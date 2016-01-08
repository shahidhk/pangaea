# Pangaea

Point and shoot Kubernetes. For Vagrant and GCE.
- To treat a Kubernetes cluster and Kubernetes nodes as the fundamental units of infrastructure, abstracting out the underlying provider
- Enable excellent developer workflow

Contents
- Installation
- Usage
    - Vagrant
    - GCE
    - Other Scripts
        - kubectl_setup
        - Google Cloud Registry credentials
        - Logging and Monitoring
- Future Work and Limitations
- Contributions

This document is meant to be used as a reference. For step by step instructions and detailed documentation, see the [Workflow Guide](pangaea/docs/workflow.md)

## Installation

- Clone this repository to your project root
- Dependencies
    - For Vagrant: vagrant, virtualbox, nfs server  
        then install these vagrant plugins  
        `vagrant plugin install vagrant-vbox-snapshot`  
        `vagrant plugin install vagrant-triggers`
    - For GCE: gcloud, jq
    - Recommended: kubectl binary [[linux](https://storage.googleapis.com/kubernetes-release/release/v1.1.2/bin/linux/amd64/kubectl)] [[mac](https://storage.googleapis.com/kubernetes-release/release/v1.1.2/bin/darwin/amd64/kubectl)]

## Usage

All commands assuming that the current directory is the project root  
You may want to add `pangaea/bin` to your `PATH`

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
Set `GCE_MACHINE_TYPE` to the required type, default is `n1-standard-1`

```bash
# First, set up the GCE project, region and zone
gcloud auth login
gcloud config set project sample-project
gcloud config set compute/region asia-east1
gcloud config set compute/zone asia-east1-a

# Create a GCE boot disk with CoreOS image
gcloud compute disks create disk-name --image coreos

# Create an External IP address for the project
gcloud compute addresses create ext-ip-address-name
# Note down the name, to add it to .pangaea 

# Edit .pangaea to include these variables
vim .pangaea
# ...
GCE_BOOT_DISK=disk-name
GCE_EXT_IP_NAME=ext-ip-address-name
# ...

pangaea/gce/up.sh init # Creates a GCE based Kubernetes node with the boot disk, attach the static external IP to it.
# Provisions the Kubernetes node
# Opens the firewall to the secure endpoint of the Kubernetes API server
# Sets up local kubectl to work with the Kubernetes node

kubectl get po       # Working Kubernetes

pangaea/gce/down.sh  # Destroys the compute instance, and deletes the firewall entry, but IP is still reserved, disk is also persisted.

pangaea/gce/up.sh    # Creates a new VM and attach the same boot disk, same IP, so that state is preserved.

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
- `kubectl create -f secret.yaml --namespace=kube-system`
- Run the gcr-docker-credentials component
- `kubectl create -f pangaea/components/gcr-docker-credentials`

#### Logging and Monitoring

- Logging with elasticsearch and kibana
- `kubectl create -f pangaea/components/logging-es-kibana`
- Monitoring with influxdb and grafana
- `kubectl create -f pangaea/components/monitoring-influxdb-grafana`

## Future Work and Limitations

- Logrotate and storage management for addons
- Multi-node Kubernetes cluster, with ability to add and remove compute/storage
- Some more notes in spec.md

## Contributions ##

Put together by [nullxone](https://github.com/nullxone) at [Hasura](http://hasura.io)

Thanks to:
- [CoreOS Vagrant](https://github.com/coreos/coreos-vagrant)
- [CoreOS Kubernetes](https://github.com/coreos/coreos-kubernetes)
- [Kubernetes](https://github.com/kubernetes/kubernetes)

Ideas and issues are welcome.
