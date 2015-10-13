# Pangaea

Point and shoot Kubernetes. For Vagrant and GCE.

Configure settings in `.pangaea` in your project root.

For detailed instructions, see the [documentation](TODO)

## Example Usage

```bash
# Vagrant
export VAGRANT_CWD=$PWD/pangaea/vagrant
                       # see the documentation for other ways to configure the environment
vagrant up             # bring up Kubernetes node
kubectl get po         # works with VM node
vagrant down           # bring down node

# GCE
providers/gce/up.sh    # bring up Kubernetes node
kubectl get po         # works with GCE node
providers/gce/down.sh  # bring down node
```

## Contributions ##

Put together by [akshaya01](https://github.com/akshaya01) at [Hasura](http://hasura.io)

Thanks to:
- [CoreoOS Vagrant](https://github.com/coreos/coreos-vagrant)
- [CoreoOS Kubernetes](https://github.com/coreos/coreos-kubernetes)
- [Kubernetes](https://github.com/kubernetes/kubernetes)

Ideas and issues are welcome.
