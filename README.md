# Pangaea

Point and shoot Kubernetes. For Vagrant and GCE.

- Installation
- Usage
    - Config
    - Vagrant
    - GCE
    - Other Scripts
        - kubectl_setup
        - Google Cloud Registry credentials
- Future Work and Limitations
- Contributions

This document is meant to be used as a reference. For step by step instructions, see the [Workflow Guide](pangaea/docs/workflow.md)

## Installation

- Clone this repository to your project root
- Dependencies
    - For Vagrant: vagrant, virtualbox, nfs server  
        then install these vagrant plugins  
        `vagrant plugin install vagrant-vbox-snapshot`  
        `vagrant plugin install vagrant-triggers`
    - For GCE: gcloud, jq
    - Recommended: kubectl binary [[linux](https://storage.googleapis.com/kubernetes-release/release/v1.0.6/bin/linux/amd64/kubectl)] [[mac](https://storage.googleapis.com/kubernetes-release/release/v1.0.6/bin/darwin/amd64/kubectl)]

## Usage

All commands assuming that the current directory is the project root  
You may want to add `pangaea/bin` to your `PATH`

### Config

All configuration is set in `.pangaea` in the project root

`KUBE_LOGGING` enables the logging addon using fluentd, elasticsearch, and kibana  
`KUBE_MONITORING` enables the monitoring addon using kubelet's cadvisor, influxdb, and grafana  
`KUBE_GCR_CREDENTIALS` sets up credentials so that the Kubernetes node can pull images from a private Docker Google Cloud Registry

### Vagrant

Set `PROVIDER=vagrant` in `.pangaea`

The `Vagrantfile` is at `pangaea/vagrant/Vagrantfile`  
Either set `VAGRANT_CWD` to this path and use Vagrant normally, or use the wrapper script `pangaea/bin/vagrant` that figures it out depending on the current working directory

```bash
pangaea/vagrant/kubesetup.sh  # Give me a bare Kubernetes node
# runs vagrant up, and provisions the Kubernetes node
# waits for Kubernetes set up
# snapshots the VM so that subsequent runs will not redownload the internet

# Subsequently, use Vagrant like normal

pangaea/bin/vagrant up    # Bring up node
kubectl get po            # Verify working Kubernetes
pangaea/bin/vagrant halt  # Bring down node
```

### GCE

In `.pangaea`  
Set `PROVIDER=gce`  
Set `GCE_INSTANCE_NAME` to the name of the compute resource you want to create

```bash
# First, set up the GCE project and zone
gcloud auth login
gcloud config set project sample-project
gcloud config set compute/zone asia-east1-a

pangaea/gce/up.sh    # Creates a GCE based Kubernetes node
# Provisions the Kubernetes node
# Opens the firewall to the secure endpoint of the Kubernetes API server
# Sets up local kubectl to work with the Kubernetes node

kubectl get po       # Working Kubernetes

pangaea/gce/down.sh  # Destroys the compute instance, and deletes the firewall entry
```

Share the folder named after your instance under `pangaea/pki/keys` with your team and have them run `pangaea/bin/kubectl_setup` to config their workstation kubectl to work with the GCE instance.

### Other Scripts

#### Set up the local kubectl config

```bash
pangaea/bin/kubectl_setup  # Sets up local kubectl config to work with the Kubernetes node
# Depends on the value of PROVIDER in .pangaea
# If PROVIDER=gce, GCE_INSTANCE_NAME must be set correctly in .pangaea and the corresponding certs must be present in pangaea/pki/keys
```

#### Enable your Kubernetes node to download images from a private Google Cloud Registry

GCE based set ups can download images from a private registry in the same project.

This is for Vagrant based set ups, or cross project GCE downloads.

- Install [kubetemplate](https://github.com/hasura/kubetemplate)  
    `pip3 install kubetemplate`
- Follow the "How To > Get the Credentials" section at [Google JWT Token](https://github.com/hasura/google-jwt-gcr-token-docker)
- Put files in a directory as in the [example](https://github.com/hasura/kubetemplate/tree/master/example). Edit the `.kubetemplate` file to include the filename of the JSON you downloaded.
- In that directory, run `kubet` to generate the compiled `secret.yaml`
- `kubectl create -f secret.yaml`

## Future Work and Limitations

- Specify Kubernetes load balancer IP address (to be fixed on Kubernetes v1.1.0)
- Specify gcePersistentDisk for pod mounts (to be fixed on Kubernetes v1.1.0)
- Persistent storage for logging and monitoring addons
- Logrotate and storage management for addons
- CoreOS logrotate and storage management for logs
- Multi-node Kubernetes cluster, with ability to add and remove compute/storage
- Some more notes in spec.md

## Contributions ##

Put together by [akshaya01](https://github.com/akshaya01) at [Hasura](http://hasura.io)

Thanks to:
- [CoreoOS Vagrant](https://github.com/coreos/coreos-vagrant)
- [CoreoOS Kubernetes](https://github.com/coreos/coreos-kubernetes)
- [Kubernetes](https://github.com/kubernetes/kubernetes)

Ideas and issues are welcome.
