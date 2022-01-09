# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Changed
- Switched format for importing Python functions into `SConstruct` file to now use a separate package (`pystatacons`) rather than `exec`ing a local `sconstruct_aux` file.
