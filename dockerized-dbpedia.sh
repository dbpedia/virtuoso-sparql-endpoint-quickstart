#!/usr/bin/env bash
cd ./dbpedia-loader
docker build -t dbpedia-virtuoso-loader .
cd ..
docker-compose up
