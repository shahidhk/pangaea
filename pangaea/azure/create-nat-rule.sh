#!/bin/bash

set -e

if [ ! "$#" = "3" ]; then
    echo "USAGE: $0 <frontend-port> <backend-port> <name-for-nat-rule>"
    exit 1
fi

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

# ENSURE CORRECT PROVIDER

source "$ROOT_DIR/.pangaea"

if [ ! $PROVIDER = azure ]; then
    echo "PAN: Set PROVIDER=azure in .pangaea"
    exit 1
fi

# Create NAT rule

azure network lb inbound-nat-rule create \
    --resource-group "$AZURE_NAME" --name "$AZURE_NAME-nat-$3" --lb-name "$AZURE_NAME-lb" \
    --protocol tcp --frontend-port "$1" --backend-port "$2"

# Note: --name here is the NIC name, not a resource name
azure network nic inbound-nat-rule add \
    --resource-group "$AZURE_NAME" --name "$AZURE_NAME-nic" --lb-name "$AZURE_NAME-lb" \
    --inbound-nat-rule-name "$AZURE_NAME-nat-$3"
