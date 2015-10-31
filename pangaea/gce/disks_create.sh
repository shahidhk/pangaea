#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

source "$ROOT_DIR/.pangaea"

function disks_create {
    while [ ! $# -eq 0 ]; do
        gcloud compute disks create $1 --size 10GB
        shift 2
    done
}

disks_create "${GCE_DISK_MOUNTS[@]}"
