
import os

def strip_ansi(text):
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