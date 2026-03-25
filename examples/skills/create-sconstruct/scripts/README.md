# `scan_project.py` and `gen_sconstruct.py` — Direct Usage Guide

These two scripts form a two-step pipeline for auto-generating a draft
`SConstruct` (and optionally SConscript files) from a Stata research project.
Run them from any directory; all paths are resolved relative to the arguments
you pass.

---

## Prerequisites

```
pip install pyyaml
```

Python 3.10 or later is required (uses `set[str] | None` union syntax).

---

## Step 1 — Scan the project: `scan_project.py`

### What it does

Walks `code/*.do` (task do-files only), parses every Stata I/O command,
resolves macros, cross-checks against log files, and writes a
`scan_results.yaml` recording inputs, outputs, and dependencies for each
do-file.

> **Important:** The scanner only picks up do-files in `code/` directly
> (one level deep). Do-files in subdirectories like `code/shrug/`,
> `code/admin19/`, etc. are **not** automatically discovered. You must handle
> those manually after reviewing the YAML.

### Basic usage

```
python scan_project.py <project_root>
```

`<project_root>` is the top-level directory of the Stata project (the folder
that contains `code/`, `input/`, `output/`, etc.). The output file
`scan_results.yaml` is written inside `<project_root>` by default.

### All options

```
python scan_project.py <project_root> [options]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--out PATH` | `<project_root>/scan_results.yaml` | Output YAML file or directory. If PATH is a directory, saves `scan_results.yaml` inside it. |
| `-f`, `--file DO_FILE` | off | Restrict scan to one or more do-files. Match by filename, relative path, or absolute path. Repeatable or space-separated. Marks the output YAML with `is_fragment: true` so `gen_sconstruct.py` automatically uses Fragment naming. |
| `--log-txt-dir DIR` | `<root>/output/log/log` | Directory of plain-text `.log` files (used for macro resolution layer 3). |
| `--log-smcl-dir DIR` | `<root>/output/log/smcl` | Directory of `.smcl` log files (fallback when no plain-text log exists). |
| `--include-testing` | off | Include `testing_*.do` and `_*.do` files as build tasks (excluded by default). |
| `--no-expand-macros` | off | Skip Python-side macro resolution. Unresolved macro paths are written as-is to the YAML (and later to the SConstruct as `# TODO` items). |
| `--quiet` | off | Suppress the summary printed to stdout. |

**Adopath options** (controls which Stata ado paths are scanned for
external packages; BASE and SITE are always excluded):

| Option | Default | Description |
|--------|---------|-------------|
| `--no-personal` | off | Exclude the Stata `PERSONAL` ado path. |
| `--no-plus` | off | Exclude the Stata `PLUS` ado path. |
| `--include-oldplace` | off | Include the Stata `OLDPLACE` ado path. |
| `--extra-ado DIR` | — | Additional ado directory to scan. Repeatable. |

**Project ado options** (controls which parts of `code/ado/` are included):

| Option | Default | Description |
|--------|---------|-------------|
| `--no-ado-root` | off | Exclude `code/ado/*.ado` (root-level ados). |
| `--no-ado-subdir NAME` | — | Exclude a named `code/ado/<NAME>/` subdirectory. Repeatable. |

### Example invocations

```bash
# Minimal — scan from project root, write scan_results.yaml there
python scan_project.py W:\myproject

# Save YAML to a separate folder; exclude system ado paths
python scan_project.py W:\myproject \
    --out C:\tmp\myproject-scan \
    --no-personal \
    --no-plus

# Scan only specific do-files (fragment mode — auto-named SConstructFragment later)
python scan_project.py W:\myproject \
    --file code/dataprep.do code/estimation.do \
    --out C:\tmp\myproject-scan

# Exclude specific ado subdirectories
python scan_project.py W:\myproject \
    --no-ado-subdir plus \
    --no-ado-subdir personal

# Skip macro expansion (faster, but leaves TODOs in output)
python scan_project.py W:\myproject --no-expand-macros
```

### Reviewing `scan_results.yaml`

The YAML contains one entry per task do-file with:

- `inputs` / `outputs` — paths found by command parsing
- `raw_file_deps` — inputs that come from `input/` (not produced by another task)
- `depends_on` — other task do-files this one depends on
- `header_discrepancies` — mismatches between the `inputs:`/`outputs:` header comment and what the scanner found

**Review and edit the YAML before running step 2.** In particular:
- Verify that `depends_on` chains are correct.
- Check any `# TODO` or `unresolved` entries.
- Add or remove paths as needed.

The YAML is designed to be human-readable and safely editable.

---

## Step 2 — Generate the SConstruct: `gen_sconstruct.py`

### What it does

Reads `scan_results.yaml` and writes a `SConstruct.draft` (and optionally
per-group `<Group>.SConscript.draft` files) following statacons conventions.

### Basic usage

```
python gen_sconstruct.py <scan_results.yaml>
```

Output is written to the project root recorded in the YAML unless `--out` is
specified.

### All options

| Option | Default | Description |
|--------|---------|-------------|
| `<scan_results.yaml>` | *(required)* | Path to the YAML produced by `scan_project.py`. |
| `--out DIR` | `project_root` from YAML | Directory to write output files into. |
| `-d`, `--draft` | off | Write `SConstructDraft` and `[name]Draft.SConscript` instead of `SConstruct` and `[name].SConscript`. Prompted automatically when existing build files are found (see below). |
| `-f`, `--file DO_FILE` | off | Restrict output to one or more do-files from the YAML. Match by filename or relative path. Forces Fragment naming (see below). Repeatable or space-separated. |
| `--sconscripts` | off | Also generate one SConscript per task group in addition to the SConstruct. |
| `--no-ado-list` | off | Omit all ado dependency variables from `depends=` lines. |
| `--no-track-ado-plus` | off | Exclude the `ado_plus` group from all `depends=` lines. |
| `--no-track-ado-personal` | off | Exclude the `ado_personal` group from all `depends=` lines. |
| `--no-track-ado` | off | Exclude **all** external ado groups (combines `--no-track-ado-plus` and `--no-track-ado-personal`). |

### Draft mode

When `--draft` is used (or `-d`), the script writes `SConstructDraft` and
`[name]Draft.SConscript` rather than `SConstruct` and `[name].SConscript`.
This is useful when you want to compare a newly generated build alongside an
existing one without overwriting it.

**Automatic prompt:** If `--draft` is *not* passed but `SConstruct` or any
`*.SConscript` files already exist in the output directory, the script will
ask:

```
Existing build file(s) found in <dir>:  SConstruct, villageDataprep.SConscript
Write as draft (SConstructDraft / [name]Draft.SConscript)? [Y/n]
```

Pressing Enter (or typing `y`/`yes`) selects draft mode. Typing `n`/`no`
overwrites the existing files.

### Fragment mode

When `--file` is used (or `-f`), the script generates a **fragment** — an
SConstruct covering only the specified do-files rather than the whole project.
Fragment naming is forced regardless of `--draft`:

| Normal | Fragment |
|--------|----------|
| `SConstruct` | `SConstructFragment` |
| `[name].SConscript` | `[name]Fragment.SConscript` |

**Fragment files are never overwritten.** If `SConstructFragment` (or a
corresponding `[name]Fragment.SConscript`) already exists in the output
directory, the script exits with an error. Delete the file first if you want
to regenerate it.

Fragment mode is also triggered automatically when `scan_results.yaml`
contains `is_fragment: true` (set by `scan_project.py --file`). In that case
you do not need to pass `--file` again to `gen_sconstruct.py`; the naming is
applied automatically.

### Task grouping

Tasks are automatically grouped into sections by keywords in the do-file stem:

| Group | Keywords matched in do-file name |
|-------|----------------------------------|
| Dataprep | `dataprep`, `clean`, `import`, `build`, `prep`, `construct`, `merge`, `append`, `reshape`, `recode`, `deflat` |
| Estimation | `estimat`, `regress`, `gmm`, `iv`, `ols`, `fe`, `probit`, `logit`, `event`, `did`, `diff`, `rdrobust`, `spec` |
| Simulation | `sim`, `simulat`, `monte`, `boot`, `permut` |
| TabFig | `tabfig`, `table`, `figure`, `fig`, `tab`, `plot`, `graph`, `bar`, `scatter`, `descstat`, `sumstat`, `balance` |
| Appendix | `appendix`, `robust`, `sensitivity`, `placebo`, `hetero` |
| Main | *(everything else)* |

### Example invocations

```bash
# Inline SConstruct (all tasks in one file)
python gen_sconstruct.py W:\myproject\scan_results.yaml

# Force draft mode (writes SConstructDraft alongside an existing SConstruct)
python gen_sconstruct.py W:\myproject\scan_results.yaml --draft

# Generate per-group SConscripts as well
python gen_sconstruct.py W:\myproject\scan_results.yaml --sconscripts

# Write output to a different directory
python gen_sconstruct.py C:\tmp\myproject-scan\scan_results.yaml \
    --out C:\tmp\myproject-scan

# Fragment: generate SConstructFragment for two specific do-files
python gen_sconstruct.py W:\myproject\scan_results.yaml \
    --file code/dataprep.do code/estimation.do \
    --out W:\myproject

# Omit ado dependency tracking entirely
python gen_sconstruct.py W:\myproject\scan_results.yaml --no-ado-list
```

### Output files

| File | Description |
|------|-------------|
| `SConstruct` | Generated SConstruct. Ready to use (review first). |
| `SConstructDraft` | Generated SConstruct in draft mode (`-d` or prompted). Rename to `SConstruct` when ready. |
| `SConstructFragment` | Generated SConstruct in fragment mode (`-f`). Contains only the requested do-files. |
| `<Group>.SConscript` | Generated SConscript per group (only with `--sconscripts`). |
| `<Group>Draft.SConscript` | Same, in draft mode. Rename to `<Group>.SConscript` when ready. |
| `<Group>Fragment.SConscript` | Same, in fragment mode. |

---

## Full two-step example

```bash
# From the project root
cd W:\myproject

# Step 1: scan
python C:\path\to\scan_project.py . \
    --no-personal --no-plus \
    --out C:\tmp\myproject-scan

# Review the YAML
code C:\tmp\myproject-scan\scan_results.yaml

# Step 2: generate (no existing SConstruct in target dir — writes directly)
python C:\path\to\gen_sconstruct.py C:\tmp\myproject-scan\scan_results.yaml \
    --out C:\tmp\myproject-scan

# If SConstruct already exists in the target dir, the script will prompt.
# To skip the prompt and always write a draft alongside the existing file:
python C:\path\to\gen_sconstruct.py C:\tmp\myproject-scan\scan_results.yaml \
    --out W:\myproject --draft

# Review the draft, then rename when ready
rename W:\myproject\SConstructDraft SConstruct
```

## Fragment workflow — scanning or generating for a subset of do-files

Use this when you want to add or update just a few tasks without regenerating
the whole SConstruct.

```bash
# Option A: scan only the relevant do-files (produces is_fragment: true in YAML)
python C:\path\to\scan_project.py W:\myproject \
    --file code/new-task.do code/another-task.do \
    --out C:\tmp\myproject-fragment

# gen_sconstruct.py auto-detects fragment mode from the YAML
python C:\path\to\gen_sconstruct.py C:\tmp\myproject-fragment\scan_results.yaml \
    --out W:\myproject
# → writes SConstructFragment (never overwrites SConstruct)

# Option B: full scan, generate fragment on the fly from existing YAML
python C:\path\to\gen_sconstruct.py W:\myproject\scan_results.yaml \
    --file code/new-task.do \
    --out W:\myproject
# → writes SConstructFragment with only that one task

# Review, then manually copy the relevant StataBuild blocks into SConstruct
```

---

## Known limitations

- **Subdirectory do-files are not auto-discovered.** Only `code/*.do` (one level
  deep) is scanned. Do-files in `code/shrug/`, `code/admin19/`, etc. must be
  added manually to the SConstruct after reviewing the generated draft.
- **Graph and figure outputs** written inside `foreach` loops (where the
  filename contains a looping variable) cannot be resolved statically and will
  appear as `# TODO` items or be omitted.
- **`antyodaya_19`-style pre-existing outputs** used as inputs (files produced
  outside the scanned pipeline) are not automatically distinguished from
  raw `input/` files; verify `raw_file_deps` entries carefully.
- **Shapefile `.dbf` sidecars** are not tracked as separate dependencies unless
  you add them manually; the scanner only sees the path string in the
  `geoframe create ... using "file.shp"` command.
