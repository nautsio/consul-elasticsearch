#!/bin/bash

function getExternalAddress() {
	curl -s http://consul:8500/v1/catalog/service/elasticsearch?tag=es-transport  \
		| /jq -r ".[] | \
			select(.ServiceID==\"$SERVICE_9300_ID\")  | \
			\"export PUBLISH_HOST=\" + .Address,  \
		\"export PUBLISH_PORT=\" + (.ServicePort | tostring ) " > /publish.env
}

function getExternalAddressWait() {

	while [ -z "$PUBLISH_PORT" ] ; do
		getExternalAddress
		. /publish.env
		if [ -z "$PUBLISH_PORT" ] ; then
			echo "Failed to obtain publish host and port for service '$SERVICE_9300_ID'. Retrying in 1s.." >&2
			sleep 1
		fi
	done
}
/consul-template -consul consul:8500 -once -template /es-unicast.ctmpl:/es-unicast.lst 

if [ $? -eq 0 ] ; then
	getExternalAddressWait
	. /publish.env

	exec /elasticsearch/bin/elasticsearch \
		--discovery.zen.ping.multicast.enabled=false \
		--discovery.zen.ping.unicast.hosts=$(cat /es-unicast.lst) \
		--transport.publish_host=$PUBLISH_HOST \
		--transport.publish_port=$PUBLISH_PORT \
		$@
else
	echo ERROR: consul-template exited with non-zero status: $? >&2
	exit $?
fi
