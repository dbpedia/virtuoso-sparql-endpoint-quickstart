# Dockerized-DBpedia
Creates and runs an Virtuoso Open Source instance preloaded with a Databus Collection and the VOS DBpedia Plugin installed.

## Usage

All you need to do is run the `dockerized-dbpedia.sh` script in the project root directory. This will build the image of the loader/installer process that will load data to the Virtuoso Open Source instance and install the DBpedia Plugin. Once the image has been built it runs 'docker-compose up' to start three containers:

* OpenLink VOS Instance ([openlink/virtuoso-opensource-7](https://hub.docker.com/r/openlink/virtuoso-opensource-7))
* Databus Download Client
* Loader/Installer

Before running the script you should configure these containers in the `docker-compose.yml`.

### OpenLink VOS Instance

You can read the full documentation of the docker image [here](https://hub.docker.com/r/openlink/virtuoso-opensource-7). The image requires one environment variable to set the admin password of the database:
* `DBA_PASSWORD`: Your database admin password

This password is only set when a new database is created. The example docker-compose mounts a folder to the internal database directory for persistence. Note that this folder needs to be cleared in order to change the password via docker-compose.

The second volume specified in the docker-compose file connects the downloads folder to a directory in the container that is
accessible by the virtuoso load script. Accessible paths are set in the internal `virtuoso.ini` file (`DirsAllowed`). As the
docker-compose uses the vanilla settings of the image the `downloads` folder is mounted to `/usr/share/proj` which is in the
`DirsAllowed` per default.

### Databus Download Client

This project uses the minimal DBpedia Databus download client. You can find the documentation [here](https://github.com/dbpedia/minimal-download-client).
* `TARGET_DIR`: The target directory for the downloaded files
* `COLLECTION_URI`: A collection URI on the DBpedia Databus

### Loader/Installer

You can build the loader/installer container by running
```
cd ./dbpedia-loader
docker build -t dbpedia-virtuoso-loader .
```

You can configure the container with the following environment variables:
* `STORE_DATA_DIR`: The directory of the VOS instance that the `downloads` folder is mounted to (`/usr/share/proj` by default)
* `STORE_DBA_PASSWORD`: The admin password specified in the VOS instance (`DBA_PASSWORD` variable)
* `DATA_DIR`: The directory of this container that the `downloads` folder is mounted to.
* `DOMAIN`: The domain of your resource identifiers
* `[OPTIONAL] DATA_DOWNLOAD_TIMEOUT`: The amount of seconds until the loader process stops waiting for the download to finish.
* `[OPTIONAL] STORE_CONNECTION_TIMEOUT`: The amount of seconds until the loader process stops waiting for the store to boot up.

## Example

The following `docker-compose.yml` will start a VOS instance with the DBpedia Plugin installed containing the data
specified in the https://databus.dbpedia.org/kurzum/collections/agro collection (in this case mapping-based geo-data in Russian).
Since the resource identifiers are Russian dbpedia identifiers the `DOMAIN` variable is set to "http://ru.dbpedia.org".

```
version: '3'
services:
  download:
    image: databus-download-min:latest
    environment:
      COLLECTION_URI: https://databus.dbpedia.org/kurzum/collections/agro
      TARGET_DIR: /root/data
    volumes:
      - ./downloads:/root/data # has to point to TARGET_DIR
  store:
    image: openlink/virtuoso-opensource-7
    ports: ["8891:8890","1111:1111"]
    environment:
      DBA_PASSWORD: dbpedia
    volumes:
      - ./virtuoso-db:/opt/virtuoso-opensource/database
      - ./downloads:/usr/share/proj # has to point to STORE_DATA_DIR in 'load'
  load:
    image: dbpedia-virtuoso-loader:latest
    environment:
      STORE_DATA_DIR: /usr/share/proj
      STORE_DBA_PASSWORD: dbpedia
      DATA_DIR: /root/data
      DOMAIN: http://ru.dbpedia.org
    volumes:
      - ./downloads:/root/data # has to point to DATA_DIR
```
