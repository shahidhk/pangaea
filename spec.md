# Spec #

Uniform interface
Idempotent operations
Local configuration must not be checked in, must not conflict
Secrets management
Templated everything, parameters and include other templates

# Tasks #

## kubernetes node, infrastructure, environment ##

parameters:
config file(s), merged in sequence

hcloud
  start
  stop
  restart = start + stop

impl:
  compile templates, run the right tool

describe [tool] [-q pipe-able configuration]
  tool is vagrant, gcloud, ssh, nfs, docker, kubectl
  set up environment automatically for tool

impl:
  output configuration file info, or environment variables, and instructions

future:
  list start and stop nodes

## run kubernetes config files ##

parameters:
  arbitrary
helpers:
  uniform mounted path, to contain all application structure

hctl
  start stop restart update(rolling) [service name, find corresponding folder in kube_configs]

impl:
  compile templates and pass to kubectl

future:
  fswatch

# Folder structure #

/
/.pangaea # pangaea-folder-contents-but-compiled
/pangaea # python module
  /pangaea +x
  /providers
    /vagrant/Vagrantfile
    /gce/bootstrap.sh
  /setup
  /compile
  /props
  /examples
    /app.example
  /files
    /coreos
      /self.yaml
    /kubernetes
      /monitoring
    /logging
/config
  /vagrant_config.rb # refactor most into Vagrantfile
  /sample.config
  /development.config
  /production.config
/app
  /secrets
    account.key
  /service1
    /

# Config file #

- provider
- parameters

# TODO #

- Download archive then extract binaries
- automatically mount caches for stuff like docker, archive file
- persistent storage for logging and monitoring
- dns server would be AWESOME
- secure cluster, everyone talks with a key or token, kube and etcd
- Dockerfile builds. understand current workflow
