#
# Elasticsearch Dockerfile
#
# https://github.com/dockerfile/elasticsearch
#

# Pull base image.
FROM dockerfile/java:oracle-java8

ENV ES_PKG_NAME elasticsearch-1.5.0

ADD https://github.com/hashicorp/consul-template/releases/download/v0.8.0/consul-template_0.8.0_linux_amd64.tar.gz  /consul-template.tar.gz
RUN cd / && tar xzvf /consul-template.tar.gz --strip-components=1 && rm /consul-template.tar.gz

ADD http://stedolan.github.io/jq/download/linux64/jq /jq
RUN chmod +x /jq

# Install Elasticsearch.
RUN \
  cd / && \
  curl -s https://download.elasticsearch.org/elasticsearch/elasticsearch/$ES_PKG_NAME.tar.gz | \
  tar xvzf - && \
  mv /$ES_PKG_NAME /elasticsearch

RUN cd / && \
     /elasticsearch/bin/plugin -install mobz/elasticsearch-head

# Define mountable directories.
VOLUME ["/data"]

# Mount elasticsearch.yml config
ADD config/elasticsearch.yml /elasticsearch/config/elasticsearch.yml
ADD /es-unicast.ctmpl /
ADD /start-es.sh /
RUN chmod +x /start-es.sh

# Define working directory.
WORKDIR /data

# Define default command.
CMD ["/start-es.sh"]

# Expose ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300
