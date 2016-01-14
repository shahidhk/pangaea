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

CREATED_JSON=$ROOT_DIR/.tmp/azure_public_ip.json
CREATED_BIP_JSON=$ROOT_DIR/.tmp/azure_bip.json

KEYS_PATH=$ROOT_DIR/pangaea/pki/keys/$AZURE_NAME
KEYS_FILE=$KEYS_PATH/login_key
mkdir -p "$KEYS_PATH"
if [ ! -f "$KEYS_FILE" ]; then
    ssh-keygen -t rsa -b 4096 -C "$AZURE_NAME-hasura" -f "$KEYS_FILE" -N "" -q
else
    echo "PAN: Using login keys found at $KEYS_PATH"
fi

# PROVISION AZURE RESOURCES

# TODO: use template based deployments instead

azure group create -n "$AZURE_NAME" -l "$AZURE_LOCATION"

azure network vnet create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-vnet" --location "$AZURE_LOCATION" --address-prefixes "10.240.0.0/24"
azure network vnet subnet create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-subnet" --vnet-name "$AZURE_NAME-vnet" --address-prefix "10.240.0.0/24"
azure network public-ip create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-pubip" --location "$AZURE_LOCATION" --allocation-method Static --domain-name-label "$AZURE_NAME-hasura"
azure network lb create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-lb" --location "$AZURE_LOCATION"
azure network lb frontend-ip create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-fip" --lb-name "$AZURE_NAME-lb" --public-ip-name "$AZURE_NAME-pubip"
azure network lb address-pool create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-bip" --lb-name "$AZURE_NAME-lb" --json | tee "$CREATED_BIP_JSON"

azure network nic create \
    --resource-group "$AZURE_NAME" --name "$AZURE_NAME-nic" --location "$AZURE_LOCATION" \
    --subnet-name "$AZURE_NAME-subnet" --subnet-vnet-name "$AZURE_NAME-vnet" \
    --lb-address-pool-ids "$(cat "$CREATED_BIP_JSON" | jq -r '.id')"

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
    --ssh-publickey-file "$KEYS_PATH/login_key.pub" \
\
    --nic-name "$AZURE_NAME-nic"

# EXPOSE SSH AND KUBEAPISERVER

NAT_SCRIPT=$ROOT_DIR/pangaea/azure/create-nat-rule.sh
"$NAT_SCRIPT" 22 22 ssh
"$NAT_SCRIPT" 443 443 kubeapiserver

# BOOTSTRAP KUBERNETES

azure network public-ip show "$AZURE_NAME" "$AZURE_NAME-pubip" --json > "$CREATED_JSON"
NODE_IP=$(cat "$CREATED_JSON" | jq -r '.ipAddress')

function init_ssl_and_setup_archive {

    local SETUP_TAR=$ROOT_DIR/.tmp/setup.tar # written to by init script
    local SETUP_MD5=$ROOT_DIR/.tmp/setup.md5
    "$ROOT_DIR/pangaea/setup/init_ssl_and_setup_archive.sh" create $AZURE_NAME $NODE_IP

    local SSH_RETRIES=0

    while ! ssh -o StrictHostKeyChecking=no -i "$KEYS_FILE" core@$NODE_IP date &>/dev/null; do
        if [ $SSH_RETRIES -gt 5 ]; then
            echo "SSH retries failed. Resources have been provisioned under group $AZURE_NAME"
            exit 1
        fi
        sleep 5
        SSH_RETRIES=$((SSH_RETRIES+1))
    done

    scp -o StrictHostKeyChecking=no -i "$KEYS_FILE" "$SETUP_TAR" core@$NODE_IP:/tmp/setup.tar
    scp -o StrictHostKeyChecking=no -i "$KEYS_FILE" "$SETUP_MD5" core@$NODE_IP:/tmp/setup.md5
}
init_ssl_and_setup_archive

"$ROOT_DIR/pangaea/bin/kubectl_setup"

echo
echo "###############################################"
echo
echo "The Kubernetes compute instance is now booting."
echo "pangaea/azure/ssh.sh $NODE_IP"
echo
echo "###############################################"
echo
