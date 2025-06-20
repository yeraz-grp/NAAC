import gettext
import os

_translation = None
_current_locale = "en"

def setup_translation(lang_code="en"):
    global _translation, _current_locale
    localedir = os.path.join(os.path.dirname(__file__), '../i18n')
    _translation = gettext.translation("messages", localedir=localedir, languages=[lang_code], fallback=True)
    _translation.install()
    _current_locale = lang_code

def _(message):
    if _translation:
        return _translation.gettext(message)
    return message

def _n(singular, plural, n, **kwargs):
    if _translation:
        text = _translation.ngettext(singular, plural, n)
    else:
        text = singular if n == 1 else plural
    return text.format(n=n, **kwargs)

def col(text, size=None, reftext=None):
    translated = _(text)

    if size is None and reftext is None:
        return translated
    
    if size is None and reftext is not None:
        return translated.ljust(len(_(reftext)) + 2)

    if size is not None and reftext is None:
        ref_len = max(size, len(translated) + 2) 
        return translated.ljust(ref_len)
    
    ref_len = max(size, len(_(reftext)) + 2) 
    return translated.ljust(ref_len)
