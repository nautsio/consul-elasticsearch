#!/bin/bash

function getExternalAddress() {
	curl -s http://consul:8500/v1/catalog/service/$SERVICE_NAME?tag=es-transport  \
		| /jq -r ".[] | \
			select(.ServiceID==\"$SERVICE_9300_ID\")  | \
			\"export PUBLISH_HOST=\" + .Address,  \
		\"export PUBLISH_PORT=\" + (.ServicePort | tostring ) " > /publish.env
}

function getExternalAddressWait() {

	COUNT=1
	while [ $COUNT -le 60 -a -z "$PUBLISH_PORT" ] ; do
		getExternalAddress
		. /publish.env
		if [ -z "$PUBLISH_PORT" ] ; then
			echo "Failed to obtain publish host and port for service '$SERVICE_9300_ID'. Retrying in 1s.." >&2
			sleep 1
			COUNT=$(($COUNT + 1))
		fi
	done
	if [ -z "$PUBLISH_PORT" ] ; then
		echo "Failed to obtain publish host and port for service '$SERVICE_9300_ID'. " >&2
		exit 1
	fi
}

function getEsHostList() {
	sed -i -e 's/es-transport.[^"]*/es-transport.'"$SERVICE_NAME/" /es-unicast.ctmpl

	COUNT=0
	NR_OF_SERVERS=0
	while [ $COUNT -lt 60 -a $NR_OF_SERVERS -lt $TOTAL_NR_OF_SERVERS ] ; do
		/consul-template -consul consul:8500 -once -template /es-unicast.ctmpl:/es-unicast.lst 
		HOST_LIST=$(</es-unicast.lst)
		NR_OF_SERVERS=$(cat /es-unicast.lst | tr ',' '\n' | wc -l)
		if [ $NR_OF_SERVERS -lt $TOTAL_NR_OF_SERVERS ] ; then
			echo "$NR_OF_SERVERS found in registry, $TOTAL_NR_OF_SERVERS required. sleeping 1." >&2
			sleep 1
			COUNT=$(($COUNT + 1))
		fi
	done
	if [ $NR_OF_SERVERS -lt $TOTAL_NR_OF_SERVERS ] ; then
		echo "Failed to acquire the required number of services" >&2
		exit 1
	fi
}

if [ $? -eq 0 ] ; then
	getExternalAddressWait
        getEsHostList
	cat /es-unicast.lst
	. /publish.env

	exec /elasticsearch/bin/elasticsearch \
		--discovery.zen.ping.multicast.enabled=false \
		--discovery.zen.ping.unicast.hosts=$(cat /es-unicast.lst) \
		--transport.publish_host=$PUBLISH_HOST \
		--transport.publish_port=$PUBLISH_PORT \
		--cluster.name=$SERVICE_NAME \
		--node.name=$SERVICE_9300_ID \
		$@
else
	echo ERROR: consul-template exited with non-zero status: $? >&2
	exit $?
fi
