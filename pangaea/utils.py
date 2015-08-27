import os

def pangaea_path(p):
    """ Get path in pangaea directory """
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '../', p))
