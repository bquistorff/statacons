import subprocess
import re
import os
from pkg_resources import packaging
import sys
from pathlib import Path  # scons' Glob is not recursive
import platform
from typing import Union

import SCons
from SCons.Defaults import DefaultEnvironment
import SCons.Debug
import SCons.Script
from SCons.Script import AddOption, GetOption, SetOption
from SCons.Builder import Builder
import SCons.Node.FS
from SCons.Environment import Environment

from .configuration import configuration, query_config, print_config
from .special_sigs import monkey_patch_scons, special_sig_fns

has_pywin32 = False
if platform.system() == "Windows":
    import importlib
    has_pywin32 = importlib.util.find_spec("win32api") is not None  # type: ignore


in_stata = 'sfi' in sys.modules
if in_stata:
    import sfi
pre_sys_stdout = sys.stdout  # Need this for SCons.Debug.Trace while run from Stata once building (e.g., stata_run)


def print_during_build(msg):
    if not GetOption('silent'):
        SCons.Debug.Trace(msg, pre_sys_stdout)
        if in_stata:
            sfi.SFIToolkit.pollnow()


##############################################
#           Stata tool (find it)             #
##############################################
def _find(pathname, paths=None):
    if paths is None:
        paths = os.environ['PATH'].split(os.pathsep)
    for dirname in paths:
        candidate = os.path.join(dirname, pathname)
        if os.path.isfile(candidate):
            return (pathname, candidate, dirname)
    return None


def find_highest_vs_dir_win(env_root_dir='ProgramFiles'):
    import glob
    dirs = glob.glob(os.path.join(os.environ[env_root_dir], "Stata*") + os.path.sep)
    pattern = ".*[aA]([0-9]+).$"
    vs = [int(re.match(pattern, dir)[1]) for dir in dirs if re.match(pattern, dir) is not None]
    if len(vs) > 0:
        return([os.path.join(os.environ['ProgramFiles'], "Stata" + str(max(vs)))])
    return []


def stata_tool(env):
    plat = platform.system()
    if not query_config(env, 'Programs', 'stata_exe', default=None) is None:
        env['STATABATCHEXE'] = env['CONFIG']['Programs']['stata_exe']
        if os.path.isabs(env['STATABATCHEXE']) and not os.path.isfile(env['STATABATCHEXE']):
            print("Config value stata_exe is an absolute path, but that file does not exist.")
            return
        if not os.path.isabs(env['STATABATCHEXE']) and _find(env['STATABATCHEXE']) is None:
            print("Can't config value stata_exe along path.")
            return

    else:
        def_execs = {'Windows': ['StataMP-64.exe', 'StataSE-64.exe', 'StataBE-64.exe', 'Stata-64.exe'],
                     'Linux': ['stata-mp', 'stata-se', 'stata'],
                     'Darwin': ['StataMP', 'StataSE', 'StataBE', 'Stata']}
        candidate_stata_exes = def_execs[plat]
        if 'STATAEXE' in os.environ:
            candidate_stata_exes = [os.environ['STATAEXE']] + candidate_stata_exes
        found_ret = None
        for candidate_stata_exe in candidate_stata_exes:
            found_ret = _find(candidate_stata_exe)
            if found_ret is not None:
                env['STATABATCHEXE'] = found_ret[0]
                break
        if found_ret is None and plat == 'Windows':
            for candidate_stata_exe in candidate_stata_exes:
                found_ret = _find(candidate_stata_exe, (find_highest_vs_dir_win('ProgramFiles')
                                                        + find_highest_vs_dir_win('ProgramFiles(x86)')))
                if found_ret is not None:
                    env['STATABATCHEXE'] = found_ret[1]
                    break
        if found_ret is None and plat == 'Darwin':
            for candidate_stata_exe in candidate_stata_exes:
                found_ret = _find(candidate_stata_exe, ["/Applications/Stata/" + st_type + ".app/Contents/MacOS/"
                                                        for st_type in def_execs[plat]])
                if found_ret is not None:
                    env['STATABATCHEXE'] = found_ret[1]
                    break

        if found_ret is None:
            print("Can't find Stata from config or defaults")
            return

    batch_flags = {'Windows': '/e',
                   'Linux': '-b',
                   'Darwin': '-e'}

    env['STATABATCHFLAG'] = batch_flags[plat]
    env['STATABATCHCOM'] = '"' + env['STATABATCHEXE'] + '"' if " " in env['STATABATCHEXE'] else env['STATABATCHEXE']
    env['STATABATCHCOM'] = env['STATABATCHCOM'] + " " + batch_flags[plat]


##############################################
#              Builders                      #
##############################################
# We impliment these skip-logic routines in stata_run() and not a dedicated Decider so that
# we can have them thought of as 'built' and info saved in the sconsign file. Also,
# someone can change them on the command-line without changing any files and is orthogonal
# to what decider they choose (MD5, MD5-timestamp)
AddOption(
    '--assume-built',
    dest='assume_built',
    action='store',
    type="string",
    help='Assume these targets are up-to-date (and if all targets for a task are up-to-date it will be skipped).',
)
AddOption(
    '--assume-done',
    dest='assume_done',
    action='store',
    type="string",
    help='Assume these do-files are up-to-date and do no rebuild.',
)
assume_built = GetOption('assume_built')  # If there are outer quotes on the cli, these are stripped.
assume_built_list = []
if assume_built is not None:
    # could've used os.pathsep, but want consistent across sytems
    assume_built_list = [str(path) for file_pattern in assume_built.split(':')
                         for path in Path().rglob(file_pattern) if not path.is_dir()]

assume_done = GetOption('assume_done')  # If there are outer quotes on the cli, these are stripped.
assume_done_list = []
if assume_done is not None:
    assume_done_list = [str(path) for file_pattern in assume_done.split(':')
                        for path in Path().rglob(file_pattern) if not path.is_dir()]


def try_hidden_desktop(cmd_line, cwd=None, disp_str=""):
    # TODO: Move this out as it doesn't require Stata (sub print_during_build)
    try:
        import win32con
        import pywintypes
        import win32service
        import win32process
        import win32event
    except ImportError:
        print_during_build("Need pywin32 package installed.\n")
        return None

    # Open Desktop. No need to close as destroyed when process ends
    desktop_name = "pystatacons"
    try:
        _ = win32service.OpenDesktop(desktop_name, 0, True, win32con.MAXIMUM_ALLOWED)
    except win32service.error:  # desktop doesn't exist
        try:
            sa = pywintypes.SECURITY_ATTRIBUTES()
            sa.bInheritHandle = 1
            _ = win32service.CreateDesktop(desktop_name, 0, win32con.MAXIMUM_ALLOWED, sa)  # return if already created
        except win32service.error:
            print_during_build("Couldn't create Desktop.\n")
            return None

    s = win32process.STARTUPINFO()
    s.lpDesktop = desktop_name
    s.dwFlags = win32con.STARTF_USESHOWWINDOW + win32con.STARTF_FORCEOFFFEEDBACK
    s.wShowWindow = win32con.SW_SHOWMINNOACTIVE
    proc_ret = win32process.CreateProcess(None, cmd_line, None, None, False, 0, None, cwd, s)
    # hProcess, _, dwProcessId, _
    if disp_str != "":
        print_during_build(disp_str + "." + "\n" + "  Starting in hidden desktop (pid=" + str(proc_ret[2]) + ")."
                           + "\n")
    win32event.WaitForSingleObject(proc_ret[0], win32event.INFINITE)
    ret_code = win32process.GetExitCodeProcess(proc_ret[0])
    return ret_code


# Handles log file (better than Clean() as we typically want them removed right away
# (there may be a lot and this is easier))
def stata_run(target, source, env, params="", file_cmd="do", full_cmd=None):
    if 'STATABATCHEXE' not in env:
        raise LookupError("Can't find Stata")
    if full_cmd is None:
        fname = str(source[0])  # Assumes the first element of source is the do file

    if assume_built is not None and all([str(t) in assume_built_list for t in target]):
        if full_cmd is None:
            full_cmd = file_cmd + ' "' + fname + '" ' + params
        # In case someone is using a time-stamp option for content being up-to-date. Touch() doesn't seem to work
        for t in target:
            Path(str(t)).touch()
        print_during_build("Assuming built: " + full_cmd + "\n")
        return 0
    if assume_done is not None and 'fname' in locals() and fname in assume_done_list:
        for t in target:
            Path(str(t)).touch()
        print_during_build("Assuming done: " + fname + "\n")
        return 0

    cwd = None

    # Can't use the Builder chdir option, since that moves the target dir (and we want source)
    stata_chdir = env['CONFIG']['SCons']['stata_chdir']
    if stata_chdir == '':
        stata_chdir = '0'

    if stata_chdir == '1' and full_cmd is None:
        cwd = os.path.dirname(fname)
        fname = os.path.basename(fname)
    elif stata_chdir != '0':
        cwd = stata_chdir
        fname = os.path.relpath(fname, stata_chdir)

    if full_cmd is None:
        full_cmd = file_cmd + ' "' + fname + '"'
        if params != "":
            full_cmd = full_cmd + ' ' + params

    # Get hash of command to avoid collisions
    import hashlib
    max_digest_len = 8
    cmd_digest = hashlib.md5(full_cmd.encode('utf-8')).hexdigest()[:max_digest_len]

    if 'fname' in locals():
        recipe_basename = os.path.splitext(os.path.basename(fname))[0]
        # TODO (potential): could track all basefnames (in StataBuild) and if there's duplicates then
        # attach digests to those
        if file_cmd != "do" or params != "":
            recipe_basename = recipe_basename + "-" + cmd_digest
    else:
        recipe_basename = "stata-" + cmd_digest

    log_basename = recipe_basename + ".log"
    if cwd is not None:
        log_name = os.path.join(cwd, log_basename)
    else:
        log_name = log_basename

    import tempfile
    with tempfile.TemporaryDirectory() as tmpdirname:
        # if GetOption("debug")!=[]: print_during_build("Executing in temporary directory: " + tmpdirname+"\n")
        recipe_fname = os.path.join(tmpdirname, recipe_basename + ".do")
        with open(recipe_fname, "w") as recipe:
            recipe.write(full_cmd + '\n')

        args_split = [env['STATABATCHEXE'], env['STATABATCHFLAG'], "do", recipe_fname]
        digest_str = "" if 'fname' in locals() and file_cmd == "do" and params == "" else ". log=" + log_basename

        no_hidden = query_config(env, 'Programs', 'win_stata_hidden', default='True') == 'False'
        ret_code = None
        disp_str = "Running: " + env['STATABATCHCOM'] + " " + full_cmd + digest_str
        if has_pywin32 and not no_hidden:
            # win32's CreateProcess just takes a string, so see if need to wrap terms in quotes
            if " " not in recipe_fname:
                cmd_line = env['STATABATCHCOM'] + " do " + recipe_fname
            else:
                cmd_line = env['STATABATCHCOM'] + ' do "' + recipe_fname + '"'
            ret_code = try_hidden_desktop(cmd_line, cwd, disp_str)
        if ret_code is None:
            print_during_build(disp_str + "\n")
            cproc = subprocess.run(args_split, cwd=cwd)
            ret_code = cproc.returncode

    if ret_code != 0:  # In case the Stata executable has a real issue
        return ret_code

    # check if script had an error
    retcode = 0
    with open(log_name, 'r') as f:
        lines = f.readlines()  # if logs are really big, iterate until end to not store whole thing
        # Thanks to Kyle https://gist.github.com/pschumm/b967dfc7f723507ac4be#gistcomment-2657900
        match = re.search(r'^r\(([0-9]+)\);$', lines[-1])  # pytask looks in any of last 10 lines
        if match is not None:
            retcode = int(match[1])
    if retcode != 0:
        os.replace(log_name, os.path.join(".", recipe_basename + ".log"))
        return retcode

    success_batch_log_dir = env['CONFIG']['SCons']['success_batch_log_dir']
    if success_batch_log_dir == "":
        os.remove(log_name)
    elif success_batch_log_dir != "." and success_batch_log_dir != "":
        os.replace(log_name, os.path.join(success_batch_log_dir, recipe_basename + ".log"))

    return 0


def copy_func(f):
    """Based on http://stackoverflow.com/a/6528148/190597 (Glenn Maynard)"""
    import types
    import functools
    g = types.FunctionType(f.__code__, f.__globals__, name=f.__name__,
                           argdefs=f.__defaults__,
                           closure=f.__closure__)
    g = functools.update_wrapper(g, f)
    g.__kwdefaults__ = f.__kwdefaults__
    return g


builder_counter = 1
task_dependencies = []


def stata_run_params_factory(self: Environment, target: Union[list, str], source: Union[list, str] = None,
                             do_file: str = None, params: str = "", file_cmd: str = "do", full_cmd: str = None,
                             depends: list = None) -> SCons.Node.NodeList:
    """Factory function to create Builder instances for Stata tasks.

    Typically called as env.StataBuild() and omitting the first (self) argument.
    Marks all targets as Precious() (more intuitive for Stata users, and facilitates --assume-done/built).

    Build time: Tasks that specify file_cmd, params, or full_cmd  will have their stata batch-mode log-file names
    so that it's the typical name with a short hash signature at the end (to ensure uniqueness).
    By default, successful tasks have their batch-mode log files deleted. An alternative is to put them in a directory
    Specified by the value of the 'success_batch_log_dir' key in the '[SCons]' header in a configuration file.
    By default, Stata's current directory when executing the script is the project root. This can be changed by
    specifying the value of the 'stata_chdir' key in the '[SCons]' header. If set to '1', then Stata will change to the
    directory of the script. If it is set as string,  then Stata will change to this directory.
    On Windows, running Stata in batch-mode will typically briefly steal the focus. If the pywin32 Python package is
    installed, we will execute Stata batch-mode tasks in a hidden desktop to prevent this. (Does not work 100% of the
    time in Stata for some unknown reason.) As these processes are hidden, process IDs are printed to allow someone to
    kill the process manually if desired using Task Manager's Details tab. To disable this hidden-desktop behavior,
    set the 'win_stata_hidden' key's value to False in the section [Programs].

    Parameters
    ----------
    self :
        Environment
    target :
        Targets of the task
    source :
        Sources of the task. If mulitple, then the first should be the Stata script file.
    do_file :
        Alternative way of specifying the do file.
    params :
        Parameters to the script execution
    file_cmd :
        Override 'do' command for the script.
    file_cmd :
        Alternative to (file_cmd, script file, params) for specifying the full command
    depends :
        Additional dependencies of the task. Equivalent to using Depends().
    """

    # partial approach doesn't work because the signature includes the address of original function
    env = self  # self is env

    # scons typically deletes targets when they will be re-made, but we want to allow assume_built
    env.Precious(target)

    if do_file is not None:
        source = [do_file]

    if (params == "") and (file_cmd == "do") and (full_cmd is None):  # don't need a custom builder
        build_obj = env.StataDo(target, source)
    else:
        custom_stata_run = copy_func(stata_run)
        custom_stata_run.__defaults__ = (params, file_cmd, full_cmd)
        global builder_counter
        cust_name = 'StataBuild' + str(builder_counter)
        builder_counter = builder_counter + 1
        cust_builder = Builder(action=custom_stata_run)
        env.Append(BUILDERS={cust_name: cust_builder})

        build_obj = env.__dict__[cust_name](target, source)  # don't think i need the env.XXX form

    if depends is not None:
        env.Depends(build_obj, depends)

    if type(source) is not list:
        source = [source]
    global task_dependencies
    deps = source
    if depends is not None:
        if type(depends) is not list:
            depends = [depends]
        deps = deps + depends
    task_dependencies.append((target, deps))

    return build_obj


##############################################
#              Patching                      #
##############################################
# how to get a Stata-style datasignature
int_env = None


def get_datasign(fname):
    if 'STATABATCHEXE' not in int_env:
        raise LookupError("Can't find Stata")
    m_str = int_env['CONFIG']['SCons']['use_custom_datasignature']
    meta = m_str != "DataOnly" and m_str != "Datasignature"
    meta_arg_split = [] if meta else ["nometa"]
    vv_only = m_str == "LabelsFormatsOnly"
    vv_only_arg_split = ["labels_formats_only"] if vv_only else []
    slow = ((query_config(int_env, 'Project', 'cache_dir') is not None)
            or (query_config(int_env, 'Project', 'dta_sig_mode') == 'slow'))
    fast_arg_split = [] if slow else ["fast"]
    fname_abs = os.path.abspath(fname)

    # Run in temp-dir as in parallel mode we don't want to processes to try writing to the same stata.log
    import tempfile
    with tempfile.TemporaryDirectory() as tmpdirname:
        sig_fname = "sig.txt"
        args_split = ([int_env['STATABATCHEXE'], int_env['STATABATCHFLAG'], 'complete_datasignature,',
                      'dta_file("' + fname_abs + '")', 'fname("' + sig_fname + '")'] + meta_arg_split
                      + fast_arg_split + vv_only_arg_split)

        no_hidden = query_config(int_env, 'Programs', 'win_stata_hidden', default='True') == 'False'
        ret_code = None
        if has_pywin32 and not no_hidden:
            meta_arg = "" if meta else " nometa"
            fast_arg = "" if slow else " fast"
            vv_only_arg = " labels_formats_only" if vv_only else ""
            cmd_line = (int_env['STATABATCHCOM'] + ' complete_datasignature, dta_file("' + fname_abs + '") fname("'
                        + sig_fname + '")' + meta_arg + fast_arg + vv_only_arg)
            ret_code = try_hidden_desktop(cmd_line, tmpdirname)
        if ret_code is None:
            cproc = subprocess.run(args_split, cwd=tmpdirname)
            ret_code = cproc.returncode
        if ret_code != 0:  # In case the Stata executable has a real issue
            raise Exception("Couldn't get the file data-signature. Stata error")
        # Don't need to check log error, because lack of sig_fname will just raise exception
        with open(os.path.join(tmpdirname, sig_fname), "r") as f:
            sig = f.readline()

    if in_stata:
        sfi.SFIToolkit.pollnow()
    return sig


def init_env(env: Environment = None, tools: list = [], patch_scons_sig_fns: bool = True,
             skip_scons_vs_check: bool = False) -> Environment:
    """Sets up an environment for Stata.

    Reads configuration data and saves to env['CONFIG']. By default it will check for and read
    two ini files ('config_project.ini' then 'config_local.ini'), though
    can be overridden using the '--config-files=....' option.
    If the config_local.ini is the first one, does not exist and 'utils/config_local_template.ini' does,
    the latter is copied to the former location.

    Displays the config if the '--show-config' option was specified.
    Runs a Stata Tool to find Stata automatically.
    If this is not in a typical location then you can specify the full path as the value for a 'stata_exe' key under a
    '[Programs]' header in the configuration file.
    Attaches the 'StataBuild' Builder method to the environment.
    Optionally patches SCons to allow for file-extension-specific signature functions.

    Parameters
    ----------
    env :
        Environment to configure for Stata support. If not provided will instantiate a DefaultEnvironment with the
        `os.environ` and no tools (many Stata users don't have defaults ones that SCons would complain about not
        finding).
    tools :
        List of tools to initialize the returned environment with.
    patch_scons_sig_fns :
        Whether to patch the SCons file signature functions to support special signature functions by file extensions.
        Default support is provided for .dta files.
    skip_scons_vs_check:
        If false, will not output a warning when using a version of SCons that has not been tested.
    """
    import configparser

    if not skip_scons_vs_check and packaging.version.parse(SCons.__version__) < packaging.version.parse("4.2.0"):
        print("WARNING: You are running SCons version" + SCons.__version__
              + " and statacons has only been tested on 4.2.0+.")

    if env is None:
        env = DefaultEnvironment(ENV=os.environ, tools=tools)
    global int_env
    int_env = env

    config = configparser.ConfigParser()
    config['SCons'] = {'success_batch_log_dir': '', 'use_custom_datasignature': 'Strict', 'stata_chdir': ''}
    strip_quote_keys = [('Programs', 'stata_exe'), ('SCons', 'success_batch_log_dir'), ('Project', 'cache_dir')]
    if GetOption("config_files") is not None:
        config = configuration(config_files=GetOption("config_files").split(':'), config=config,
                               strip_quote_keys=strip_quote_keys)
    else:
        config = configuration(config=config, strip_quote_keys=strip_quote_keys)

    # Check values
    if config['SCons']['success_batch_log_dir'] != "" and not os.path.isdir(config['SCons']['success_batch_log_dir']):
        print("Warning: couldn't find directory 'success_batch_log_dir'")

    if not config['SCons']['stata_chdir'] in ['', '0', '1'] and not os.path.isdir(config['SCons']['stata_chdir']):
        print("Warning: Couldn't find 'stata_chdir' directory.")

    # Check if our clumsy over-ride causes a problem
    if config['SCons']['stata_chdir'] == '1' and os.path.isdir('1'):
        print("Warning: Interpreting the value of 1 for stata_chdir to mean"
              " 'set cwd to do_file's directory' rather than 'set cwd to 1/'")
    if config['SCons']['stata_chdir'] == '0' and os.path.isdir('0'):
        print("Warning: Interpreting the value of 0 for stata_chdir to mean"
              " 'set cwd to SConstruct's directory' rather than 'set cwd to 0/'")

    env['CONFIG'] = config

    env.Tool(stata_tool)

    stata_do_bld = Builder(action=stata_run)
    env.Append(BUILDERS={'StataDo': stata_do_bld})
    env.AddMethod(stata_run_params_factory, 'StataBuild')

    if GetOption("show_config"):
        SetOption("no_exec", True)
        SetOption("silent", True)
        print("Current config:")
        if 'Programs' not in config or 'stata_exe' not in config['Programs']:
            print("Stata batch found automatically: " + env['STATABATCHCOM'])
        print_config(config)
        print("\n")

    if not GetOption("clean") and patch_scons_sig_fns:
        m_str = config['SCons']['use_custom_datasignature']
        if m_str != "False":
            monkey_patch_scons()
            special_sig_fns[".dta"] = get_datasign

            if not GetOption('silent'):
                if m_str != "DataOnly" and m_str != "Datasignature" and m_str != "LabelsFormatsOnly":
                    print("Using 'Strict' custom_datasignature.")
                    print("Calculates timestamp-independent checksum of dataset, ")
                    print("  including all metadata.")
                    print("Edit use_custom_datasignature in config_project.ini to change.")
                    print("  (other options are DataOnly, LabelsFormatsOnly, False)")
                elif m_str == "LabelsFormatsOnly":
                    print("Using 'LabelsFormatsOnly' custom_datasignature.")
                    print("Calculates timestamp-independent checksum of dataset, ")
                    print("  including variable formats, variable labels and value labels.")
                    print("Edit use_custom_datasignature in config_project.ini to change.")
                    print("  (other options are Strict, DataOnly, False)")
                else:
                    print("Using 'DataOnly' datasignature.")
                    print("Calculates timestamp-independent checksum of dataset,")
                    print("  not including metadata.")
                    print("Edit use_custom_datasignature in config_project.ini to change.")
                    print("  (other options are Strict, LabelsFormatsOnly, False)")
        elif not GetOption('silent'):
            print("Using default timestamp-dependent checksums of dataset,")
            print("Edit use_custom_datasignature in config_project.ini to change (Strict, DataOnly, LabelsFormatsOnly)")

    if in_stata:
        import sfi
        sfi.SFIToolkit.pollnow()

    return(env)
