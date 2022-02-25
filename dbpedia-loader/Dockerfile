FROM debian:jessie

LABEL org.aksw.dld=true org.aksw.dld.type="import" org.aksw.dld.require.store="virtuoso" org.aksw.dld.config="{volumes_from: [store]}"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y git virtuoso-opensource pigz pbzip2

ADD import.sh /
RUN chmod +x /import.sh

ADD dbpedia_fr-metadata.ttl /
RUN chmod +x /dbpedia_fr-metadata.ttl

ADD compute_named_graphs_stats.sh  /
RUN chmod +x /compute_named_graphs_stats.sh 

ENTRYPOINT /bin/bash import.sh && compute_named_graphs_stats.sh 
