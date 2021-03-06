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

- test bug where external loadbalancer open connection prevents kube-proxy setup

logging and monitoring
- on google services, allow external access
- persistent storage
- logrotate

later
- secure cluster, kube and etcd

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

