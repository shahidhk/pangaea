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
x compilation target parameter
x replace env with template + env var strings
x gce support -test
x template coreos cloud config: ip addr, dns for kubelet
x refactor compile
x change compile to be separate unit that compiles to any path
    including relative and absolute paths
    compile output filename is templatable
    filename mask
x add docker gcr creds as kube pod with secrets
x make-ca-cert use _use_gce_ value instead of curl
x mount app folder
- kubesystem bootstrap secrets
- add hook to run kubectl yaml on cluster boot
- add --project flag to all gcloud compute commands
- mount cloud init file for debugging
- expose specific port on service
- gce mount disk
- secure access to apiserver
- complete env tooling
- vagrant mount permissions
- persistent storage for logging and monitoring
- helpers for path in templates, such as for mounting
- package as pip
- documentation
    docs
    basic tooling

later
- fix the utter mess with paths
- fswatch for compilation
- secure cluster, everyone talks with a key or token, kube and etcd
- automatically mount caches for stuff like docker, archive file
- Dockerfile builds. understand current workflow

redefine.

template compiler
  parameter based config
  template helpers
scripts
  print env variables
    templated
      info: current config files, status
      all
        if env is dev then vagrant else gce
      vagrant
    wrapper script calls template() then calls rendered script
components
  setup
    coreos
      self.yaml
    kubernetes
      monitoring
      logging
      dns
      template and call kubectl
    vagrant
      vagrantfile
      vagrant.rb
    gce
      up
      down
  env
    vagrant
    fleetctl
    kubectl
    gcloud
    nfs
    docker
    ssh
  #

# Templating

output to the same directory
  always run pan compile
    idempotent
  option: prefix ".pan"
  so include ".pan" paths insteadj


# Pangaea command line tool

$PANGAEA_ENVIRONMENT = 'development.yaml'

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
