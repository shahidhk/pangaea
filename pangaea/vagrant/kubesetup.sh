#!/bin/bash

SCRIPT_DIR=$(dirname $0)
ROOT_DIR=$SCRIPT_DIR/../..

# ENSURE CORRECT PROVIDER

source "$ROOT_DIR/.pangaea"

if [ ! $PROVIDER = vagrant ]; then
    echo "PAN: Set PROVIDER=vagrant in .pangaea. Aborting kubesetup."
    exit 1
fi

VAGRANT=$ROOT_DIR/pangaea/bin/vagrant

# CONFIRM USER ACTION

if ! "$VAGRANT" status | grep "not created" &>/dev/null; then
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

function assure_downloaded {
    for i in "$@"; do
        while ! "$VAGRANT" ssh -c 'kubectl get po --namespace=kube-system 2>/dev/null' 2>/dev/null | grep "$i" | grep 'Running' &>/dev/null; do
            sleep 5
        done
    done
}

if "$VAGRANT" snapshot list | grep KubeSetup &>/dev/null; then
    "$VAGRANT" snapshot go KubeSetup -r
else
    echo "PAN: Setting up bare Kubernetes VM. This could take a while..."
    "$VAGRANT" destroy -f
    "$VAGRANT" up
    "$ROOT_DIR/pangaea/bin/kubectl_setup"

    # WAIT FOR IMAGE DOWNLOADS

    echo "PAN: Provisioned machine, waiting for Kubernetes setup..."
    KUBE_CORE_IMGS=(kube-apiserver kube-controller-manager kube-proxy kube-scheduler kube-dns)
    assure_downloaded "${KUBE_CORE_IMGS[@]}"
    echo "PAN: We have Kubernetes core"

    if [ $KUBE_LOGGING = true ]; then
        IMGS=(elasticsearch-logging fluentd-elasticsearch kibana-logging)
        assure_downloaded "${IMGS[@]}"
        echo "PAN: KUBE_LOGGING loaded"
    fi

    if [ $KUBE_MONITORING = true ]; then
        IMGS=(monitoring-heapster monitoring-influxdb-grafana)
        assure_downloaded "${IMGS[@]}"
        echo "PAN: KUBE_MONITORING loaded"
    fi

    if [ $KUBE_GCE_CREDENTIALS = true ]; then
        # For state Running we need to provide credentials
        # It is discouraged for the snapshot to include credentials
        # Further, to pull images subsequently we need the internet anyway
        :
    fi

    echo "PAN: Creating a snapshot"
    "$VAGRANT" snapshot take KubeSetup
fi

echo "PAN: kubesetup complete"
