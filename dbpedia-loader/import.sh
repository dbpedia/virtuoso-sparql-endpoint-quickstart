#!/usr/bin/env bash
#!/

# Environment variables with example values:
# STORE_NAME: store
# STORE_DBA_PASSWORD: dbpedia
# STORE_CONNECTION_TIMEOUT: 60
# STORE_IMPORT_VOLUME_DIR: /import
# DATA_DOWNLOAD_TIMEOUT: 60
# SRC_VOLUME_DIR: /data
# IMPORT_VOLUME_DIR: /import

set -o nounset

bin="isql-vt"
host=${STORE_NAME}
port=1111
user="dba"
password=${STORE_DBA_PASSWORD}

import_dir=${IMPORT_VOLUME_DIR}
store_import_dir=${STORE_IMPORT_VOLUME_DIR}

run_virtuoso_cmd () {
 VIRT_OUTPUT=`echo "$1" | "$bin" -H "$host" -S "$port" -U "$user" -P "$password" 2>&1`
 VIRT_RETCODE=$?
 if [[ $VIRT_RETCODE -eq 0 ]]; then
   echo "$VIRT_OUTPUT" | tail -n+5 | perl -pe 's|^SQL> ||g'
   return 0
 else
   echo -e "[ERROR] running the these commands in virtuoso:\n$1\nerror code: $VIRT_RETCODE\noutput:"
   echo "$VIRT_OUTPUT"
   let 'ret = VIRT_RETCODE + 128'
   return $ret
 fi
}

wait_for_download() {
  retries=$1
  for i in $(seq $retries)
  do
    sleep 1
    echo "[INFO] Waiting for files.. (${i})"
    if [ ! -f "${SRC_VOLUME_DIR}/download.lck" ]; then
      return 0
    fi
  done
}

test_connection () {
   if [[ -z $1 ]]; then
       echo "[ERROR] missing argument: retry attempts"
       exit 1
   fi

   t=$1

   run_virtuoso_cmd 'status();'
   while [[ $? -ne 0 ]] ;
   do
       echo -n "."
       sleep 1
       echo $t
       let "t=$t-1"
       if [ $t -eq 0 ]
       then
           echo "timeout"
           return 2
       fi
       run_virtuoso_cmd 'status();'
   done
}

bz2_to_gz () {
   if [[ -z "$1" || ! -d "$1"  ]]; then
       echo "[ERROR] not a valid directory path: $wd"
       exit 1
   fi

   cd "${import_dir}"

   wd="$1"
   bz2_archives=( "$wd"/*bz2 )
   bz2_archive_count=${#bz2_archives[@]}
   if [[ $bz2_archive_count -eq 0 || ( $bz2_archive_count -eq 1 && "$bz2_archives" == "${wd}/*bz2" ) ]]; then
       return 0
   fi

   echo "[INFO] converting $bz2_archive_count bzip2 archives to gzip:"
   for archive in ${bz2_archives[@]}; do
       echo "[INFO] converting $archive"
       pbzip2 -dc $archive | pigz - > ${archive%bz2}gz
       rm $archive
   done
}

echo "[INFO] waiting for download client to finish"
wait_for_download ${DATA_DOWNLOAD_TIMEOUT}

echo "copying import files to store volume"
cp "${SRC_VOLUME_DIR%/}"/* "${import_dir}"

bz2_to_gz "${import_dir}"

echo "[INFO] waiting for store to come online"
: ${STORE_CONNECTION_TIMEOUT:=60}
test_connection "${STORE_CONNECTION_TIMEOUT}"
if [ $? -eq 2 ]; then
   echo "[ERROR] store not reachable"
   exit 1
fi

echo "[INFO] initializing named graphs"
for graph_file in *.graph; do
   graph=`head -n1 ${graph_file}`
   run_virtuoso_cmd "sparql CREATE SILENT GRAPH <${graph}>;"
done

echo "[INFO] installing package dbpedia_dav"
run_virtuoso_cmd "vad_install('/opt/virtuoso-opensource/vad/dbpedia_dav.vad', 0);"

#ensure that all supported formats get into the load list
#(since we have to excluse graph-files *.* won't do the trick
echo "[INFO] registring RDF documents for import"
for ext in nt nq owl rdf trig ttl xml gz; do
 run_virtuoso_cmd "ld_dir ('${store_import_dir}', '*.${ext}', NULL);"
done

echo "[INFO] deactivating auto-indexing"
run_virtuoso_cmd "DB.DBA.VT_BATCH_UPDATE ('DB.DBA.RDF_OBJ', 'ON', NULL);"

echo '[INFO] Starting load process...';

load_cmds=`cat <<EOF
log_enable(2);
checkpoint_interval(-1);
set isolation = 'uncommitted';
rdf_loader_run();
log_enable(1);
checkpoint_interval(60);
EOF`
run_virtuoso_cmd "$load_cmds";
echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'
echo "[INFO] re-activating auto-indexing"
run_virtuoso_cmd "DB.DBA.RDF_OBJ_FT_RULE_ADD (null, null, 'All');"
run_virtuoso_cmd 'DB.DBA.VT_INC_INDEX_DB_DBA_RDF_OBJ ();'
echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'
echo "[INFO] update/filling of geo index"
run_virtuoso_cmd 'rdf_geo_fill();'
echo "[INFO] making checkpoint..."
run_virtuoso_cmd 'checkpoint;'
echo "[INFO] bulk load done; terminating loader"
