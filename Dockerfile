FROM aksw/dld-bootstrap

MAINTAINER Markus Ackermann <ackermann@informatik.uni-leipzig.de>

RUN dnf install -y findutils wget figlet

COPY docker/run.sh docker/dbpedia-dld.yml /download.sh /

RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
