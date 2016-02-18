# Dockerized-DBpedia
Creates a docker image with Virtuoso preloaded with the latest DBpedia dataset

**Requirements**
- Docker
- realpath `sudo apt-get install realpath` 

**Usage**
`$./upload.sh [options]`

	-l or --language : Set the language for which data-id file is to be downloaded [Required]
	-b or --baseurl  : Set the baseurl for fetching the data-id file [def: http://downloads.dbpedia.org/2015-04/core-i18n/lang/2015-04_dataid_lang.ttl]
	-t or --rdftype  : Set rdf format to download for datasets, [def: .ttl]
	-h or --help     : Display this help text

	-->Make sure docker daemon is running before launching the script
