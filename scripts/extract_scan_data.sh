#!/usr/bin/bash

# Configure export script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCANNET_DIR=`realpath ${SCRIPT_DIR}/..`
PYTHONPATH=${PYTHONPATH}:${SCANNET_DIR}/SensReader/python
EXPORT_SCRIPT=${SCANNET_DIR}/SensReader/python/reader.py

DATA_DIRS_OPTIONS=("depth" "color" "pose" "intrinsic")
DATA_DIRS=
SCAN_DIR=
RECURSIVE=false

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
		return 1
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
				OPTIONS="${OPTIONS} --export_color_images"
				;;
			depth)
				OPTIONS="${OPTIONS} --export_depth_images"
				;;
			pose)
				OPTIONS="${OPTIONS} --export_poses"
				;;
			intrinsic)
				OPTIONS="${OPTIONS} --export_intrinsics"
				;;
		esac
		EXTRACTED_DATA_DIRS="${EXTRACTED_DATA_DIRS} ${DIR}" 
	done

	if [ -z $OPTIONS ]
	then
		return 1
	fi

	# Extract the data
	PYTHONPATH=$PYTHONPATH python3 $EXPORT_SCRIPT \
		--filename $SENS_FILE \
		--output_path $1 \
		$OPTIONS

	# Compress everything now
	for DIR in $EXTRACTED_DATA_DIRS
	do
		tar --remove-files --use-compress-program=pigz -cf ${DIR}.tar.gz ${DIR}
	done
}

# Parse CLI options
while getopts ":hrs:d:" opt
do
	case ${opt} in
		h ) 
			echo "Extract scan data from .sens file."
			exit 0
			;;
		s )
			if [ ! -d $OPTARG ]
			then
				echo "${OPTARG} is not a valid dir path!"
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
shift $((OPTIND -1))

if [ -z $SCAN_DIR ]
then
	echo "-s must be specified!"
	exit 1
fi

if $RECURSIVE
then
	SCAN_DIRS=`find $SCAN_DIR -name scene\* -type d`
	. `which env_parallel.bash`
	env_parallel extract_scan_data ::: $SCAN_DIRS
else
	extract_scan_data $SCAN_DIR
fi
