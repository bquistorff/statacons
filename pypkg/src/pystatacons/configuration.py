import os

from SCons.Script import AddOption

AddOption(
    '--show-config',
    dest='show_config',
    action='store_true',
    default=False,
    help='Show pystatacons configuration.',
)


# use to test for optional keys
def query_config(env, header, key, default=None):
    if 'CONFIG' in env and header in env['CONFIG'] and key in env['CONFIG'][header]:
        return env['CONFIG'][header][key]
    return default


def configuration(config_files=['config_project.ini', 'config_local.ini'], config=None, strip_quote_keys=[],
                  copy_local=True):
    import shutil
    import configparser
    # Copies templates if no such file exists
    if copy_local and len(config_files) > 1 and config_files[0] == 'config_local.ini' and \
       not os.path.isfile('config_local.ini') and os.path.isfile('utils/config_local_template.ini'):
        shutil.copy('utils/config_local_template.ini', 'config_local.ini')

    if config is None:
        config = configparser.ConfigParser()

    # Loads config ini files (local ones can over-ride project ones)
    config_files = [f for f in config_files if os.path.isfile(f)]
    config.read(config_files)

    # Remove quotes form paths if people are confused
    def strip_quotes_config(k1, k2, conf):
        if k1 in conf and k2 in conf[k1]:
            conf[k1][k2] = conf[k1][k2].strip('"').strip("'")

    for k1, k2 in strip_quote_keys:
        strip_quotes_config(k1, k2, config)

    return config


def print_config(config):
    for section in config.sections():
        print("[" + section + "]")
        for key in config[section]:
            print(key + ": " + config[section][key])


AddOption(
    '--config-files',
    dest='config_files',
    action='store',
    type="string",
    help='Specify config file paths.',
)
