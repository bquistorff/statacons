"""This module provides functions to write SConstruct files to process Stata
projects.

Additional SCons Options
------------------------
--assume-done: list of file patterns
    Skip execution, but mark all targets as up-to-date, for each script file in file pattern list

--assume-built: list of file patterns
    If all targets for a task are specified, skip the task execution, but mark all targets as up-to-date.

--show-config: <existence>
    List configuration read from files.

--config-files: string
    Override the user-config files to read for configuration.


Attributes
----------
decider_str_lookup : dict
    Dictionary mapping string to objects that SCons' Decider function can handle.
    Can be used to easily specify our new Decider function 'content-timestamp-newer' which only runs a task
    if a depenency is different than last time SCons ran and a dependency is newer than all the targets
    (this means that if you run scripts outside of SCons, we won't rebuild them):
    Decider(pystatacons.decider_str_lookup['content-timestamp-newer'])

special_sig_fns : dict
    Dictionary used by patch functions to have extension-specific signature functions.
    Can be updated with entries file-extension: function. The function should take
    a filename and return a string signature.

"""

__version__ = "3.0.2"
__all__ = ['init_env', 'decider_str_lookup', 'special_sig_fns', 'stata_run_params_factory']
from .deciders import decider_str_lookup, dependency_newer_then_content_changed, \
    changed_timestamp_then_dependency_newer_then_content_content
from .special_sigs import special_sig_fns
from .stata_utils import init_env, stata_run_params_factory
