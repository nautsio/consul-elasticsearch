#!/bin/bash
/consul-template -consul consul:8500 -once -template /es-unicast.ctmpl:/es-unicast.lst 

if [ $? -eq 0 ] ; then
	curl -s http://consul:8500/v1/catalog/service/elasticsearch?tag=es-transport  \
		| /jq -r ".[] | \
			select(.ServiceID==\"$SERVICE_9300_ID\")  | \
			\"export PUBLISH_HOST=\" + .Address,  \
			\"export PUBLISH_PORT=\" + (.ServicePort | tostring ) " > /publish.env

	. /publish.env

	exec /elasticsearch/bin/elasticsearch \
		--discovery.zen.ping.multicast.enabled=false \
		--discovery.zen.ping.unicast.hosts=$(cat /es-unicast.lst) \
		--transport.publish_host=$PUBLISH_HOST \
		--transport.publish_port=$PUBLISH_PORT \
		$@
fi
