#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

# ENSURE CORRECT PROVIDER

source "$ROOT_DIR/.pangaea"

if [ ! $PROVIDER = azure ]; then
    echo "PAN: Set PROVIDER=azure in .pangaea"
    exit 1
fi

# SET UP AZURE KUBERNETES INSTANCE

CLOUD_CONFIG=$ROOT_DIR/pangaea/kubernetes/cloud-config.sh

KEYS_PATH=$ROOT_DIR/pangaea/pki/$AZURE_NAME
mkdir -p "$KEYS_PATH"
ssh-keygen -t rsa -b 4096 -C "$AZURE_NAME-hasura" -f "$KEYS_PATH/login_key" -N ""

azure group create -n "$AZURE_NAME" -l "$AZURE_LOCATION"
azure vm create \
    --resource-group "$AZURE_NAME" \
    --name "$AZURE_NAME-vm" \
    --location "$AZURE_LOCATION" \
    --os-type Linux \
    --image-urn CoreOS:CoreOS:Stable:835.9.0 \
    --vm-size Standard_A0 \
    --custom-data "$CLOUD_CONFIG" \
\
    --admin-username core \
    --admin-password "Password123!" \
    --ssh-publickey-file "$KEYS_PATH/login_key.pub"
\
    --nic-name "$AZURE_NAME-nic" \
    --vnet-name "$AZURE_NAME-vnet" \
    --vnet-address-prefix "10.240.0.0/24" \
    --vnet-subnet-name "$AZURE_NAME-subnet" \
    --vnet-subnet-address-prefix "10.240.0.0/24" \
    --public-ip-name "$AZURE_NAME-pubip" \
    --public-ip-domain-name "$AZURE_NAME-hasura"

exit



# SET UP GCE KUBERNETES INSTANCE

CREATED_JSON=$ROOT_DIR/.tmp/gce_instance_create.json

GCE_DISK_ARGS=""
function generate_gce_disk_args {
    while [ ! $# -eq 0 ]; do
        GCE_DISK_ARGS="$GCE_DISK_ARGS --disk name=$1,device-name=$1"
        shift 2
    done
}
generate_gce_disk_args "${GCE_DISK_MOUNTS[@]}"

gcloud compute instances create $GCE_INSTANCE_NAME \
\
    --machine-type n1-standard-2 \
    --boot-disk-size 20GB \
    --boot-disk-type pd-ssd \
\
    $GCE_DISK_ARGS \
    --image coreos \
    --metadata-from-file user-data="$CLOUD_CONFIG" \
    --scopes https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/compute \
    --format json > "$CREATED_JSON"

function init_ssl_and_setup_archive {
    local NODE_IP=$(cat "$CREATED_JSON" | jq -r '.[0].networkInterfaces[0].accessConfigs[0].natIP')

    local SETUP_TAR=$ROOT_DIR/.tmp/setup.tar # written to by init script
    local SETUP_MD5=$ROOT_DIR/.tmp/setup.md5
    "$ROOT_DIR/pangaea/setup/init_ssl_and_setup_archive.sh" create $GCE_INSTANCE_NAME $NODE_IP

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
