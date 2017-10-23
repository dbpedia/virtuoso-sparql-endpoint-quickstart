# Dockerized-DBpedia
Creates and runs an Virtuoso Open Source instance preloaded with the latest DBpedia dataset
inside a Docker container 

## Usage as Docker Image

### Requirements

 * Docker Engine 1.9.1 or newer

### Quickstart
1. ensure your Docker Engine is up and running (and accepting
   connection on the `/var/run/docker.sock` socket file)
1. choose the DBpedia language version which you want to deploy
   (e.g. by browsing the [DBpedia Download Server](http://downloads.dbpedia.org/2016-04/core-i18n/))
1. If you want a short-lived container that you can terminate directly using `Ctrl + C`, run:

        $ docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock:z --name dld-dbpedia aksw/dld-dist-dbpedia prepare  -l {{lang-code}}   

   replacing `{{lang code}}` with the chosen language (use `core` as language if you want an exact copy of the data in http://dbpedia.org/sparql, 'en' is slightly different). If you, alternatively, would like the triple store to persist independent from the shell session you start it in, use:

        $ docker run -d -v /var/run/docker.sock:/var/run/docker.sock:z --name dld-dbpedia aksw/dld-dist-dbpedia prepare  -l {{lang-code}}
   
   (i.e. replace the `-ti --rm` switches with a `-d` switch, please consult the [Docker Run Reference](https://docs.docker.com/engine/reference/run/) for details)
   N.B.: Currently it is required the container has exactly the name `dld-dbpedia`, we hope to get rid of this constraint soon. 

1. SPARQL query web interface can be accessed at http://localhost:8891 once the downloading and bulk loading task are finished.

 You can either use wget to get query results or directly make queries on the interface and select the desired output format.

### What happens?
 * a download script uses [DataId](https://github.com/dbpedia/dataid)
   meta-data for the chosen language to determine which distribution
   files must be downloaded and does so
 * the containerized version of the
   [DLD](https://dockerizing.github.io/) Bootstrap tool is used to
   configure and run a suitable orchestration of a VOS container and a
   bulk load container initiating efficient import into the RDF store
    
### Re-Using Previous Downloads 

The `dld-dist-dbpedia` image also allows you to re-use distribution
data downloaded by it from a previous invocation. To this end, you
should mount a host system directory as the place to persistently keep
the download files
(`-v /host/path/to/dbpedia-download:/dbpedia-download:z`) 
and first run the `dld-dist-dbpedia` image with the command `download`
followed by download switches. After that, you can re-use the
downloads in your host filesystem to re-create the VOS setup several
times.

For example, to keep the downloads for the German DBpedia version
(`de`) in `/opt/dbpedia-data/de` in your host filesystem, first invoke

        $ docker run --rm -v /opt/dbpedia/data/de:/dbpedia-download:z aksw/dld-dist-dbpedia download  -l de
        
followed by 

        $ docker run -ti -v /var/run/docker.sock:/var/run/docker.sock:z -v /opt/dbpedia/data/de:/dbpedia-download:z --name dld-dbpedia aksw/dld-dist-dbpedia run-dld

to start a VOS import setup using the previously downloaded data.


### Download Script Options (the `download` sub-command)
`$./download.sh [options]` or `$ docker run [...] dld-dist-dbpedia [download|prepare] [options]`

    -l or --language : Set the language for which data-id file is to be downloaded [Required]

    -b or --baseurl  : Set the baseurl for fetching the data-id file 
                       [Default: http://downloads.dbpedia.org/2016-04/core-i18n/{lang}/2016-04_dataid_{lang}.ttl]

    -c or --core     : Must specifiy recursive level like 1,2,3... If used, the core directory will get downloaded [http://downloads.dbpedia.org/2016-04/core/]
                       [Default recursive level: 1]

    -t or --rdftype  : Set rdf format to download for datasets {nt, nq, ttl, tql}, 
                       [Default: ttl]

    -h or --help     : Display this help text"

### Caveats and Remarks
 * the `:z` suffix for host filesystem mount points is only required
   if SELinux access control is present and configured to `enforce` on
   your host system and can be ommited otherwise
 * sharing to Docker control socket (`/var/run/docker.sock`) with the
   `dld-dist-container` might require adjustment to `SELinux` policies
   (when used) on some distributions (e.g. for Fedora and RHEL, apply
   adjustments as in
   [selinux-dockersock](https://github.com/dpw/selinux-dockersock))
