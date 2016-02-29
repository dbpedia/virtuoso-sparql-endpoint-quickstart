#!/bin/bash -eu

${DLD_DEV:=}
[[ ! -z "$DLD_DEV" ]] && set -x

# Set default variables
GENERIC_FILENAME=2015-04_dataid_lang.ttl
BASEURL=http://downloads.dbpedia.org/2015-04/core-i18n/lang/2015-04_dataid_lang.ttl
LANG="null"
DIRECTORY="downloads"

# Check if import directory exist or else make one
if [ ! -d "$DIRECTORY" ]; then
    # Control will enter here if $DIRECTORY doesn't exist.
    mkdir "$DIRECTORY"
    if [[ $? != 0 ]]; then
    echo "Failed to make import directory. Delete any file named $DIRECTORY for the script to work."
    exit
  fi
fi
# Help function to display usage iunstructions
function help 
{
  echo "Usage: $./upload.sh [options]
  -l or --language : Set the language for which data-id file is to be downloaded [Required]
  -b or --baseurl  : Set the baseurl for fetching the data-id file [def: http://downloads.dbpedia.org/2015-04/core-i18n/lang/2015-04_dataid_lang.ttl]
  -t or --rdftype  : Set rdf format to download for datasets, [def: .ttl]
  -h or --help     : Display this help text

  -->Make sure docker daemon is running before launching the script"
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

# Language parameter is mandatory. Check if specified or exit the script
if [ "$LANG" == "null" ]; then
  echo "Usage: $./upload.sh --help"
  exit
fi

# Display of creativity
figlet -t Smart Data-Id Download

# Fetch the data-id file using the baseurl and the language specified
echo $BASEURL | sed "s|lang|$LANG|g" | xargs wget 

# Get the filename of the above downloaded data-id file
FILENAME=$( echo $GENERIC_FILENAME | sed "s|lang|$LANG|" )

# Parse the file to get all download urls and store them in the downloadURLs.txt file
cat $FILENAME | grep 'dcat:downloadURL' | grep "ttl.bz2" | sed -r -e 's|\s+dcat:downloadURL\s+<||' -e 's|> ;||' > downloadURLs.txt

# Get the count of number of files to be downloaded
COUNT=$( wc -l downloadURLs.txt | cut -d' ' -f1 )
echo "Number of files to be downloaded: " $COUNT

# Set number of files downloaded to 0 to keep track of downloaded files
DOWNLAODED=0

# Download all the datasets and store them in import directory
for i in `cat downloadURLs.txt`; 
do
  echo "Download URL: " $i
  wget -P "$PWD/$DIRECTORY/" $i
  if [[ $? == 0 ]]; then
    DOWNLAODED=$((DOWNLAODED+1))
  fi
  echo "Number of files downloaded: " $DOWNLAODED "/" $COUNT
done

# Write absolute  dataset paths to paths.absolute
for f in `ls $DIRECTORY/`; 
do 
  realpath "$DIRECTORY/$f";
done > paths.absolute

find "$DIRECTORY" -type f > paths.relative
