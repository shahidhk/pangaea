#!/bin/bash

SCRIPT_DIR=`dirname $0`

INSTANCE_NAME=glassic-master
CLOUD_CONFIG="${SCRIPT_DIR}/../../pangaea/files/coresos/self.yaml"

# gcloud compute project-info remove-metadata --keys user-data
gcloud compute project-info add-metadata --metadata-from-file user-data="$CLOUD_CONFIG"
gcloud compute instances create $INSTANCE_NAME \
  --image coreos \
  --zone asia-east1-a \
  --machine-type n1-standard-2 \
  --boot-disk-size 20GB \
  --boot-disk-type pd-ssd

echo "###############################################"
echo
echo "The Kubernetes compute instance is now booting."
echo "If asked for an ssh password, wait for the instance to boot and try again."
echo "gcloud compute ssh core@$INSTANCE_NAME"
echo
echo "###############################################"
