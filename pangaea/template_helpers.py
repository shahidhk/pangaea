# template rendering helpers

import yaml
from base64 import b64encode

from pangaea import utils, props

def kube_secret(name, secrets):
    ob = \
    {
        "kind": "Secret",
        "apiVersion": "v1",
        "metadata": {
            "name": name
        },
        "data": {k: b64encode(v.encode('ascii')).decode('ascii') for k, v in secrets.items()}
    }
    return yaml.dump(ob)

def read_file(f):
    with open(utils.pangaea_path(f)) as f:
        return f.read()

def kube_apiserver_ip():
    if props.get()['provider'] == 'gce' and props.get()['environment'] == 'development':
        # TODO: system exec gcloud # get ip address
        pass

helpers = {}
for f in [utils.pangaea_path, kube_secret, read_file]:
    helpers[f.__name__] = f
    helpers['gce_apiserver_ip'] = kube_apiserver_ip()
