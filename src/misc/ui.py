
from colorama import Fore, Back, Style

from misc.configuration import Configuration
from misc.i18n import _
from misc.theme import theme, Foreground

class Display:

    def __init__(self):
        pass

    @classmethod
    def box(cls, message: str, color = Back.RED, width: int = 100):
        lines = message.splitlines() or [""]
        content_width = width - 4

        print("\n " + color + " " * width + Style.RESET_ALL)
        for line in lines:
            line_to_print = (line)[:content_width]
            line_to_print = line_to_print.ljust(content_width)
            print(" " + color + "  " + Style.BRIGHT + Fore.WHITE + line_to_print + "  " + Style.RESET_ALL)
        print(" " + color + " " * width + Style.RESET_ALL + "\n")


    @classmethod
    def header(cls, title):
        """ 
            Affiche un entête 
            Args:
                title (str): Le titre.
            Returns:
                str: L"entête.    
        """

        print(f"\n{theme.Bright}{theme.Title}{title}{theme.Reset}")

    @classmethod
    def label(cls, label, value):
        """ 
            Affiche un libellé 
            Args:
                label (str): Le libellé.
                value (str): La valeur à afficher.
            Returns:
                str: Le libellé.
        """

        print(
            f" {Back.GREEN}{Fore.WHITE} {label} {Style.RESET_ALL} {_(value)}"
        )
