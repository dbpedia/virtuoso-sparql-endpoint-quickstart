FROM debian:stable-slim

LABEL org.aksw.dld=true org.aksw.dld.type="import" org.aksw.dld.require.store="virtuoso" org.aksw.dld.config="{volumes_from: [store]}"

ENV DEBIAN_FRONTEND noninteractive

ADD quickstart.sh /

RUN apt-get update && \
    apt-get install -y git virtuoso-opensource pigz pbzip2 && \
    chmod +x /quickstart.sh

ENTRYPOINT /bin/bash quickstart.sh
