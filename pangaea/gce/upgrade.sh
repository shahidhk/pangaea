#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

# ENSURE CORRECT PROVIDER

source "$ROOT_DIR/.pangaea"

if [ ! $PROVIDER = gce ]; then
    echo "PAN: Set PROVIDER=gce in .pangaea"
    exit 1
fi

# CREATE BOOTSTRAP SCRIPTS

"$ROOT_DIR/pangaea/setup/init_ssl_and_setup_archive.sh" upgrade $GCE_INSTANCE_NAME

# UPGRADE GCE KUBERNETES INSTANCE

CLOUD_CONFIG=$ROOT_DIR/pangaea/kubernetes/cloud-config.sh

gcloud compute instances add-metadata $GCE_INSTANCE_NAME \
    --metadata-from-file user-data="$CLOUD_CONFIG"

# cloud config will recreate the setup directory from the new bootstrap scripts

gcloud compute ssh core@$GCE_INSTANCE_NAME --command 'sudo rm -rf /tmp/setup.tar /opt/panwd/setup'

SETUP_TAR=$ROOT_DIR/.tmp/setup.tar # written to by init script
SETUP_MD5=$ROOT_DIR/.tmp/setup.md5

# reboot to reconfigure

gcloud compute ssh core@$GCE_INSTANCE_NAME --command 'sudo reboot' || true

while ! gcloud compute ssh core@$GCE_INSTANCE_NAME --command 'date' &>/dev/null; do
    sleep 2
done

gcloud compute copy-files "$SETUP_TAR" "$GCE_INSTANCE_NAME:/tmp/setup.tar"
gcloud compute copy-files "$SETUP_MD5" "$GCE_INSTANCE_NAME:/tmp/setup.md5"
