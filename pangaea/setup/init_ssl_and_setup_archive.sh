#!/bin/bash

# init ssl and setup archive, to be uploaded to kubernetes node during bootstrap
#

INSTANCE_NAME=$1
NODE_IP=$2

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

function init_ssl {
    local PKI_DIR=$ROOT_DIR/pangaea/pki
    local SSL_TARBALL_PATH=$PKI_DIR/keys/$INSTANCE_NAME
    local SSL_INIT_SCRIPT_PATH=$PKI_DIR/init-ssl

    rm -rf "$SSL_TARBALL_PATH"

    mkdir -p "$SSL_TARBALL_PATH"
    "$SSL_INIT_SCRIPT_PATH" "$SSL_TARBALL_PATH" IP.1=10.3.0.1,IP.2=$NODE_IP

    cp "$SSL_TARBALL_PATH/controller.tar" "$PKI_DIR/keys/_CURRENT.tar"
}

function init_setup_archive {
    local SETUP_TAR=$ROOT_DIR/.tmp/setup.tar
    local SETUP_MD5=$ROOT_DIR/.tmp/setup.md5

    tar -zcf "$SETUP_TAR" -C "$ROOT_DIR" .pangaea pangaea
    md5sum "$SETUP_TAR" | cut -f 1 -d " " > "$SETUP_MD5"
}

init_ssl
init_setup_archive

