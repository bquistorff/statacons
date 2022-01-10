# Copyright 2022. This work is licensed under a CC BY 4.0 license. 
import sys

#Actually keep around previous one (e.g., https://stackoverflow.com/questions/12719328/sys-stdout-not-reassigning-to-sys-stdout/12719351)
pre_sys_stdout = sys.stdout
pre_sys_stderr = sys.stderr
def revert_io2():
    # This call is added to revert stderr and stdout to the original
    # ones just in case some build rule or something else in the system
    # has redirected them elsewhere.
    sys.stderr = pre_sys_stderr
    sys.stdout = pre_sys_stdout
    pass
		
#Only needed for SCons <4.3
import signal
def _reset_sig_handler2(self):
	"""Restore the signal handlers to their previous state (before the
	 call to _setup_sig_handler()."""

	signal.signal(signal.SIGINT, self.old_sigint if self.old_sigint is not None \
		else signal.SIG_DFL)
	signal.signal(signal.SIGTERM, self.old_sigterm if self.old_sigterm is not None \
		else signal.SIG_DFL)
	try:
		signal.signal(signal.SIGHUP, self.old_sighup if self.old_sighup is not None \
			else signal.SIG_DFL)
	except AttributeError:
		pass


def rm_SCons_mods():
	to_del = [mod for mod in sys.modules.keys() if mod.startswith('SCons.') or mod in ['SCons', 'pystatacons', 'pystatacons.sconstruct_aux']]

	for t in to_del:
		del(sys.modules[t])


