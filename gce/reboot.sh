#!/bin/bash

gcloud compute instances delete kubemaster -q

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/bootstrap.sh

gcloud compute ssh core@kubemaster

