#!/bin/bash

set -e

SCRIPT_DIR=`dirname $0`
ROOT_DIR=$SCRIPT_DIR/../..

source $ROOT_DIR/.pangaea

CLOUD_CONFIG=$ROOT_DIR/pangaea/kubernetes/cloud-config.sh

CREATED_JSON=$ROOT_DIR/.tmp/gce_instance_create.json

gcloud compute instances create "$GCE_INSTANCE_NAME" \
  --image coreos \
  --metadata-from-file user-data="$CLOUD_CONFIG" \
  --zone asia-east1-a \
  --machine-type n1-standard-2 \
  --boot-disk-size 20GB \
  --boot-disk-type pd-ssd \
  --scopes https://www.googleapis.com/auth/cloud.useraccounts.readonly,https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/compute \
  --format json > "$CREATED_JSON"

function init_ssl {
  local PKI_DIR=$ROOT_DIR/pangaea/pki
  local SSL_TARBALL_PATH=$PKI_DIR/keys/$GCE_INSTANCE_NAME
  local SSL_INIT_SCRIPT_PATH=$PKI_DIR/init-ssl

  rm -rf $SSL_TARBALL_PATH

  local NODE_IP=$(cat "$CREATED_JSON" | jq -r '.[0].networkInterfaces[0].accessConfigs[0].natIP')

  mkdir -p "$SSL_TARBALL_PATH"
  "$SSL_INIT_SCRIPT_PATH" "$SSL_TARBALL_PATH" IP.1=10.3.0.1,IP.2=$NODE_IP

  cp "$SSL_TARBALL_PATH/controller.tar" "$PKI_DIR/keys/_CURRENT.tar"
}
init_ssl

function init_setup_archive {
  local SETUP_ARCHIVE_PATH=$ROOT_DIR/.tmp/setup.tar
  tar -cf "$SETUP_ARCHIVE_PATH" -C "$ROOT_DIR" .pangaea pangaea

  gcloud compute copy-files "$SETUP_ARCHIVE_PATH" "$GCE_INSTANCE_NAME:/tmp/setup.tar"
}
init_setup_archive

gcloud compute firewall-rules create "$GCE_INSTANCE_NAME-kubeapiserver-443" --allow tcp:443 --description "$GCE_INSTANCE_NAME: kubernetes api server secure port"

if [ $PROVIDER = gce ]; then
  "$ROOT_DIR/pangaea/bin/kubectl_setup"
else
  echo "Set PROVIDER=gce in .pangaea and run pangaea/bin/kubectl_setup to configure kubectl"
fi

echo
echo "###############################################"
echo
echo "The Kubernetes compute instance is now booting."
echo "gcloud compute ssh core@$GCE_INSTANCE_NAME"
echo
echo "###############################################"
echo
