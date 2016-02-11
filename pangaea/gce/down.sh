#!/bin/bash

set -e

SCRIPT_DIR=`dirname $0`
ROOT_DIR=$SCRIPT_DIR/../..

source $ROOT_DIR/.pangaea

gcloud --project $GCE_PROJECT_ID compute instances delete "$GCE_INSTANCE_NAME" -q

gcloud --project $GCE_PROJECT_ID compute firewall-rules delete "$GCE_INSTANCE_NAME-kubeapiserver-443" -q || true
