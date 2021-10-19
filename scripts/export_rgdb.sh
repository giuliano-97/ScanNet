#!/usr/bin/env bash

if [ -z $1 ]
then
    echo "Usage: export_rgbd.sh <PATH_TO_SCANS_DIRECTORY>"
    exit 1
fi
export SCANS_DIR_PATH=`realpath $1`

# Get scannet repo absolute path
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCANNET_DIR=`realpath ${SCRIPT_DIR}/..`

# Configure export script
export PYTHONPATH=${PYTHONPATH}:${SCANNET_DIR}/SensReader/python
export EXPORT_SCRIPT_PATH=${SCANNET_DIR}/SensReader/python/reader.py

# Wrap calls to export script in function
export_fn () {
    SCAN_ID=$1
    echo "Exporting the data for scan $SCAN_ID"
    SCAN_DIR=$SCANS_DIR_PATH/$SCAN_ID
    SENS_FILE=$SCAN_DIR/${SCAN_ID}.sens
    python3 $EXPORT_SCRIPT_PATH --filename $SENS_FILE --output_path $SCAN_DIR --export_depth_images --export_color_images --export_poses --export_intrinsics
}
export -f export_fn

# Export data in parallel
cat ${SCANNET_DIR}/Tasks/Benchmark/scannetv2_val.txt | parallel --jobs 16 --bar export_fn {}




