#!/usr/bin/bash

# Configure export script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCANNET_DIR=`realpath ${SCRIPT_DIR}/..`
PYTHONPATH=${PYTHONPATH}:${SCANNET_DIR}/SensReader/python
EXPORT_SCRIPT=${SCANNET_DIR}/SensReader/python/reader.py

DATA_DIRS_OPTIONS=("depth" "color" "pose" "intrinsic")
SCANS_LIST_FILE=
DATA_DIRS=
DOWNLOAD_DIR=

function validate_data_dirs() {
	# Validate data dirs list
	for DIR in ${DATA_DIRS[*]}
	do
		if [[ ! " ${DATA_DIRS_OPTIONS[*]} " =~ " ${DIR} " ]]
		then
			echo "Invalid data directory ${DIR}. Allowed options: ${DATA_DIRS_OPTIONS[*]}"
			exit 1
		fi
	done
}

function check_if_exists_and_not_empty() {
	if [ -f $1 ] && [ -s $1 ]
	then
		return 0
	else
		return 1
	fi
}

function extract_scan_data() {
	cd $1
	SENS_FILE=$(realpath `ls *.sens`)
	if [ ! -f $SENS_FILE ]
	then
		echo "Warning: .sens not found in $1. Skipped."
		return
	fi

	EXTRACTED_DATA_DIRS=""

	# Construct export script options
	OPTIONS=""
	for DIR in ${DATA_DIRS[*]}
	do
		ARCHIVE=$(pwd)/${DIR}.tar.gz
		if check_if_exists_and_not_empty $ARCHIVE
		then
			continue
		fi
		case ${DIR} in
			color)
				OPTIONS="${OPTIONS} --export_color"
				;;
			depth)
				OPTIONS="${OPTIONS} --export_depth"
				;;
			pose)
				OPTIONS="${OPTIONS} --export_pose"
				;;
			intrinsic)
				OPTIONS="${OPTIONS} --export_intrinsic"
				;;
		esac
		EXTRACTED_DATA_DIRS="${EXTRACTED_DATA_DIRS} ${DIR}" 
	done

	if [ -z "$OPTIONS" ]
	then
    echo "Nothing to extract in $1"
		return
	fi

	# Extract the data
	PYTHONPATH=$PYTHONPATH python3 $EXPORT_SCRIPT \
		--filename $SENS_FILE \
		--output_path $1 \
		--image_size 640 480 \
		$OPTIONS

	# Compress everything now
	for DIR in $EXTRACTED_DATA_DIRS
	do
    if [ ! -d ${DIR} ]
    then
      continue
    fi
		tar --remove-files --use-compress-program=pigz -cf ${DIR}.tar.gz ${DIR}
	done
}

# Parse CLI options
while getopts ":hp:d:f:" opt
do
	case ${opt} in
		h ) 
			echo "Extract scan data from .sens file.\n"
			echo "Usage extract_scan_data.sh -p <SCANS_DOWNLOAD_DIR> -d {depth,color,pose.intrinsic} -f <SCANS_LIST_FILE>"
			exit 0
			;;
		p )
			if [ ! -d $OPTARG ]
			then
				echo "${OPTARG} is not a valid dir path!"
				exit 1
			fi
			DOWNLOAD_DIR=$OPTARG
			;;
		d ) 
			# Parse and validate the list of directories to compress
			IFS=',' read -ra DATA_DIRS <<< "${OPTARG}"
			validate_data_dirs
			;;
		f )
			SCANS_LIST_FILE=$OPTARG
			;;
		\? )
			echo "Invalid Option: -$OPTARG" 1>&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))

if [ -z $DOWNLOAD_DIR ]
then
	echo "The scans download dir must be specified with -p <DOWNLOAD_DIR>!"
	exit 1
fi


. `which env_parallel.bash`
if [ -z $SCANS_LIST_FILE ]
then
	# Extract all the scans in the download directory
	env_parallel extract_scan_data ::: `find $DOWNLOAD_DIR -name scene\* -type d`
else
	# Read the directory to extract from a file
	env_parallel extract_scan_data ::: $(cat $SCANS_LIST_FILE | sed 's|^|'"${DOWNLOAD_DIR%%/}"'/|g')
fi
