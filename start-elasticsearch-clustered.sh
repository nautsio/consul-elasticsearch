#!/bin/bash

PEERS=${TMP:-/tmp}/$SERVICE_NAME.json

function getServiceAddressesFromConsul() {
        curl -s http://consul:8500/v1/catalog/service/$SERVICE_NAME?tag=es-transport > $PEERS
}

function getOwnPublishPort() {
        jq -r ".[] | select(.ServiceID==\"$SERVICE_9300_ID\") | .ServicePort" $PEERS
}

function getOwnPublishAddress() {
        jq -r ".[] | select(.ServiceID==\"$SERVICE_9300_ID\") | .Address" $PEERS
}

function getNumberOfPeers() {
        jq -r 'length'  $PEERS
}

function getPeerAddressList() {
        jq -r '[ .[] | [ .Address, .ServicePort | tostring ] | join(":")  ] | join(",")'  $PEERS
}

function waitForAllServers() {
        COUNT=0
        NR_OF_SERVERS=0
        while [ $COUNT -lt 60 -a $NR_OF_SERVERS -lt $TOTAL_NR_OF_SERVERS ] ; do
                getServiceAddressesFromConsul
                NR_OF_SERVERS=$(getNumberOfPeers)
                if [ $NR_OF_SERVERS -lt $TOTAL_NR_OF_SERVERS ] ; then
                        echo "$NR_OF_SERVERS found in registry, $TOTAL_NR_OF_SERVERS required. sleeping 2s." >&2
                        sleep 2
                        COUNT=$(($COUNT + 1))
                fi
        done
        if [ $NR_OF_SERVERS -lt $TOTAL_NR_OF_SERVERS ] ; then
                echo "Failed to acquire the required number of services" >&2
                exit 1
        fi
}

if [ -z "$TOTAL_NR_OF_SERVERS" ] ; then
	echo "ERROR: Environment variable TOTAL_NR_OF_SERVERS is not specified." >&2
	exit 1
fi

if [ -z "$SERVICE_9300_ID" ] ; then
	echo "ERROR: Environment variable SERVICE_9300_ID is not set. required to find my own publish port in Consul." >&2
	exit 1
fi

if [ -z "$SERVICE_NAME" ] ; then
	echo "ERROR: Environment variable SERVICE_NAME is not set. required to find peers own publish port and peers in cluster." >&2
	exit 1
fi

waitForAllServers

PUBLISH_PORT=$(getOwnPublishPort)
PUBLISH_ADDRESS=$(getOwnPublishAddress)
HOST_LIST=$(getPeerAddressList)
echo INFO: my network endpoint: $PUBLISH_ADDRESS:$PUBLISH_PORT
echo INFO: other servers: $HOST_LIST

if [ -z "$PUBLISH_PORT" -o -z "$PUBLISH_ADDRESS" -o -z "HOST_LIST" ] ; then
	echo ERROR: Failed to satisfy pre-conditions to start this node. >&2
	exit 1
fi

chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data

exec gosu elasticsearch elasticsearch \
	--discovery.zen.ping.multicast.enabled=false \
	--discovery.zen.ping.unicast.hosts=$HOST_LIST \
	--transport.publish_host=$PUBLISH_ADDRESS \
	--transport.publish_port=$PUBLISH_PORT \
	--cluster.name=$SERVICE_NAME \
	--node.name=$SERVICE_9300_ID \
	$@
