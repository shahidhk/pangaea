# TODO #

- expose specific port on service
- gce mount disk
- vagrant mount permissions
- persistent storage for logging and monitoring
- merge config and pangaea/files
- package as pip
- documentation
    docs
    basic tooling
- complete env tooling

- requirements installer
    gcloud, kubectl, vagrant
- compile outputs list of files
- broken pipe on env, env.py:24 stdout write vs print
- restarting vagrant box must not re-download files

later
- mount cloud init file for debugging
- secure access to apiserver
- fswatch for compilation
- secure cluster, everyone talks with a key or token, kube and etcd
- automatically mount caches for stuff like docker, archive file
- Dockerfile builds. understand current workflow

# Pangaea command line tool

$PANGAEA_ENVIRONMENT = 'development.yaml'

pangaea
  cluster
    status start stop reboot [todo maybe]
    node [todo]
      add remove reboot
  env
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

