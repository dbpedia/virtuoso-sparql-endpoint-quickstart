#!/bin/bash -eu

${DLD_DEV:=}
[[ ! -z "$DLD_DEV" ]] && set -x

# Set default variables
VERSION="2016-10"
GENERIC_FILENAME="${VERSION}_dataid_lang.ttl"
BASEURL="http://downloads.dbpedia.org/$VERSION/core-i18n/lang/${VERSION}_dataid_lang.ttl"
ONTOLOGY_FILE="http://downloads.dbpedia.org/$VERSION/dbpedia_$VERSION.nt"
LANG="null"
DIRECTORY="downloads"
RDFTYPE="ttl"
CORE="null"
GRAPH="null"
MEDIA_TYPE="null"

# Check if downloads directory exist or else make one
if [ ! -d "$DIRECTORY" ]; then
    # Control will enter here if $DIRECTORY doesn't exist.
    mkdir "$DIRECTORY"
    if [[ $? != 0 ]]; then
    echo "Failed to make $DIRECTORY directory. Delete any file named $DIRECTORY for the script to work."
    exit
  fi
fi

# Help function to display usage instructions
function help 
{
  echo "Usage: $./download.sh [options]
  -l or --language : Set the language for which data-id file is to be downloaded [Required]

  -b or --baseurl  : Set the baseurl for fetching the data-id file 
                     [Default: $BASEURL]

  -c or --core     : Must specify recursive level like 1,2,3... If used, the core directory will get downloaded [http://downloads.dbpedia.org/$VERSION/core/]
                     [Default recursive level: 1]

  -t or --rdftype  : Set rdf format to download for datasets {nt, nq, ttl, tql}, 
                     [Default: ttl]

  -h or --help     : Display this help text"
  echo ""
# TODO: not sure whether or for what Ex 3 is relevant, could clean up script if not needed
  echo "Ex: 
  1. Download datasets for english language in ttl format using data-id: $BASEURL: 
        $./download.sh -l en -t ttl

  2. Download dataset from DBpedia core only {No data-id available currently}
        $./download.sh -c 1

  3. Download datasets for both the above mentioned examples but using base url:
        $./download.sh -l en -t ttl -c 1 -b $BASEURL
  "
}

# Setting all key value pairs specified as arguments to the script
while [[ $# > 0 ]]
do
key="$1"

case $key in
    -l|--language)
    LANG="$2"
    shift # past language argument
    ;;
    -c|--core)
    CORE="$2"
    shift # past core argument
    ;;
    -b|--baseurl)
    BASEURL="$2"
    shift # past baseurl argument
    ;;
    -t|--rdftype)
    RDFTYPE="$2"
    shift # past rdf format argument
    ;;
    -h|--help)
    help # call the help function
    exit # exit overriding any other arguments specified
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
    echo "ERROR: unknown option '$key'"
    ;;
esac
shift # past argument or value
done

# Display of creativity no more
function startup
{
  echo "......................"
  echo "Dockerized-DBpedia"
  echo "......................"
}

# Write absolute dataset paths to paths.absolute
function loadPaths
{
  for f in `ls $DIRECTORY/`; 
  do 
    realpath "$DIRECTORY/$f";
  done > paths.absolute

  find "$DIRECTORY" -type f > paths.relative
}

# If only core directory is to be downloaded
function coredump
{
  startup

  # Download the core directory
  wget -r -l1 --no-parent -N --continue -P "$PWD/$DIRECTORY" http://downloads.dbpedia.org/$VERSION/core/ 
  wget -r -l1 --no-parent -N --continue -P "$PWD/$DIRECTORY" http://downloads.dbpedia.org/$VERSION/links/
  
  # Download the ontology file
  wget -N --continue -P "$PWD/$DIRECTORY" $ONTOLOGY_FILE
  loadPaths
}

# Language parameter is mandatory if core parameter not set. Check if specified or exit the script
if [ "$LANG" == "null" ]; then
  if [ "$CORE" == "null" ]; then
    echo "Language parameter is mandatory if core parameter not set."
    echo "Usage: $./download.sh --help"
    exit 0;
  else
    coredump
    exit 0;
  fi
elif [ "$LANG" == "core" ]; then
  coredump
  exit 0;
fi

# RDF type needs to be ttl or tql
if [ "$RDFTYPE" == "ttl" ]; then
  MEDIA_TYPE="MediaType_turtle_x-bzip2"
elif [ "$RDFTYPE" == "tql" ]; then
  MEDIA_TYPE="MediaType_n-quads_x-bzip2"
else
  echo "Unsupported RDF format."
  echo "Usage: $./download.sh --help"
  exit 0;
fi

# RDF type needs to be ttl or tql
if [ "$LANG" == "en" ]; then
  GRAPH="http://dbpedia.org"
else
  GRAPH="http://$LANG.dbpedia.org"
fi

# Call the startup function
startup

# Get the filename of the above downloaded data-id file
FILENAME=$( echo $GENERIC_FILENAME | sed "s|lang|$LANG|" )
if [ -f "$FILENAME" ]; then
  echo "Will use the existing $FILENAME file"
else
  # Fetch the data-id file using the baseurl and the language specified
  echo $BASEURL | sed "s|lang|$LANG|g" | xargs wget
fi 

# Set the rdf filter
RDFFILTER="$RDFTYPE.bz2"

# Parse the file to get all download urls and store them in the downloadURLs.txt file
#cat $FILENAME | grep 'dcat:downloadURL' | grep "$RDFFILTER" | sed -r -e 's|\s+dcat:downloadURL\s+<||' -e 's|> ;||' > downloadURLs.txt
roqet -D $FILENAME -e "PREFIX dataid: <http://dataid.dbpedia.org/ns/core#> PREFIX dataid-mt: <http://dataid.dbpedia.org/ns/mt#> PREFIX dcat: <http://www.w3.org/ns/dcat#> PREFIX sd: <http://www.w3.org/ns/sparql-service-description#> SELECT ?url WHERE {[] dcat:downloadURL ?url ; dcat:mediaType dataid-mt:$MEDIA_TYPE ; dataid:isDistributionOf ?ds . ?ds sd:defaultGraph <$GRAPH> .}" -r csv | tail -n +2 | tr -d '\r' > downloadURLs.txt

# Get the count of number of files to be downloaded
COUNT=$( wc -l downloadURLs.txt | cut -d' ' -f1 )
echo "Number of files to be downloaded: " $COUNT

# Set number of files downloaded to 0 to keep track of downloaded files
DOWNLAODED=0

# Download all the datasets and store them in download directory
for i in `cat downloadURLs.txt`; 
do
  echo "Download URL: " $i
  wget -N --continue -P "$PWD/$DIRECTORY/" $i
  if [[ $? == 0 ]]; then
    DOWNLAODED=$((DOWNLAODED+1))
  fi
  echo "Number of files downloaded: " $DOWNLAODED "/" $COUNT
done

# Download the ontology file
wget -N --continue -P "$PWD/$DIRECTORY" http://downloads.dbpedia.org/$VERSION/dbpedia_$VERSION.nt

# Download the core directory if core parameter is set
if [ "$CORE" != "null" ]; then
  # Download the core directory
  wget -r -l1 --no-parent -N --continue -P "$PWD/$DIRECTORY" http://downloads.dbpedia.org/$VERSION/core/
  wget -r -l1 --no-parent -N --continue -P "$PWD/$DIRECTORY" http://downloads.dbpedia.org/$VERSION/links/
fi

loadPaths
