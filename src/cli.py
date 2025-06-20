#!/usr/bin/env python3

from misc.i18n import setup_translation
from misc.util import clean_screen
from misc.ui import Display
from misc.configuration import Configuration

def form():
    print(f"OK ?")

def main():
    clean_screen()

    Configuration.load("/etc/TUX/tux_motd.yaml")

    setup_translation(Configuration.get("language","en"))

    form()  

    print("\n\n")

if __name__ == "__main__":
    main()