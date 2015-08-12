#!/bin/bash

SCRIPT_DIR=`dirname $0`

INSTANCE_NAME=kubemaster
CLOUD_CONFIG=$(cd "$SCRIPT_DIR" ; cd .. ; pwd -P)/cloud_configs/self.yaml

gcloud compute project-info remove-metadata --keys user-data
gcloud compute project-info add-metadata --metadata-from-file user-data="$CLOUD_CONFIG"
gcloud compute instances create $INSTANCE_NAME \
  --image https://www.googleapis.com/compute/v1/projects/coreos-cloud/global/images/coreos-stable-723-3-0-v20150804 \
  --machine-type n1-standard-1 \
  --boot-disk-size 10GB

echo "###############################################"
echo
echo "The Kubernetes compute instance is now booting."
echo "If asked for an ssh password, wait for instance to boot and try again."
echo "gcloud compute ssh core@kubemaster"
echo
echo "###############################################"

# --image https://www.googleapis.com/compute/v1/projects/coreos-cloud/global/images/coreos-stable-723-3-0-v20150804 \
# --image https://www.googleapis.com/compute/v1/projects/coreos-cloud/global/images/coreos-alpha-766-0-0-v20150807 \

