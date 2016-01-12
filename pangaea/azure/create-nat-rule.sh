#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "USAGE: $0 <port-number-to-forward> <name-for-nat-rule>"
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
    --resource-group "$AZURE_NAME" --name "$AZURE_NAME-nat-$2" --lb-name "$AZURE_NAME-lb" \
    --protocol tcp --frontend-port "$1" --backend-port
