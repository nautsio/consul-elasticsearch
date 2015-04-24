## Elasticsearch Dockerfile


This repository contains **Dockerfile** of [Elasticsearch](http://www.elasticsearch.org/) for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/cargonauts/consul-elasticsearch/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).


### Base Docker Image

* [dockerfile/java:oracle-java8](http://dockerfile.github.io/#/java)


### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/cargonauts/consul-elasticsearch/) from public [Docker Hub Registry](https://registry.hub.docker.com/): `docker pull cargonauts/consul-elasticsearch`

   (alternatively, you can build an image from Dockerfile: `docker build -t="cargonauts/consul-elasticsearch" github.com/cargonauts/consul-elasticsearch`)


### Usage

    docker run -d -p 9200:9200 -p 9300:9300 cargonauts/consul-elasticsearch

#### Attach persistent/shared directories

  1. Create a mountable data directory `<data-dir>` on the host.

  2. Create Elasticsearch config file at `<data-dir>/elasticsearch.yml`.

    ```yml
    path:
      logs: /data/log
      data: /data/data
    ```

  3. Start a container by mounting data directory and specifying the custom configuration file:

    ```sh
    docker run -d -p 9200:9200 -p 9300:9300 -v <data-dir>:/data cargonauts/consul-elasticsearch 
    ```

After few seconds, open `http://<host>:9200` to see the result.
