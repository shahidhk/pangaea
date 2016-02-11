#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

source "$ROOT_DIR/.pangaea"

function disks_create {
    while [ ! $# -eq 0 ]; do
        gcloud --project $GCE_PROJECT_ID compute disks delete $1 -q
        shift 2
    done
}

disks_create "${GCE_DISK_MOUNTS[@]}"
