#!/bin/bash

set -e

SCRIPT_DIR=`dirname $0`
ROOT_DIR=$SCRIPT_DIR/../..

source $ROOT_DIR/.pangaea

gcloud compute instances delete "$GCE_INSTANCE_NAME" -q

if [ "$ENVIRONMENT" = "development" ]; then
  gcloud compute firewall-rules delete "$GCE_INSTANCE_NAME-kubeapiserver-8080" -q || true
fi
