#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <ip address>"
    exit
fi

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

source "$ROOT_DIR/.pangaea"

ssh -i "$ROOT_DIR/pangaea/pki/$AZURE_NAME/login_key" $1
