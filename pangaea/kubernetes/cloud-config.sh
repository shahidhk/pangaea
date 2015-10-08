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
    local K8S_BINARY_HASH=a9e46f18ffd67602619cd2f88472c71a

    if [ ! -e $CWD/kubernetes.tar.gz ] || ! md5sum -c <(echo "$K8S_BINARY_HASH $CWD/kubernetes.tar.gz"); then
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
    # tar uploaded from workstation with pki keys
    local SETUP_TAR=/tmp/setup.tar

    while [ ! -e $SETUP_TAR ]
    do
      sleep 2
    done
    mkdir -p $TMP_PATH/setup
    tar -C $TMP_PATH/setup -xf $SETUP_TAR

    mkdir -p /etc/kubernetes/ssl
    tar -C /etc/kubernetes/ssl -xf $TMP_PATH/setup/pangaea/pki/keys/_CURRENT.tar
}

init_kube_binaries
init_setup_and_ssl

SETUP_OPT_FILE=$PANGAEA_PATH/../.pangaea
source "$SETUP_OPT_FILE"

source "$PANGAEA_PATH/kubernetes/kubernetes-installer.sh"

source "$PANGAEA_PATH/kubernetes/kubernetes-services.sh"
