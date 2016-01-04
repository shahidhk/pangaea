#!/bin/bash

set -e

SCRIPT_DIR=`dirname $0`
ROOT_DIR=$SCRIPT_DIR/../..

COMMAND=$1

source $ROOT_DIR/.pangaea

gcloud compute instances delete "$GCE_INSTANCE_NAME" -q

gcloud compute firewall-rules delete "$GCE_INSTANCE_NAME-kubeapiserver-443" -q || true
