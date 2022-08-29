import os
import SCons
from SCons.Script import AddOption, GetOption

# replacement of hash_file_signature. Checks if .dta and then special call, otherwise hands off to reguarl
# hash_file_signature()
special_sig_fns = {}


def hash_file_signature_new(fname, chunksize=65536, hash_format=None):
    """
    Generate the md5 signature of a file

    Args:
        fname: file to hash
        chunksize: chunk size to read
        hash_format: Specify to override default hash format

    Returns:
        String of Hex digits representing the signature
    """
    import SCons.Util

    # print_during_build('new hash: ' + fname + "\n")
    fname_ext = os.path.splitext(fname)[1]
    if fname_ext in special_sig_fns.keys():
        try:
            sig = special_sig_fns[fname_ext](fname)
            if GetOption("show_specialsig") and not GetOption('silent'):
                print('Computed ' + fname_ext[1:] + '-signature: ' + fname)
            return sig
        except Exception as e:
            print('Error when computing ' + fname_ext[1:] + '-signature: ' + fname)
            raise e

    return SCons.Util.hash_file_signature(fname, chunksize, hash_format)


# replacement of get_content_hash, just called hash_file_signature_new() instead of default
def get_content_hash_new(self) -> str:
    """
    Compute and return the hash for this file.
    """
    import SCons.Util
    import SCons.Node.FS
    if not self.rexists():
        return SCons.Util.hash_signature(SCons.Util.NOFILE)
    fname = self.rfile().get_abspath()
    try:
        cs = hash_file_signature_new(fname, chunksize=SCons.Node.FS.File.hash_chunksize)
    except EnvironmentError as e:
        if not e.filename:
            e.filename = fname
        raise
    return cs


# Remove condition where if file size < hash_chunksize it calls hash_signature(contents) instead of going down to
# hash_file_signature
def get_csig_new(self) -> str:
    """Generate a node's content signature."""
    import SCons.Util
    ninfo = self.get_ninfo()
    try:
        return ninfo.csig
    except AttributeError:
        pass

    csig = self.get_max_drift_csig()
    if csig is None:
        try:
            size = self.get_size()
            if size == -1:
                contents = SCons.Util.NOFILE
            # elif size < File.hash_chunksize:
            #     contents = self.get_contents()
            else:
                csig = get_content_hash_new(self)
        except IOError:
            # This can happen if there's actually a directory on-disk,
            # which can be the case if they've disabled disk checks,
            # or if an action with a File target actually happens to
            # create a same-named directory by mistake.
            csig = ''
        else:
            if not csig:
                csig = SCons.Util.hash_signature(contents)

    ninfo.csig = csig

    return csig


# Save the originals (just in case someone needs them)
get_content_hash_orig = SCons.Node.FS.File.get_content_hash
get_csig_orig = SCons.Node.FS.File.get_csig


def monkey_patch_scons(m_str=""):
    # Allow using Stata-style data-signatures instead of MD5 file hashes
    # Can't do this in SConstruct
    # Can't use Decider because I need my hash of the previous file and don't want to store it
    # Can't easily replace SCons.Util.hash_file_signature because it's imported druing SCons/Script/__init__.py
    # (https://medium.com/@chipiga86/python-monkey-patching-like-a-boss-87d7ddb8098e)
    # So have to override the calling class method instead
    SCons.Node.FS.File.get_content_hash = get_content_hash_new
    # Overwrite this one too that used a different hash method with small files
    SCons.Node.FS.File.get_csig = get_csig_new


AddOption(
    '--show-specialsig',
    dest='show_specialsig',
    action='store_true',
    default=False,
    help='Show special content signature calculations.',
)
