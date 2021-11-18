# Virtuoso SPARQL Endpoint Quickstart

Creates and runs a Virtuoso Open Source instance including a SPARQL endpoint preloaded with a Databus Collection and the VOS DBpedia Plugin installed.

## Quickstart

Running the Virtuoso SPARQL Endpoint Quickstart requires Docker and Docker Compose installed on your system. If you do not have those installed, please follow the install instructions for [here](https://docs.docker.com/engine/install/) and [here](https://docs.docker.com/compose/install/). Once you have both Docker and Docker Compose installed, run

``` bash
git clone https://github.com/dbpedia/virtuoso-sparql-endpoint-quickstart.git
cd virtuoso-sparql-endpoint-quickstart
COLLECTION_URI=https://databus.dbpedia.org/dbpedia/collections/latest-core VIRTUOSO_ADMIN_PASSWD=YourSecretPassword docker-compose up
```

After a short delay your SPARQL endpoint will be running at [localhost:8890/sparql](localhost:8890/sparql). 

Note that loading huge datasets to the Virtuoso triple store takes some time. Even though the SPARQL endpoint is up and running, the loading process might still take up to several hours depending on the amount of data you are trying to load. 

In order to verify your setup more quickly you can use the following collection URI instead: 
[https://databus.dbpedia.org/dbpedia/collections/virtuoso-sparql-endpoint-quickstart-preview](https://databus.dbpedia.org/dbpedia/collections/virtuoso-sparql-endpoint-quickstart-preview)

Note that this collection is only a collection of RDF data to test drive the docker compose network and not a DBpedia release. After a short delay the resource [http://localhost:8890/page/Berlin](http://localhost:8890/page/Berlin) should be accessible. 

## Troubleshooting

- `virtuoso-sparql-endpoint-quickstart_load_1 exited with code 1` something went wrong with loading the files, data may be incompletely loaded 
  - * `load_1      | *** Error 28000: [Virtuoso Driver]CL034: Bad login` you are not using the correct password (the one provided when starting the compose setup for the first time
- `store_1     | 05:28:37 *** read-ahead of a free or out of range page dp L=318307, database not necessarily corrupted.` increase the memory settings (BUFFERS options) for the virtuoso database in config.env see [here](http://vos.openlinksw.com/owiki/wiki/VOS/VirtRDFPerformanceTuning#General%20Memory%20Usage%20Settings) for more details
- `store_1     | 05:18:32 Write wait on column page 62980.  Waits should be on the index leaf page, except when col page is held for read by background write` see above
- `store_1     | 05:27:43 * Monitor: High disk read (1)` see above

## Documentation

The Virtuoso SPARQL Endpoint Quickstart is a network of three different docker containers which are launched with docker-compose. The following containers are being run:

* OpenLink VOS Instance ([openlink/virtuoso-opensource-7](https://hub.docker.com/r/openlink/virtuoso-opensource-7))
* DBpedia Databus Collection Downloader ([dbpedia/dbpedia-databus-collection-downloader](https://hub.docker.com/repository/docker/dbpedia/dbpedia-databus-collection-downloader))
* Loader/Installer ([dbpedia/virtuoso-sparql-endpoint-quickstart](https://hub.docker.com/repository/docker/dbpedia/virtuoso-sparql-endpoint-quickstart))

Once the loading process has been completed, only the OpenLink VOS Instance will keep running. The other two containers will shut down once their job is done. By running `docker ps` you can see whether the download and loader container are still running. If there is only the OpenLink VOS Instance remaining, all your data has been loaded to the triple store.

The possible configurations for all containers are documented below. The repository includes an `.env` file containing all configurable environment parameters for the network.

### Environment Variables

Running `docker-compose up` will use the environment variables specified in the `.env` file next to the `docker-compose.yml`. The available variables are:


* `VIRTUOSO_ADMIN_PASSWD`: The password for the Virtuoso Database. **This needs to be set in order to successfully start the SPARQL endpoint.**

* `VIRTUOSO_HTTP_PORT`: The HTTP port of the OpenLink VOS instance.

* `VIRTUOSO_ISQL_PORT`: The ISQL port of the OpenLink VOS instance.

* `VIRTUOSO_DIR`: The directory that stores the content of the virtuoso triple store.

* `COLLECTION_URI`: The URI of a Databus Collection. If you want to load the DBpedia Dataset it is recommended to use the *Latest Core Collection* 
  (https://databus.dbpedia.org/dbpedia/collections/latest-core). You can start the SPARQL endpoint with any other Databus Collection or you can copy the files manually into the `./downloads` folder.

* `DATA_DIR`: The directory containing the loaded data. The download container will download files to this directory. You can also copy files into the directory manually.

* `DOMAIN`: The domain of your resource identifiers. This variable is only required if you intend to access the HTML view of your resources (e.g. if you want to run a DBpedia Chapter). The HTML view will only show correct views for identifiers in the specified domain. 
  (e.g. set this to http://ru.dbpedia.org when running the Russian chapter with Russian resource identifiers)

* `DBP_LANG` : The language code of your language. Defaults to 'en'.

* `DBP_CATEGORY` : The word 'category' in your language. Defaults to 'Category'.

### Container Configurations

You can configure the containers in the network even further by adjusting the `docker-compose.yml` file. The following section lists all the environment variables that can only be set in the `docker-compose.yml` for each of the containers.

Only change the docker-compose.yml if you know what you are doing. For most users the .env file is sufficient.

#### Container 1: OpenLink VOS Instance

You can read the full documentation of the docker image [here](https://hub.docker.com/r/openlink/virtuoso-opensource-7). The image requires one environment variable to set the admin password of the database:

* `DBA_PASSWORD`: Your database admin password. It is recommended to set this by setting the `VIRTUOSO_ADMIN_PASSWD` variable in the `.env` file. 
* `VIRT_PARAMETERS_NUMBEROFBUFFERS`: Defaults to 2000 which will result in a very long loading time. Increase this depending on the available memory on your machine. You can find more details in the docker image documentation.
* `VIRT_PARAMETERS_MAXDIRTYBUFFERS`: Same as `VIRT_PARAMTERS_NUMBEROFBUFFERS`.

This password is only set when a new database is created. The example docker-compose mounts a folder to the internal database directory for persistence. Note that this folder needs to be cleared in order to change the password via docker-compose.

The second volume specified in the docker-compose file connects the downloads folder to a directory in the container that is
accessible by the virtuoso load script. Accessible paths are set in the internal `virtuoso.ini` file (`DirsAllowed`). As the
docker-compose uses the vanilla settings of the image the local `./downloads` folder is mounted to `/usr/share/proj` inside of the container which is in the `DirsAllowed` per default.

#### Container 2: DBpedia Databus Collection Downloader

This project uses the DBpedia Databus Collection Downloader. You can find the documentation [here](https://github.com/dbpedia/dbpedia-databus-collection-downloader). If you haven't already, download and build the download client docker image. The required environment variables are:

* `TARGET_DIR`: The target directory for the downloaded files (inside of the container). Make sure that the directory is mounted to a local folder to access the files in the docker network.

#### Container 3: Loader/Installer

The loader/installer container is being pulled from ([dbpedia/virtuoso-sparql-endpoint-quickstart](https://hub.docker.com/repository/docker/dbpedia/virtuoso-sparql-endpoint-quickstart)).

Alternatively, you could potentially modify and then build the loader/installer docker image by running

```
cd ./dbpedia-loader
docker build -t dbpedia-virtuoso-loader .
```

You can configure the container with the following environment variables:

* `STORE_DATA_DIR`: The directory of the VOS instance that the `downloads` folder is mounted to (`/usr/share/proj` by default). Since the Loader will tell the VOS instance to start importing files it needs to know where the files are going to be. Additionally the VOS instance needs to be given access to that directory. 
* `STORE_DBA_PASSWORD`: The admin password specified in the VOS instance (`DBA_PASSWORD` variable).  It is recommended to set this by setting the `VIRTUOSO_ADMIN_PASSWD` variable in the `.env` file. 
* `DATA_DIR`: The directory of this container that the `downloads` folder is mounted to.
* `[OPTIONAL] DATA_DOWNLOAD_TIMEOUT`: The amount of seconds until the loader process stops waiting for the download to finish.
* `[OPTIONAL] STORE_CONNECTION_TIMEOUT`: The amount of seconds until the loader process stops waiting for the store to boot up.



## Instructions for DBpedia Chapters

In case of emergency or confusion please visit [this forum thread](https://forum.dbpedia.org/t/chapter-deployment-support-thread/950). Feel free to ask and answer questions as it will help future chapter deployments!

In order to use the Virtuoso SPARQL Endpoint Quickstart docker network to host your own DBpedia instance you need to create a chapter collection on the [DBpedia Databus](https://databus.dbpedia.org/). You can learn about the Databus and Databus Collections in the [DBpedia Stack Tutorial on Youtube](https://www.youtube.com/watch?v=NrUK0Hs-ZpQ)

Alternatively you can download the required data to your local machine and supply the files manually. It is however recommended to use Collections as it makes updating to future version much easier.

Set the `COLLECTION_URI` variable to your chapter collection URI and adjust the `DOMAIN` variable to match the domain of your resource identifiers. Alternatively (not recommended) copy your files into the directory specified in `DATA_DIR` and remove the download container section from the `docker-compose.yml`)

Once all variables are set in the `.env` file run

````docker-compose up
docker-compose up
````

## Enabling Federated Queries

Federated queries can be enabled by granting the roles `SPARQL_LOAD_SERVICE_DATA` and `SPARQL_SPONGE` to the `SPARQL` user.
```
docker exec -it [virtuoso_docker_name] /bin/bash
isql-v -U dba -P [virtuoso_admin_password]
grant SPARQL_LOAD_SERVICE_DATA to "SPARQL";
grant SPARQL_SPONGE to "SPARQL";
```





