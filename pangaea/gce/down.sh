#!/bin/bash

set -e

SCRIPT_DIR=`dirname $0`
ROOT_DIR=$SCRIPT_DIR/../..

EXT_IP_CREATED_JSON=$ROOT_DIR/.tmp/gce_ext_ip_create.json
COMMAND=$1

source $ROOT_DIR/.pangaea

gcloud compute instances delete "$GCE_INSTANCE_NAME" -q

gcloud compute firewall-rules delete "$GCE_INSTANCE_NAME-kubeapiserver-443" -q || true

if [ "$COMMAND" = "setup" ]
    then
	gcloud compute addresses delete "${GCE_INSTANCE_NAME}-ext-ip" --region asia-east1 -q 
	rm $EXT_IP_CREATED_JSON
fi
