
from colorama import Fore, Back

from misc.util import get_size, strip_ansi
from misc.configuration import Configuration
from misc.theme import theme, Foreground

class Display:

    def __init__(self):
        pass

    @classmethod
    def error(cls, text):
        print(f"{Back.RED}{Fore.WHITE}ERROR{Back.RESET} {Fore.RED}{text}{Fore.RESET}")

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
    def label(cls, icon, label, value, indent=0):
        """ 
            Affiche un libellé 
            Args:
                icon (str): L"îcone à afficher.
                label (str): Le libellé.
                value (str | tuple | list): La valeur ou les valeurs à afficher.
                indent (int): Le nombre d"espace à gauche.
            Returns:
                str: Le libellé.
        """

        if isinstance(value, (tuple, list)):
            value = ", ".join(str(v) for v in value if v)    

        print(
            f"{" " * indent}"
            f"{theme.Bright}{theme.Highlight}{icon}  {label:16}{theme.Reset}"
            f"{value}"
        )

    @classmethod
    def barlabel(cls, icon, label, used, total, width=50):
        """ Réalise le rendu des labels d"un bargraph """

        percent = int((used / total) * 100)

        value = f"{get_size(used)} " \
                f"{_("used")} {theme.Dim}({percent}%){theme.Reset} / {get_size(total)} " \
                f"{_("total")}" 

        if label == "":
            print(f"   {icon}  {value}")
        else:
            print(f"   {icon}  {label:<{width - len(strip_ansi(value))}}{value}")

    @classmethod
    def bargraph(cls, icon, used, total, warning, critical, width=50):
        """ Réalise le rendu d"un bargraph """

        progression  = min(int(used * 100 / total),100)
        used_width   = max(1, int(width * progression / 100))
        unused_width = width - used_width

        if progression >= critical:
            color = theme.Critical
        elif progression >= warning:
            color = theme.Warning
        else:
            color = theme.Ok

        symbol = Configuration.get("graph.symbol","─")

        print(
            f"   {icon}  "
            f"{color}{symbol * used_width}"
            f"{Foreground.get(Configuration.get("graph.track_color"), theme.LightBlack)}"
            f"{theme.Dim}{symbol * unused_width}{theme.Reset}"
        )

    @classmethod
    def box(cls, message, width=50, color=theme.Highlight):
        lines = message.split('\n')
        print(f"\n{color}┌" + "─" * (width + 2) + f"┐{theme.Reset}")
        for line in lines:
            print(f"{color}│ " + line.ljust(width) + f" │{theme.Reset}")
        print(f"{color}└" + "─" * (width + 2) + f"┘{theme.Reset}")
    