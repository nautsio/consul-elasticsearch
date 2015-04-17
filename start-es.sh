#!/bin/bash
/consul-template -consul consul:8500 -once -template /es-unicast.ctmpl:/es-unicast.lst &&
exec /elasticsearch/bin/elasticsearch \
	--discovery.zen.ping.multicast.enabled=false \
	--discovery.zen.ping.unicast.hosts=$(cat /es-unicast.lst) \
	$@
