#!/bin/bash

SCRIPT_DIR=`dirname $0`

INSTANCE_NAME=kubemaster
CLOUD_CONFIG=$(cd "$SCRIPT_DIR" ; cd .. ; pwd -P)/cloud-configs/self.yaml.bak2

gcloud compute instances create $INSTANCE_NAME \
  --image https://www.googleapis.com/compute/v1/projects/coreos-cloud/global/images/coreos-alpha-766-0-0-v20150807 \
  --machine-type n1-standard-1 \
  --boot-disk-size 10GB \
  --metadata-from-file user-data="$CLOUD_CONFIG"

# --image https://www.googleapis.com/compute/v1/projects/coreos-cloud/global/images/coreos-stable-723-3-0-v20150804 \

