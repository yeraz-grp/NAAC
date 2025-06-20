import yaml
from pathlib import Path

_dummy = object() 

class Configuration:
    _data = {}
    _loaded = False

    def __init__(self):
        pass

    @classmethod
    def load(cls, file_path):
        """ Charge la configuration depuis un fichier YAML """

        if Path(file_path).is_file():
            with open(file_path, "r", encoding="utf-8") as f:
                cls._data = yaml.safe_load(f) or {}
                cls._loaded = True
        else:
            raise FileNotFoundError(f"Configuration file not found: {file_path}")

    @classmethod
    def get(cls, key, default=None):
        keys = key.split('.')
        data = cls._data
        for k in keys:
            if isinstance(data, dict) and k in data:
                data = data[k]
            else:
                return default
        return data
    
    @classmethod
    def is_loaded(cls):
        return cls._loaded