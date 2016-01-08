#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

COMMAND=$1

# ENSURE CORRECT PROVIDER

source "$ROOT_DIR/.pangaea"

if [ ! $PROVIDER = gce ]; then
    echo "PAN: Set PROVIDER=gce in .pangaea"
    exit 1
fi

# SET UP GCE KUBERNETES INSTANCE

CLOUD_CONFIG=$ROOT_DIR/pangaea/kubernetes/cloud-config.sh

CREATED_JSON=$ROOT_DIR/.tmp/gce_instance_create.json

GCE_DISK_ARGS=""
function generate_gce_disk_args {
    while [ ! $# -eq 0 ]; do
        GCE_DISK_ARGS="$GCE_DISK_ARGS --disk name=$1,device-name=$1"
        shift 2
    done
}
generate_gce_disk_args "${GCE_DISK_MOUNTS[@]}"

GCE_BOOT_DISK_ARGS="--disk name=$GCE_BOOT_DISK,boot=yes,auto-delete=no,mode=rw"

gcloud compute instances create $GCE_INSTANCE_NAME \
\
    --machine-type $GCE_MACHINE_TYPE\
    $GCE_BOOT_DISK_ARGS \
    $GCE_DISK_ARGS \
    --address $GCE_EXT_IP_NAME \
    --metadata-from-file user-data="$CLOUD_CONFIG" \
    --scopes https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/compute \
    --format json > "$CREATED_JSON"


NODE_IP=$(cat "$CREATED_JSON" | jq -r '.[0].networkInterfaces[0].accessConfigs[0].natIP')

function init_ssl_and_setup_archive {

    local SETUP_TAR=$ROOT_DIR/.tmp/setup.tar # written to by init script
    local SETUP_MD5=$ROOT_DIR/.tmp/setup.md5
    "$ROOT_DIR/pangaea/setup/init_ssl_and_setup_archive.sh" create $GCE_INSTANCE_NAME $NODE_IP

    gcloud compute copy-files "$SETUP_TAR" "core@$GCE_INSTANCE_NAME:/tmp/setup.tar"
    gcloud compute copy-files "$SETUP_MD5" "core@$GCE_INSTANCE_NAME:/tmp/setup.md5"
}

SSH_RETRIES=0

while ! gcloud compute ssh core@$GCE_INSTANCE_NAME --command 'date' &>/dev/null; do
    if [ $SSH_RETRIES -gt 5 ]; then
        echo 'SSH retries failed. Error occured within VM. Deleting VM and exiting'
        gcloud compute instances delete $GCE_INSTANCE_NAME -q
        exit
    fi  
    sleep 10
    SSH_RETRIES=$((SSH_RETRIES+1))
done


if [ "$COMMAND" = "init" ]; then
    init_ssl_and_setup_archive
fi

gcloud compute firewall-rules create "$GCE_INSTANCE_NAME-kubeapiserver-443" --allow tcp:443 --description "$GCE_INSTANCE_NAME: kubernetes api server secure port"

"$ROOT_DIR/pangaea/bin/kubectl_setup"

echo
echo "###############################################"
echo
echo "The Kubernetes compute instance is now booting."
echo "gcloud compute ssh core@$GCE_INSTANCE_NAME"
echo "External IP address is $NODE_IP"
echo
echo "###############################################"
echo
