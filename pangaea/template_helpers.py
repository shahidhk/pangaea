# template rendering helpers

import yaml
from base64 import b64encode

from pangaea.utils import pangaea_path

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
    with open(pangaea_path(f)) as f:
        return f.read()

helpers = {}
for f in [pangaea_path, kube_secret, read_file]:
    helpers[f.__name__] = f
