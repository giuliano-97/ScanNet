#!/bin/bash	

ALLOWED_DATA_DIRS=("panoptic" "depth" "color" "pose" "intrinsic")
SCAN_DIR=
DATA_DIRS=
RECURSIVE=false

function validate_data_dirs() {
  # Validate data dirs list
  for DIR in ${DATA_DIRS[*]}
  do
    if [[ ! " ${ALLOWED_DATA_DIRS[*]} " =~ " ${DIR} " ]]
    then
      echo "Invalid data directory ${DIR}. Allowed options: ${ALLOWED_DATA_DIRS[*]}"
      exit 1
    fi
  done
}

function compress_scan_data() {
  echo "Compressing ${DATA_DIRS[*]} in $1"
  cd $1
  for DIR in ${DATA_DIRS[*]}
  do
    if [ ! -d $DIR ]
    then
      echo "Warning: $DIR not found in $1"
      continue
    fi
    tar --remove-files --use-compress-program=pigz -cf ${DIR}.tar.gz ${DIR}
  done
  cd -
}

while getopts ":hrp:d:" opt
do
  case ${opt} in
    h ) 
      echo "Compress the specified directories into gzip archives for the given scans."
      exit 0
      ;;
    p )
      if [ ! -d $OPTARG ]
      then
        echo "${OPTARG} is not a valid path!"
        exit 1
      fi
      SCAN_DIR=$OPTARG
      ;;
    d ) 
      # Parse and validate the list of directories to compress
      IFS=',' read -ra DATA_DIRS <<< "${OPTARG}"
      validate_data_dirs
      ;;
    r )
      RECURSIVE=true
      ;; 
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done

if $RECURSIVE
then
  . `which env_parallel.bash`
  env_parallel compress_scan_data ::: `find $SCAN_DIR -name scene\* -type d`
else
  compress_scan_data $SCAN_DIR
fi
