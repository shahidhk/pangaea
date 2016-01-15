#!/bin/bash

set -e

if [ ! "$#" = "2" ]; then
    echo "Adds an azure nat rule to forward traffic from <frontend-port> to kubernetes <service-name>"
    echo "USAGE: $0 <service-name> <frontend-port>"
    exit 1
fi

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

# TODO: use a load balancer rule instead of a nat rule for better availability

"$ROOT_DIR/pangaea/azure/create-nat-rule.sh" \
    $2 \
    $(kubectl get svc "$1" -o json | jq -r '.spec.ports[0].nodePort') \
    "svc-$1"
