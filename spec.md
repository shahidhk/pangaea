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
    gcloud, kubectl, vagrant, nfsd
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
