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

# create azure resources

azure group create -n "$AZURE_NAME" -l "$AZURE_LOCATION"

# create network, lb, public ip, nic

azure network vnet create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-vnet" --location "$AZURE_LOCATION" --address-prefixes "10.240.0.0/24"
azure network vnet subnet create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-subnet" --vnet-name "$AZURE_NAME-vnet" --address-prefix "10.240.0.0/24"
azure network public-ip create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-pubip" --location "$AZURE_LOCATION" --allocation-method Static --domain-name-label "$AZURE_NAME-hasura"
azure network lb create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-lb" --location "$AZURE_LOCATION"
azure network lb frontend-ip create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-fip" --lb-name "$AZURE_NAME-lb" --public-ip-name "$AZURE_NAME-pubip"
azure network lb address-pool create --resource-group "$AZURE_NAME" --name "$AZURE_NAME-bip" --lb-name "$AZURE_NAME-lb"
azure network lb inbound-nat-rule create \
    --resource-group "$AZURE_NAME" --name "$AZURE_NAME-nat-kubeapiserver" --lb-name "$AZURE_NAME-lb" \
    --protocol tcp --frontend-port 8080 --backend-port

# azure network lb address-pool show #

# azure network nic create -g nrprg -n lb-nic1-be --subnet-name nrpvnetsubnet --subnet-vnet-name nrpvnet -d "/subscriptions/####################################/resourceGroups/nrprg/providers/Microsoft.Network/loadBalancers/nrplb/backendAddressPools/NRPbackendpool" -e "/subscriptions/####################################/resourceGroups/nrprg/providers/Microsoft.Network/loadBalancers/nrplb/inboundNatRules/rdp1" eastus
azure network nic create \
    --resource-group "$AZURE_NAME" --name "$AZURE_NAME-nic" \
    --subnet-name "$AZURE_NAME-subnet" --subnet-vnet-name "$AZURE_NAME-vnet" \
    --lb-address-pool-ids "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_NAME/providers/Microsoft.Network/loadBalancers/$AZURE_NAME-lb/backendAddressPools/$AZURE_NAME-bip" \
    --lb-inbound-nat-rule-ids "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_NAME/providers/Microsoft.Network/loadBalancers/$AZURE_NAME-lb/inboundNatRules/$AZURE_NAME-nat-kubeapiserver" 

# use nic here
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
    --public-ip-domain-name "$AZURE_NAME-hasura" || true # TODO: remove true

#TODO: rule add
# XXX: azure network nic inbound-nat-rule add

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
