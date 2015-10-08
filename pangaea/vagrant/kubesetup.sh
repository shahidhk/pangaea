#!/bin/bash

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

# ENSURE CORRECT PROVIDER

SETUP_OPT_FILE=$ROOT_DIR/.pangaea
source $SETUP_OPT_FILE

if [ ! $PROVIDER = vagrant ]; then
    echo "PAN: Set PROVIDER to vagrant in your .pangaea file. Aborting kubesetup."
    exit 1
fi

VAGRANT=$ROOT_DIR/pangaea/bin/vagrant

# CONFIRM USER ACTION

if ! "$VAGRANT" status | grep "not created"; then
    echo "WARNING: This will restore your VM to a bare Kubernetes setup"
    echo "         You will lose all unsaved/unsnapshotted changes!"

    read -p "Are you sure? [y/n]" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting kubesetup"
        exit 1
    fi
fi

# KUBE SETUP

if "$VAGRANT" snapshot list | grep KubeSetup &>/dev/null; then
    "$VAGRANT" snapshot go KubeSetup -r
else
    echo "PAN: Setting up bare Kubernetes VM. This could take a while..."
    "$VAGRANT" destroy -f
    "$VAGRANT" up
    # "$ROOT_DIR/pangaea/bin/kubectl_setup"

    echo "PAN: Provisioned machine, waiting for Kubernetes setup..."
    KUBE_CORE=(kube-apiserver kube-controller-manager kube-dns kube-proxy kube-scheduler)
    for el in "${KUBE_CORE[@]}"; do
        while ! "$VAGRANT" ssh -c 'kubectl get po --namespace=kube-system' | grep "$el" &>/dev/null; do
            sleep 5
        done
    done

    echo "PAN: We have Kubernetes core. Creating a snapshot."
    "$VAGRANT" snapshot take KubeSetup
fi

echo "PAN: kubesetup complete"
