# Dockerized-DBpedia
Creates and runs a Virtuoso Open Source instance preloaded with a Databus Collection and the VOS DBpedia Plugin installed.

## Usage

All you need to do is to set a password in the `.env` file change the `COLLECTION_URI` in  `docker-compose.yml` and then  run the `dockerized-dbpedia.sh` script in the project root directory. 

This will build the image of the loader/installer process that will load data of the Databus Collection to the Virtuoso Open Source instance and install the DBpedia Plugin. Once the image has been built it runs 'docker-compose up' to start three containers:

* OpenLink VOS Instance ([openlink/virtuoso-opensource-7](https://hub.docker.com/r/openlink/virtuoso-opensource-7))
* Minimal Databus Download Client ([dbpedia/minimal-download-client](https://hub.docker.com/repository/docker/dbpedia/minimal-download-client))
* Loader/Installer

## Configuration

Before running the script you should configure the containers in the `docker-compose.yml`. Details for the parameters are listed below.

### OpenLink VOS Instance

You can read the full documentation of the docker image [here](https://hub.docker.com/r/openlink/virtuoso-opensource-7). The image requires one environment variable to set the admin password of the database:
* `DBA_PASSWORD`: Your database admin password
* `VIRT_PARAMETERS_NUMBEROFBUFFERS`: Defaults to 2000 which will result in a very long loading time. Increase this depending on the available memory on your machine. You can find more details in the docker image documentation.
* `VIRT_PARAMETERS_MAXDIRTYBUFFERS`: Same as `VIRT_PARAMTERS_NUMBEROFBUFFERS`.

This password is only set when a new database is created. The example docker-compose mounts a folder to the internal database directory for persistence. Note that this folder needs to be cleared in order to change the password via docker-compose.

The second volume specified in the docker-compose file connects the downloads folder to a directory in the container that is
accessible by the virtuoso load script. Accessible paths are set in the internal `virtuoso.ini` file (`DirsAllowed`). As the
docker-compose uses the vanilla settings of the image the `downloads` folder is mounted to `/usr/share/proj` which is in the
`DirsAllowed` per default.

### Databus Download Client

This project uses the minimal DBpedia Databus download client. You can find the documentation [here](https://github.com/dbpedia/minimal-download-client). If you haven't already, download and build the download client docker image. The required environment variables are:
* `TARGET_DIR`: The target directory for the downloaded files
* `COLLECTION_URI`: A collection URI on the DBpedia Databus

### Loader/Installer

You can build the loader/installer container by running
```
cd ./dbpedia-loader
docker build -t dbpedia-virtuoso-loader .
```

You can configure the container with the following environment variables:
* `STORE_DATA_DIR`: The directory of the VOS instance that the `downloads` folder is mounted to (`/usr/share/proj` by default). Since the Loader will tell the VOS instance to start importing files it needs to know where the files are going to be. Additionally the VOS instance needs to be given access to that directory. 
* `STORE_DBA_PASSWORD`: The admin password specified in the VOS instance (`DBA_PASSWORD` variable)
* `DATA_DIR`: The directory of this container that the `downloads` folder is mounted to.
* `DOMAIN`: The domain of your resource identifiers
* `[OPTIONAL] DATA_DOWNLOAD_TIMEOUT`: The amount of seconds until the loader process stops waiting for the download to finish.
* `[OPTIONAL] STORE_CONNECTION_TIMEOUT`: The amount of seconds until the loader process stops waiting for the store to boot up.

## Example

The default `docker-compose.yml` will start a VOS instance with the DBpedia Plugin installed containing the data
specified in the https://databus.dbpedia.org/kurzum/collections/agro collection (in this case mapping-based geo-data in Russian).
Since the resource identifiers are Russian dbpedia identifiers the `DOMAIN` variable is set to "http://ru.dbpedia.org".

```
version: '3'
services:
  download:
    image: dbpedia/minimal-download-client:latest
    environment:
      COLLECTION_URI: https://databus.dbpedia.org/kurzum/collections/agro
      TARGET_DIR: /root/data
    volumes:
      - ./downloads:/root/data # has to point to TARGET_DIR
  store:
    image: openlink/virtuoso-opensource-7
    ports: ["${VIRTUOSO_HTTP_PORT}:8890","127.0.0.1:${VIRTUOSO_ISQL_PORT}:1111"]
    environment:
            DBA_PASSWORD: ${VIRTUOSO_ADMIN_PASSWD:?Set VIRTUOSO_ADMIN_PASSWD in .env file or pass as environment variable e.g.  VIRTUOSO_ADMIN_PASSWD= docker-compose up}
    volumes:
      - ./virtuoso-db:/opt/virtuoso-opensource/database
      - ./downloads:/usr/share/proj # has to point to STORE_DATA_DIR in 'load'
  load:
    image: dbpedia-virtuoso-loader:latest
    environment:
      STORE_DATA_DIR: /usr/share/proj
      STORE_DBA_PASSWORD: ${VIRTUOSO_ADMIN_PASSWD:?Set VIRTUOSO_ADMIN_PASSWD in .env file or pass as environment variable e.g.  VIRTUOSO_ADMIN_PASSWD= docker-compose up}
      STORE_ISQL_PORT: ${VIRTUOSO_ISQL_PORT}
      DATA_DIR: /root/data
      DOMAIN: http://ru.dbpedia.org
    volumes:
      - ./downloads:/root/data # has to point to DATA_DIR
      
