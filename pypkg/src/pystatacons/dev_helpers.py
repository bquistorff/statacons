"""Development-only helpers for statacons.

These functions are no-ops in production. They activate only when
STATACONS_DEV_SRC is set in the environment, which is the convention
for working against an editable install of pystatacons paired with a
not-yet-released .ado source tree.

Production users do not set STATACONS_DEV_SRC; everything here returns
the empty string or a no-op for them.
"""
import os


def dev_adopath_prefix():
    """Return an `adopath ++` line for the dev .ado tree, or empty string.

    When STATACONS_DEV_SRC is set, signature recipes need to find the
    dev complete_datasignature.ado instead of whatever is installed in
    the user's plus dir. Callers prepend this string to recipe.do
    contents so the dev .ado wins precedence on Stata's adopath.

    In production (env var unset) this returns "" and recipes are
    unchanged.
    """
    dev_src = os.environ.get('STATACONS_DEV_SRC')
    if not dev_src:
        return ''
    return 'adopath ++ "' + dev_src.replace('\\', '/') + '"\n'
