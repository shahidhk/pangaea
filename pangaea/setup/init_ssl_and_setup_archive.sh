#!/bin/bash

# init ssl and setup archive to be uploaded to kubernetes node during bootstrap

set -e

CREATE_OR_UPGRADE=$1
INSTANCE_NAME=$2

NODE_IP=$3

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

PKI_DIR=$ROOT_DIR/pangaea/pki
SSL_TARBALL_PATH=$PKI_DIR/keys/$INSTANCE_NAME

function init_ssl {
    local SSL_INIT_SCRIPT_PATH=$PKI_DIR/init-ssl

    rm -rf "$SSL_TARBALL_PATH/*"

    mkdir -p "$SSL_TARBALL_PATH"
    "$SSL_INIT_SCRIPT_PATH" "$SSL_TARBALL_PATH" IP.1=10.3.0.1,IP.2=$NODE_IP,IP.3=127.0.0.1
}

function init_ssl_archive {
    cp "$SSL_TARBALL_PATH/controller.tar" "$PKI_DIR/keys/_CURRENT.tar"
}

function init_setup_archive {
    local SETUP_TAR=$ROOT_DIR/.tmp/setup.tar
    local SETUP_MD5=$ROOT_DIR/.tmp/setup.md5

    tar -zcf "$SETUP_TAR" -C "$ROOT_DIR" .pangaea pangaea

    if which md5sum &>/dev/null; then # linux
        md5sum "$SETUP_TAR" | cut -f 1 -d " " > "$SETUP_MD5"
    else # mac
        md5 -q "$SETUP_TAR" > "$SETUP_MD5"
    fi
}

if [ $CREATE_OR_UPGRADE = create ]; then
    init_ssl
fi
init_ssl_archive
init_setup_archive

