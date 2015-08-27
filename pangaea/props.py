import os
import yaml, json
from utils import pangaea_path

class D: pass
__PROPS = D()
__PROPS.props = None
__PROPS.path = None

def get(path='config/sample.json'):
    global __PROPS
    if __PROPS.props is None:
        fp = pangaea_path(path)
        _, ext = os.path.splitext(fp)
        with open(fp) as f:
            if ext == '.json':
                __PROPS.props = json.load(f)
            elif ext == '.yaml' or ext == '.yml':
                __PROPS.props = yaml.load(f)
        __PROPS.path = path
    return __PROPS.props
