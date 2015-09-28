#!/bin/bash

set -e

export PANGAEA_PATH=/tmp/setup/pangaea

function init_binaries {
    [ ! -x /opt/bin/kubectl ] || return 0

    local CWD=/pangaea/.tmp
    local K8S_VER=v1.0.6

    if [ ! -e $CWD/kubernetes/server/kubernetes/server/bin/kubelet ]; then
        mkdir -p $CWD
        curl -L -o $CWD/kubernetes.tar.gz https://github.com/kubernetes/kubernetes/releases/download/$K8S_VER/kubernetes.tar.gz

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

function init_setup_and_ssl {
    while [ ! -e /tmp/setup.tar ]
    do
      sleep 2
    done
    mkdir -p /tmp/setup
    tar -C /tmp/setup -xf /tmp/setup.tar

    mkdir -p /etc/kubernetes/ssl
    tar -C /etc/kubernetes/ssl -xf /tmp/setup/pangaea/pki/keys/_CURRENT.tar
}

init_binaries
init_setup_and_ssl

SETUP_OPT_FILE=$PANGAEA_PATH/../.pangaea
source "$SETUP_OPT_FILE"

"$PANGAEA_PATH/kubernetes/kubernetes-installer.sh"

source "$PANGAEA_PATH/kubernetes/kubernetes-services.sh"
