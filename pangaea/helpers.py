# template rendering helpers

import yaml
from base64 import b64encode
import subprocess, json

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

def kube_running():
    kctl = utils.pangaea_path('pangaea/files/stubs/kubectl.py')

    try:
        nodes = subprocess.check_output('{} get no -o json 2>/dev/null'.format(kctl), shell=True)
        nodes = json.loads(nodes.decode('utf-8'))
        if len(nodes['items']) > 0:
            return True
    except ValueError: # json parse error
        pass
    except subprocess.CalledProcessError: # kubectl error code, not ready or not found
        pass

    return False

class KubeIPNotFound(Exception):
    pass
def kube_apiserver_ip():
    if props.get()['provider'] == 'vagrant':
        return '127.0.0.1:8080'
    elif props.get()['provider'] == 'gce':
        instances = subprocess.check_output('gcloud compute instances list --format json', shell=True)
        instances = json.loads(instances.decode('utf-8'))

        for i in instances:
            if i['name'] == props.get()['gce']['instance_name']:
                return i['networkInterfaces'][0]['accessConfigs'][0]['natIP'] + ':8080'

        raise KubeIPNotFound('GCE instance {} not found'.format(props.get()['gce']['instance_name']))

helpers = {}
for f in [utils.pangaea_path, kube_secret, read_file]:
    helpers[f.__name__] = f
    helpers['kube_apiserver_ip'] = kube_apiserver_ip
