# Spec #

Uniform interface
Idempotent operations
Local configuration must not be checked in, must not conflict
Secrets management
Templated everything, parameters and include other templates

# Folder structure #

/
/pan +x
/.pangaea # pangaea-folder-contents-but-compiled
/pangaea # python module
  /providers
    /vagrant/Vagrantfile
    /gce/bootstrap.sh
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

x Download archive then extract binaries
x dns server
- gce support -test
- compilation target parameter
- complete env tooling
- template coreos cloud config: ip addr, dns for kubelet
- persistent storage for logging and monitoring
- helpers for path in templates, such as for mounting
- fswatch for compilation
- secure cluster, everyone talks with a key or token, kube and etcd
- automatically mount caches for stuff like docker, archive file
- Dockerfile builds. understand current workflow

# Pangaea command line tool

$PANGAEA_ENVIRONMENT = 'development:override'
  # ':' separated list of config files

pangaea
  cluster
    status start stop reboot
    node
      add remove reboot
  env
    # produce eval-able output
    all
      # $PAN to pangaea_path so we can do things like create -f $PAN/app/something
    kubectl docker gcloud vagrant nfs ssh fleetctl
