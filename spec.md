# Spec

- Provision node
    multinode setup
    providers: gce, vagrant
    configure nfs mounts
- Compiler
    jinja based templating
    template helpers
- Boot Kubernetes on node
    generate certificates
    download and setup binaries
      systemd and manifest files
- Boot kube system services
    dns
    logging
    monitoring
    docker auth
- Add application level concerns
    secrets

# Tasks

- specify loadBalancerIP (on release v1.1.0)
- test bug where external loadbalancer open connection prevents kube-proxy setup

- package as pip
- gce mount disk
- documentation

logging and monitoring
- on google services, allow external access
- persistent storage
- logrotate

- expose service ports as nodeports, enable and disable

- vagrant mount permissions
- complete env tooling

- requirements installer
    gcloud, kubectl, vagrant, nfsd, jq
- compile outputs list of files
- broken pipe on env, env.py:24 stdout write vs print
- test on
    create
    machine reboot

later
- mount cloud init file for debugging
- fswatch for compilation
- secure cluster, kube and etcd
- automatically mount caches for stuff like docker, archive file
- Dockerfile builds, understand current workflow

# Pangaea command line tool

pangaea
  init
    creates files directory, binstubs
  compile
    -infile, -outfile
  cluster [todo maybe]
    status start stop reboot
    node {profile|name}
      add remove reboot
      configuration profile based, node of certain type
  env
    # use shims instead
    # produce eval-able output
    all
    [components]
      vagrant
      fleetctl
      kubectl
      gcloud
      nfs
      docker
      ssh

# Workflow

- operation
    bootstrap, add node, remove node
    clustering handled differently on each
- provision node
    compile templates
    provisioner script

# Workflow

- provision node
    vagrant provision / gcloud create instance
- etcd nodes
    get list of all compute ip (offline)
    contact first successful that allows fleetctl
    find etcd servers
    verify cluster name
    optional: etcdctl to modify etcd cluster
    get etcd nodes for templating
- template systemd units (kubelet, etcd)
    based on roles, specify offline
    node environment
      systemd environmentfile
- template other files
    pod manifests, kubeconfig files
    roles, offline
    node environment
      bash based compiler

# Configuring gcloud
gcloud auth login
gcloud config set project tfc-glassic
gcloud config set compute/zone asia-east1-a

# Next tasks
x curl multiple document kubernetes object
x vagrant cache kubernetes binaries
x race condition in wait for setup.tar where only part of file is present
x test coreos reboots
x kubectl with vagrant
x vagrant cache docker
test nfs permissions issues
mount gce disks
services kubectl can fail in race, on logging with fluentd
