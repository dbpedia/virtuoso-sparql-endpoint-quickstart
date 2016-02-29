#!/bin/bash -eu

${DLD_DEV:=}
[[ ! -z "$DLD_DEV" ]] && set -x

DOWNLOAD_SCRIPT_NAME='download.sh'
DOWNLOAD_DIR='/dbpedia-download'
DLD_WD='/dld-dbpedia-wd'

missing-files-error() {
    cat <<EOF 
The dataset files to import (downloads/) and the corresponding listing
(paths.relative) can not be found in the container directory:
$(pwd)

Please run $DOWNLOAD_SCRIPT_NAME with approriate parameters
and mount the Dockeried DBpedia directory into the aforementioned
EOF
    exit 4
}

check-download-exists() {
    [[ -f "paths.relative" && -d  "downloads" ]] ||  missing-files-error
}

download-files() {
    [[ -d "$DOWNLOAD_DIR" ]] || mkdir -p "$DOWNLOAD_DIR"
    pushd "$DOWNLOAD_DIR" &> /dev/null
    "/$DOWNLOAD_SCRIPT_NAME" "$@"
    popd &> /dev/null
}

run-dld() {
    pushd "$DOWNLOAD_DIR" &> /dev/null
    check-download-exists
    export DLD_VOLUMES_FROM=dld-dbpedia
    export DLD_IMPORT_MOUNT=/dld-dbpedia-wd/models/
    export DLD_INTERNAL_IMPORT=true
    python3 /dld/dld.py -c /dbpedia-dld.yml -w "$DLD_WD" --do-up
    popd &> /dev/null
}


RUN_CMD=$1
#shift away /run.sh args got use the rest as args for the download script
shift

case $RUN_CMD in
    prepare)
        download-files "$@"
        run-dld
    ;;
    download)
        download-files "$@"
    ;;
    run-dld)
        run-dld
    ;;
    *)
        echo "unknown predefined action (action choice: prepare, download, run-dld)"
        exit 1
    ;;
esac
