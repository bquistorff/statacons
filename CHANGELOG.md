# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- On Windows, if `pywin32` is installed, Stata batch-mode processes will be launched in a hidden desktop to prevent them from briefly stealing the UI focus. This can be disabled by setting the `win_stata_hidden` key's value to `False` in the section `Programs`.
### Changed
- We changed `config_user.ini` to `config_local.ini` and changed the CLI option to `config-local` which now accepts a colon-delimited list of files that can be used instead of the default sources.

## 2.0.0
### Changed
- Switched format for importing Python functions into `SConstruct` file to now use a separate package (`pystatacons`) rather than `exec`ing a local `sconstruct_aux` file.
- Split off `assume-done` from `assume-built`
### Added
- Strip quotes (single + double) from paths (stata_exe, cache_dir, success_batch_log_dir) for convenience (quotes are never needed for paths in config files).
- Automatically down-grade parallel execution to sequential in Stata (crashes otherwise).
- New Decider 'content-timestamp-newer' and new exported `decider_str_lookup` to map all typical strings to valid `Decider` input.
- Make imports from `pystatacons` rather than from `pystatacons.sconstruct_aux`.
