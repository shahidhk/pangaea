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

CREATED_JSON=$ROOT_DIR/.tmp/azure_instance_create.json

KEYS_PATH=$ROOT_DIR/pangaea/pki/keys/$AZURE_NAME
KEYS_FILE=$KEYS_PATH/login_key
mkdir -p "$KEYS_PATH"
if [ ! -f "$KEYS_FILE" ]; then
    ssh-keygen -t rsa -b 4096 -C "$AZURE_NAME-hasura" -f "$KEYS_FILE" -N "" -q
else
    echo "PAN: Using login keys found at $KEYS_PATH"
fi

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
    --ssh-publickey-file "$KEYS_PATH/login_key.pub" \
\
    --nic-name "$AZURE_NAME-nic" \
    --vnet-name "$AZURE_NAME-vnet" \
    --vnet-address-prefix "10.240.0.0/24" \
    --vnet-subnet-name "$AZURE_NAME-subnet" \
    --vnet-subnet-address-prefix "10.240.0.0/24" \
    --public-ip-name "$AZURE_NAME-pubip" \
    --public-ip-domain-name "$AZURE_NAME-hasura" || true

azure network public-ip show "$AZURE_NAME" "$AZURE_NAME-pubip" --json > "$CREATED_JSON"

function init_ssl_and_setup_archive {
    local NODE_IP=$(cat "$CREATED_JSON" | jq -r '.ipAddress')

    local SETUP_TAR=$ROOT_DIR/.tmp/setup.tar # written to by init script
    local SETUP_MD5=$ROOT_DIR/.tmp/setup.md5
    "$ROOT_DIR/pangaea/setup/init_ssl_and_setup_archive.sh" create $AZURE_NAME $NODE_IP

    scp -i "$KEYS_FILE" "$SETUP_TAR" core@$NODE_IP:/tmp/setup.tar
    scp -i "$KEYS_FILE" "$SETUP_MD5" core@$NODE_IP:/tmp/setup.md5
}
init_ssl_and_setup_archive

exit

# SET UP GCE KUBERNETES INSTANCE

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
