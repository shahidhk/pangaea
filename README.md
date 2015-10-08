# Pangaea

Point and shoot Kubernetes.

Configure settings in `.pangaea` in your project root.

## Vagrant
```bash
cd providers/vagrant
vagrant up        # bring up Kubernetes node
vagrant suspend   # pause Kubernetes node
```

## GCE
```bash
providers/gce/up.sh     # bring up Kubernetes node
providers/gce/down.sh   # bring down node
```
## Requirements
- vagrant, virtualbox  
    vagrant plugin install vagrant-vbox-snapshot
- gcloud
- jq
- kubectl

## TODO

- See the file `spec.md`
- Better documentation, and setting shims for tools is a priority

## Contributions ##

Put together by [akshaya01](https://github.com/akshaya01) at [Hasura](http://hasura.io)

Thanks to:
- [CoreoOS Vagrant](https://github.com/coreos/coreos-vagrant)
- [CoreoOS Kubernetes](https://github.com/coreos/coreos-kubernetes)
- [Kubernetes](https://github.com/kubernetes/kubernetes)

Although fully usable, this is a preview release under ongoing development.

Ideas and issues are welcome.
