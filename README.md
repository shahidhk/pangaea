# Pangaea

Point and shoot Kubernetes.

Brings up a running Kubernetes node on CoreOS using either the Vagrant or GCE providers and provides a consistent interface.

A usable workflow enabled by
- Provider and environment aware template compiler
- Default set up of logging and monitoring
- Tool to set up the shell environment to use existing tools like gcloud, kubectl, and vagrant

## Documentation

- `.pangaea` file contains configuration and template variables
- access template variables in any `.jinja` file in the config hash

### ./pan tool

- -h help
- compile
	- Compiles all `.jinja` files list in `configuration.targets`. Output file prefixed with `pan.`
- env
	- Sets up the environment to use tools like `kubectl` and `vagrant`
	- Run as `./pan env | source /dev/stdin` to modify the environment

## TODO

- use scripts from https://github.com/coreos/coreos-kubernetes instead
- See the file `spec.md`
- Better documentation, and setting up the environment for more tools is a priority

## Contributions ##

Put together by [akshaya01](https://github.com/akshaya01) at [Hasura](http://hasura.io)

Thanks to:
- [CoreoOS Vagrant](https://github.com/coreos/coreos-vagrant)
- [Kubernetes](https://github.com/kubernetes/kubernetes)

Although fully usable, this is a preview release under ongoing development.

Ideas and issues are welcome.
