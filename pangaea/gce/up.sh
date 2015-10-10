#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

# ENSURE CORRECT PROVIDER

source "$ROOT_DIR/.pangaea"

if [ ! $PROVIDER = gce ]; then
    echo "PAN: Set PROVIDER=gce in .pangaea"
    exit 1
fi

# SET UP GCE KUBERNETES INSTANCE

CLOUD_CONFIG=$ROOT_DIR/pangaea/kubernetes/cloud-config.sh

CREATED_JSON=$ROOT_DIR/.tmp/gce_instance_create.json

gcloud compute instances create "$GCE_INSTANCE_NAME" \
    --image coreos \
    --metadata-from-file user-data="$CLOUD_CONFIG" \
    --zone asia-east1-a \
    --machine-type n1-standard-2 \
    --boot-disk-size 20GB \
    --boot-disk-type pd-ssd \
    --scopes https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/compute \
    --format json > "$CREATED_JSON"

function init_ssl_and_setup_archive {
    local NODE_IP=$(cat "$CREATED_JSON" | jq -r '.[0].networkInterfaces[0].accessConfigs[0].natIP')

    local SETUP_TAR=$ROOT_DIR/.tmp/setup.tar # written to by init script
    local SETUP_MD5=$ROOT_DIR/.tmp/setup.md5
    "$ROOT_DIR/pangaea/setup/init_ssl_and_setup_archive.sh" $GCE_INSTANCE_NAME $NODE_IP

    gcloud compute copy-files "$SETUP_TAR" "$GCE_INSTANCE_NAME:/tmp/setup.tar"
    gcloud compute copy-files "$SETUP_MD5" "$GCE_INSTANCE_NAME:/tmp/setup.md5"
}
init_ssl_and_setup_archive

gcloud compute firewall-rules create "$GCE_INSTANCE_NAME-kubeapiserver-443" --allow tcp:443 --description "$GCE_INSTANCE_NAME: kubernetes api server secure port"

"$ROOT_DIR/pangaea/bin/kubectl_setup"

echo
echo "###############################################"
echo
echo "The Kubernetes compute instance is now booting."
echo "gcloud compute ssh core@$GCE_INSTANCE_NAME"
echo
echo "###############################################"
echo
