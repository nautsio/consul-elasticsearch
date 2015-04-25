## Elasticsearch Dockerfile


This repository contains a ElasticSearch instance that can be used in a Consul and Registrator environment.

### Usage

``` bash
docker run --rm \
    --name elasticsearch-<i> \
    --env SERVICE_NAME=<cluster-name> \
    --env SERVICE_9200_TAGS=http \
    --env SERVICE_9300_ID=<cluster-name>-<i> \
    --env SERVICE_9300_TAGS=es-transport \
    -P \
    --dns $(ifconfig docker0 | grep 'inet ' | awk '{print $2}') \
    --dns-search=service.consul \
    -v <data-dir>:/data \
    cargonauts/consul-elasticsearch
```

