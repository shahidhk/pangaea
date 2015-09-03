import os
import yaml, json

from pangaea.utils import pangaea_path

class D: pass
__PROPS = D()
__PROPS.props = None
__PROPS.path = None

def get(path=None):
    path = pangaea_path(path or os.path.join('config', os.getenv('PANGAEA_CONFIG', 'development.yaml')))

    global __PROPS
    if __PROPS.props is None or __PROPS.path != path:
        _, ext = os.path.splitext(path)
        with open(path) as f:
            if ext == '.json':
                __PROPS.props = json.load(f)
            elif ext == '.yaml' or ext == '.yml':
                __PROPS.props = yaml.load(f)
        __PROPS.path = path
    return __PROPS.props
