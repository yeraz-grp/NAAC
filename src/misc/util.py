
import os
import re
import ipaddress

def strip_ansi(text: str) -> str:
    """ 
        Supprime les caractères unicodes (couleur / style) 
        Args:
            text (str): La texte à modifier.
        Returns:
            str: Le texte modifié.
    """       

    import re
    return re.sub(r"\x1B\[[0-?]*[ -/]*[@-~]", "", text)

def is_root():
    """ 
        Vérifie si l"utilisateur courant est root
        Returns:
            bool: True si l"utilisateur est root, sinon False.
    """
    return os.geteuid() == 0

def clean_screen():
    print("\033[2J\033[H", end="")


def is_fqdn(hostname: str) -> bool:
    if not hostname or len(hostname) > 253:
        return False

    if hostname.startswith('.') or hostname.endswith('.'):
        return False

    if '.' not in hostname:
        return False

    labels = hostname.split('.')
    fqdn_regex = re.compile(r"^(?!-)[A-Za-z0-9-_]{1,63}(?<!-)$")
    for label in labels:
        if not fqdn_regex.match(label):
            return False
    return True

def is_ipv4(address: str) -> bool:
    try:
        ipaddress.IPv4Address(address)
        return True
    except ValueError:
        return False