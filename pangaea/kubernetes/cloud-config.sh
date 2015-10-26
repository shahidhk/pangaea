#!/bin/bash

set -e

TMP_PATH=/opt/tmp
mkdir -p $TMP_PATH

# setup files like installation scripts and pki keys
PANGAEA_PATH=$TMP_PATH/setup/pangaea

function init_kube_binaries {
    [ ! -x /opt/bin/kubectl ] || return 0

    local CWD=$TMP_PATH

    local K8S_VER=v1.0.6
    local K8S_BINARY_MD5=a9e46f18ffd67602619cd2f88472c71a

    if ! md5sum -c <(echo "$K8S_BINARY_MD5  $CWD/kubernetes.tar.gz"); then
        echo "PAN: downloading Kubernetes binaries"
        curl -L -o $CWD/kubernetes.tar.gz https://github.com/kubernetes/kubernetes/releases/download/$K8S_VER/kubernetes.tar.gz
    else
        echo "PAN: using cached Kubernetes binaries"
    fi

    if [ ! -e $CWD/kubernetes/server/kubernetes/server/bin/kubelet ]; then
        tar -xzf $CWD/kubernetes.tar.gz -C $CWD/
        tar -xzf $CWD/kubernetes/server/kubernetes-server-linux-amd64.tar.gz -C $CWD/kubernetes/server/
    fi

    mkdir -p /opt/bin

    rm -f /opt/bin/kubelet
    rm -f /opt/bin/kubectl

    # ln -s results in permissions problems for user core
    cp $CWD/kubernetes/server/kubernetes/server/bin/kubelet /opt/bin/kubelet
    cp $CWD/kubernetes/platforms/linux/amd64/kubectl /opt/bin/kubectl

    chmod +x /opt/bin/kubelet
    chmod +x /opt/bin/kubectl
}

# creates PANGAEA_PATH
function init_setup_and_ssl {
    # setup tar uploaded from workstation with pki keys and installation files
    local SETUP_TAR=/tmp/setup.tar
    local SETUP_MD5=/tmp/setup.md5

    if [ ! -e $TMP_PATH/setup ]; then
        while ! md5sum -c <(echo "$(cat $SETUP_MD5)  $SETUP_TAR"); do
          sleep 2
        done

        cp $SETUP_TAR $TMP_PATH
        cp $SETUP_MD5 $TMP_PATH

        mkdir -p $TMP_PATH/setup
        tar -C $TMP_PATH/setup -xzf $SETUP_TAR

        mkdir -p /etc/kubernetes/ssl
        tar -C /etc/kubernetes/ssl -xf $TMP_PATH/setup/pangaea/pki/keys/_CURRENT.tar
    fi
}

init_kube_binaries
init_setup_and_ssl

SETUP_OPT_FILE=$PANGAEA_PATH/../.pangaea
source "$SETUP_OPT_FILE"

source "$PANGAEA_PATH/kubernetes/kubernetes-installer.sh"

source "$PANGAEA_PATH/kubernetes/kubernetes-services.sh"
