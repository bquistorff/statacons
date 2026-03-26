# Statacons Habits and Conventions

Personal style and preferences for SConstruct and SConscript files, derived
from reviewing all active projects in `W:\`:

| Project | SConstruct | SConscripts | Notes |
|---------|-----------|-------------|-------|
| `GenericProject` | ✓ (template) | — | Canonical blank template |
| `stataconsIntro` | ✓ | `SConscript-dataprep`, `SConscript-analysis` | Tutorial / learning |
| `BGD_San_Struc` | ✓ | — | Solo; GMM estimation + policy sims |
| `BGD_San_Struc_Sims` | ✓ | — | Minimal (dataprep only) |
| `BGD-floods-build` | ✓ | — | Solo; DHS pipeline |
| `cropResidueBurning` | ✓ | `*.SConscript` (via f2e) | Uses GIS data |
| `f2e` | ✓ | `villageDataprep.SConscript`, `spotChecks.SConscript` | Multi-SConscript |
| `mundlak` | ✓ | — | Old boilerplate only |
| `BD_Sanitation_Social/analysis` | ✓ | 14 SConscripts | Large collaborative project |
| `BD_Sanitation_Social/replication` | ✓ | 14 SConscripts (same) | Replication package |

---

## 1. SConstruct Canonical Structure

### Standard section headers

All SConstructs open with two standard section comments:

```python
# **** Setup and configuration *****

import pystatacons
env = pystatacons.init_env()

# **** Substance begins        *****
```

The padding to `*****` is intentional (it looks like a banner). Some projects
also close with:

```python
# **** Substance ends          *****
```

If SConscripts are used, the `Export` / `SConscript` / `Import` block goes
at the top of "Substance", before any tasks in the SConstruct itself:

```python
# **** Substance begins        *****

# so SConscripts can read env
Export('env')

SConscript(['First.SConscript',
            'Second.SConscript'])

# import variables from SConscripts
Import('*')
```

### `StataBuild` call formatting (preferred style)

4-space indent, `=` signs aligned so that all values start in the same column:

```python
task_name = env.StataBuild(
    target  = ['output/data/result.dta'],
    source  = 'code/analysis.do',
    depends = ['input/data/raw.dta']
)
```

`target` and `source` get two spaces before `=`; `depends` gets one — this
aligns the `=` signs vertically.

**Always use `depends=` keyword argument** rather than a separate `Depends()`
call. The `Depends()` form appears only in very old or tutorial files (e.g.,
`stataconsIntro`).

### Indentation note on older projects

Several older projects (e.g., `BGD_San_Struc`, `BGD-floods-build`, `f2e`)
use 6-space indent from the opening parenthesis:

```python
task_name = env.StataBuild(
      target = ['output/data/result.dta'],
      source = 'code/analysis.do',
      depends = ['input/data/raw.dta']
)
```

This is the old style from the original statacons SConstruct template; the
new preferred style is 4-space with aligned `=` as shown above.

---

## 2. Task Variable Naming

### No prefix in research projects

Name task variables by their role, not with a `cmd_` or other prefix:

```python
dataprep      = env.StataBuild(...)    # ✓
estimation    = env.StataBuild(...)    # ✓
tabfig        = env.StataBuild(...)    # ✓

cmd_dataprep  = env.StataBuild(...)    # ✗ (old tutorial style)
```

Exception: `stataconsIntro` uses `cmd_` for pedagogy; don't copy it to
research projects.

### Target list variables

When a task has many targets (especially for SConscript `Export`), define the
target list as a named variable before passing it to `StataBuild`:

```python
estimation_targets_sters = [
    'output/sters/results-' + spec + '.sters'
    for spec in specifications
]
estimation_targets_dta = ['output/data/estimation-summary.dta']
estimation_targets = estimation_targets_sters + estimation_targets_dta

estimation = env.StataBuild(
    target  = estimation_targets,
    source  = 'code/estimation.do',
    depends = [dataprep]
)
```

Naming convention for sub-lists: `<task>_targets_<type>` where `<type>` is
`sters`, `dta`, `tables`, `figs`, `figs_notes`, `tex`, etc.

### Ado-file lists

Group ado-file dependencies into a named Python list:

```python
GMM_ado = [
    "code/ado/" + f + ".ado"
    for f in ['helper1', 'helper2', 'helper3']
]
```

Then pass as part of `depends`:

```python
estimation = env.StataBuild(
    target  = [...],
    source  = 'code/estimation.do',
    depends = [dataprep, GMM_ado]
)
```

---

## 3. Directory Structure Conventions

```
project_root/
├── SConstruct
├── config_project.ini
├── config_local.ini          ← not git-tracked
├── code/
│   ├── dataprep.do
│   ├── estimation.do
│   ├── tabfig.do
│   ├── ado/                  ← project-specific ado files
│   │   ├── personal/         ← sysdir PERSONAL (via profile.do)
│   │   └── plus/             ← sysdir PLUS (via profile.do)
│   └── subdo/                ← sub-do files called by main do-files
├── input/data/               ← raw input data (not built by statacons)
├── output/
│   ├── data/                 ← built .dta files
│   ├── sters/                ← saved estimates (.sters)
│   ├── tab/
│   │   ├── tex/              ← LaTeX tables
│   │   ├── dta/              ← tabulation data
│   │   └── rtf/              ← RTF tables (older projects)
│   ├── fig/
│   │   ├── pdf/              ← figure PDFs
│   │   ├── tex/              ← figure notes (.tex)
│   │   └── dta/              ← figure data
│   ├── log/
│   │   ├── smcl/             ← Stata SMCL logs (used as targets when no other output)
│   │   └── log/              ← batch mode logs (from success_batch_log_dir)
│   └── docs/
│       ├── tex/              ← LaTeX compilation files
│       └── pdf/              ← compiled PDFs
```

Some older/simpler projects use `outputs/` (with trailing s) instead of
`output/` and `inputs/` instead of `input/`. New projects use `output/` and
`input/` (no trailing s), and some use `in/` and `out/` (f2e).

Estimation sub-folders in `output/data/`:
- `output/data/estimation/` — results from estimation do-files
- `output/data/policy_simulations/` — policy experiment results

---

## 4. Depends Argument Patterns

SCons accepts nested lists in `depends`; statacons flattens them
automatically. This makes it natural to mix task references with file lists:

```python
# pass task node directly — SCons infers all targets of that task
tabfig = env.StataBuild(
    target  = [...],
    source  = 'code/tabfig.do',
    depends = [estimation]       # task node, not string
)

# mix task node, string, and list
tabfig = env.StataBuild(
    target  = [...],
    source  = 'code/tabfig.do',
    depends = [estimation,
               'input/data/labels.dta',
               ado_list]
)

# use concatenated target list from another task's targets
tabfig = env.StataBuild(
    target  = [...],
    source  = 'code/tabfig.do',
    depends = estimation_targets + ['code/subdo/drawFig.do']
)
```

**Prefer task-node references** (passing the task variable) over listing
target strings, because SCons understands the dependency relationship.
Use target string lists only when you need to depend on a *subset* of a
task's outputs.

---

## 5. Handling Do-Files With No "Real" Outputs

When a do-file produces only log output (exploration, descriptive stats,
diagnostics), use its SMCL log as the target:

```python
descriptive = env.StataBuild(
    target  = ['output/log/smcl/descriptive.smcl'],
    source  = 'code/descriptive.do',
    depends = [dataprep]
)
```

The do-file must explicitly `log using "output/log/smcl/descriptive.smcl", replace smcl`.

---

## 6. The `.dtas` Sentinel Pattern

When a do-file produces many `.dta` files (e.g., an import script that
creates one `.dta` per geographic unit), listing every file as a target is
impractical. Use a single `.dtas` sentinel file instead:

```python
shrug_punjab = env.StataBuild(
    target  = ['out/data/shrug/shrug-punjab.dtas'],
    source  = 'code/shrug/shrug-import.do',
    depends = ['in/shrug/village_modified/village_modified_punjab.dta']
)
```

The do-file writes a marker file at the end:
```stata
// at end of import.do
file open fh using "out/data/shrug/shrug-punjab.dtas", write replace
file write fh "done"
file close fh
```

Downstream tasks depend on the `.dtas` sentinel as if it were the data:
```python
merge_step = env.StataBuild(
    target  = ['out/data/merged.dta'],
    source  = 'code/merge.do',
    depends = [shrug_punjab, 'out/data/other.dta']
)
```

This pattern is used heavily in `f2e` for GIS data imports.

---

## 7. SConscript Style

### File naming

Mixed convention exists: `.SConscript` (capitalized) and `.sconscript`
(lowercase) both appear in the same project. SCons treats them identically.
Prefer `.SConscript` for new files.

### Canonical SConscript structure

```python
# TaskName.SConscript

# environment exported by SConstruct
Import('env')

# ** <section description>

# define targets
task_targets_sters = [...]
task_targets_dta   = [...]
task_targets       = task_targets_sters + task_targets_dta

# build targets
task = env.StataBuild(
    target  = task_targets,
    source  = 'code/task.do',
    depends = [upstream_task, 'input/data/extra.dta']
)


# export variables for SConstruct to read
Export(['task_targets',
        'task_targets_sters',
        'task_targets_dta'])
```

### Comments

Use asterisk-depth to indicate section nesting:

```python
# ** major section
# *** sub-section
# **** sub-sub-section
# ***** sub-sub-sub-section (used in complex SConscripts)
```

### Import / Export discipline

- Import `env` at the top of every SConscript.
- `Export` at the very bottom, after all task definitions.
- Export only the variables the SConstruct (or other SConscripts) actually
  need — typically the combined target list plus any sub-lists needed for
  the `post_to_overleaf` alias.
- SConstruct uses `Import('*')` after all SConscripts are loaded, which
  brings all exports into scope.

---

## 8. SConstruct With SConscripts (Full Pattern)

```python
# **** Setup and configuration *****

import pystatacons
env = pystatacons.init_env()

# **** Substance begins        *****

Export('env')

SConscript(['DataSection.SConscript',
            'Estimation.SConscript',
            'TabFig.SConscript'])

# import variables from SConscripts
Import('*')

# any tasks that depend on SConscript results go here
```

**Order matters**: SConscripts are processed in the order listed. A
SConscript that imports a variable from another SConscript must be listed
later.

---

## 9. Configuration Files

### `config_project.ini` (always git-tracked)

Active research projects always explicitly set both `use_custom_datasignature`
and (when relevant) `dta_sig_mode`. Keep all the standard comments so the
file is self-documenting.

| Setting | When to use |
|---------|------------|
| `use_custom_datasignature: Strict` | Solo projects; most research |
| `use_custom_datasignature: LabelsFormatsOnly` | When notes/characteristics aren't meaningful; collaborative replication packages |
| `dta_sig_mode: Slow` | When collaborating or using SCons cache |
| `dta_sig_mode: Fast` | Solo, no cache (default if not set) |

Observed across projects:

| Project | `use_custom_datasignature` | `dta_sig_mode` |
|---------|--------------------------|----------------|
| BGD_San_Struc | Strict | Slow |
| BGD_San_Struc_Sims | Strict | (default) |
| BGD-floods-build | LabelsFormatsOnly | (default) |
| mundlak | Strict | (default) |
| cropResidueBurning | Strict | (default) |
| f2e | Strict | Slow |
| BD_San_Social/analysis | LabelsFormatsOnly | Slow |
| BD_San_Social/replication | LabelsFormatsOnly | Slow |
| stataconsIntro | LabelsFormatsOnly | Fast |

`Strict` is the default for most research projects. `LabelsFormatsOnly` is
used when the project produces large DHS/collaborative datasets where notes
and characteristics change frequently without meaning anything.

### `config_local.ini` (never git-tracked)

Keep a `config_local_template.ini` under version control; each user copies
it to `config_local.ini` and edits.

Current local settings on this machine:

```ini
[Programs]
stata_exe: "C:/Program Files/StataNow19/StataMP-64.exe"

[SCons]
success_batch_log_dir: output/log/log

[Project]
overleaf_dir: C:/Users/rpguiter/Dropbox/apps/Overleaf/<ProjectName>
cache_dir: C:/Users/rpguiter/Dropbox/<ProjectPath>/scons_cache
```

Keep `success_batch_log_dir` pointing to `output/log/log` (or similar) so
batch logs are preserved — useful for debugging.

---

## 10. SCons Cache (Collaborative Pattern)

Used in `BD_Sanitation_Social/analysis`. Cache is enabled via a custom
command-line option (disabled by default to avoid accidentally polluting the
shared cache):

```python
# in SConstruct, after init_env()

AddOption('--mycache-enable',
    dest    = 'mycache_enable',
    action  = 'store_true',
    default = False,
    help    = 'mycache enable'
)
CacheDir(env['CONFIG']['Project']['cache_dir'] if GetOption('mycache_enable') else None)

Help("""
To build outputs (default):
    statacons
To enable cache:
   --mycache-enable
   (additional options --cache-readonly, --cache-force, --cache-debug=-)
""", append=True)
```

`config_local.ini` sets the cache path:

```ini
[Project]
cache_dir: C:/Users/rpguiter/Dropbox/ProjectName/scons_cache
```

When not using the cache add-on, `dta_sig_mode: Slow` should still be set in
`config_project.ini` when collaborating, so that signatures are
machine-independent.

---

## 11. Overleaf Integration

Used in `BD_Sanitation_Social/analysis`. Pattern: read the Overleaf directory
from `config_local.ini`, assemble lists of files to post, use `env.Install`
to copy them, and define an `post_to_overleaf` alias.

```python
# read overleaf directory from config_local.ini
overleaf_dir = env['CONFIG']['Project']['overleaf_dir']

# (after Import('*') brings in all SConscript exports)

toPost_Tables = firstSConscript_tables + secondSConscript_tables + ...
toPost_Figs   = firstSConscript_figs   + secondSConscript_figs   + ...
toPost_Figs_Notes = firstSConscript_figs_notes + ...

env.Install(overleaf_dir + '/tab',     toPost_Tables)
env.Install(overleaf_dir + '/fig/pdf', toPost_Figs)
env.Install(overleaf_dir + '/fig/tex', toPost_Figs_Notes)

env.Alias('post_to_overleaf', overleaf_dir)
```

And in `Help(...)`:
```python
Help("""
To build outputs (default):
    statacons
To post outputs to Overleaf:
    statacons post_to_overleaf
""", append=True)
```

---

## 12. PDF Compilation (LaTeX)

Used in `BD_Sanitation_Social` SConscripts to compile summary PDFs from
`.tex` files generated by Stata:

```python
env.Tool("pdftex")
env.AppendUnique(PDFLATEXFLAGS='-quiet')

pdf_output = env.PDF(
    target = 'output/docs/pdf/summary.pdf',
    source = 'output/docs/tex/summary.tex'
)
```

Put these lines in the SConscript where the `.tex` file is built, after the
`StataBuild` that creates it.

---

## 13. Python List Comprehensions in SConstructs

Python list comprehensions are used heavily to build target lists without
repetition. Patterns seen:

### Simple loop

```python
specifications = ["spec1", "spec2", "spec3"]
estimation_sters = [
    "output/sters/results-" + spec + ".sters"
    for spec in specifications
]
```

### Multi-dimensional loop (nested `for`)

```python
# ** outer loop is first `for`, inner loop is second `for`
targets = [
    "output/tab/tex/grSh_" + z + y + "_AllVill" + w + ".tex"
    for w in ['_wtd', '']
        for z in ['r5', 'el']
            for y in ['HygOwn', 'AnyOwn', 'HygAcc']
]
```

### Loop with condition

```python
targets = [
    "output/sters/grSh_" + z + y + "_AllVill.sters"
    for z in ['r5', 'el']
        for y in ['HygOwn', 'AnyOwn', 'HygAcc', 'RegOD']
            if not (z == 'r5' and y == 'RegOD')
]
```

### Deriving a sibling list (e.g., notes files from table files)

```python
tables_notes = [
    w.replace(".tex", "-notes.tex")
    for w in tables
]

figs_notes = [
    w.replace(".pdf", "-notes.tex")
     .replace("/fig/pdf/", "/fig/tex/")
    for w in figs
        if not w.count("notitle")   # filter condition
]
```

### Loop over tasks

```python
for SPEC in specifications:
    task_SPEC = env.StataBuild(
        target  = ['output/sters/estimation-' + SPEC + '.sters'],
        source  = 'code/estimation-' + SPEC + '.do',
        depends = [dataprep, GMM_ado]
    )
```

Note: when building tasks in a loop, the loop variable name is typically
`SPEC` (uppercase), matching the project-specific terminology.

---

## 14. GenericProject Template

`W:\GenericProject\SConstruct` is the canonical blank template for new projects.
Key features of its template style:

- 4-space indent, aligned `=` (`target  =`, `source  =`, `depends =`)
- Includes commented examples in the body (not in a block quote at the bottom)
- Standard `# **** Setup` and `# **** Substance` headers
- When SConscripts are used, includes `Export('env')` / `SConscript([...])` / `Import('*')` block at top of Substance

The template also includes the `SConscript`-based variant as a comment.
When creating a new project from `GenericProject` (via `/newproject`), the
SConstruct starts from this template and the user fills in the actual tasks.

---

## 15. Summary of Key Rules

| Rule | Detail |
|------|--------|
| Use `depends=` kwarg | Never use separate `Depends()` call in new code |
| 4-space indent, aligned `=` | `target  =`, `source  =`, `depends =` |
| No `cmd_` prefix | Name tasks by role: `dataprep`, `estimation`, `tabfig` |
| `config_project.ini` always sets `use_custom_datasignature` | Default `Strict`; use `LabelsFormatsOnly` for collaborative/replication |
| Set `dta_sig_mode: Slow` when collaborating | Required for shared cache; otherwise omit |
| `success_batch_log_dir: output/log/log` | In `config_local.ini`; preserve logs for debugging |
| `stata_exe: "C:/Program Files/StataNow19/StataMP-64.exe"` | In `config_local.ini` on this Windows machine |
| Task variable for SConscript export: `<task>_targets` | Also `<task>_targets_<type>` for sub-lists |
| Ado list as Python list comprehension | `ado_list = ["code/ado/" + f + ".ado" for f in [...]]` |
| Section banners: `# **** Name *****` | Extra spaces to pad to `*****` |
| Comments: `# **`, `# ***`, `# ****` | Depth indicates nesting level |
| `.dtas` sentinel for multi-file outputs | Do-file writes a marker file; downstreams depend on marker |
| Log target for exploration do-files | `target = ['output/log/smcl/explore.smcl']` |
| SConscript `Export` at bottom | After all task definitions; only export what's needed |
| `Import('*')` in SConstruct | After all SConscript calls |
| Overleaf alias: `post_to_overleaf` | Via `env.Install` + `env.Alias` |
| Optional cache: `--mycache-enable` | `AddOption` pattern; cache off by default |

---

## Appendix A: Minimal SConstruct Template (Solo Project)

```python
# **** Setup and configuration *****

import pystatacons
env = pystatacons.init_env()

# **** Substance begins        *****

dataprep = env.StataBuild(
    target  = ['output/data/analysis-sample.dta'],
    source  = 'code/dataprep.do',
    depends = ['input/data/raw.dta']
)

estimation = env.StataBuild(
    target  = ['output/sters/results.sters',
               'output/data/results-hh.dta'],
    source  = 'code/estimation.do',
    depends = [dataprep]
)

tabfig = env.StataBuild(
    target  = ['output/tab/tex/table1.tex',
               'output/tab/tex/table1-notes.tex',
               'output/fig/pdf/figure1.pdf'],
    source  = 'code/tabfig.do',
    depends = [estimation, dataprep]
)
```

---

## Appendix B: Minimal SConscript Template

```python
# TaskName.SConscript

# environment exported by SConstruct
Import('env')

# ** <task description>

# target list
task_targets_sters = [
    'output/sters/results-' + spec + '.sters'
    for spec in ['spec1', 'spec2']
]
task_targets_dta = ['output/data/results-summary.dta']
task_targets = task_targets_sters + task_targets_dta

# build
task = env.StataBuild(
    target  = task_targets,
    source  = 'code/task.do',
    depends = ['input/data/analysis-sample.dta']
)


# export variables for SConstruct to read
Export(['task_targets',
        'task_targets_sters'])
```

---

## Appendix C: SConstruct Template With SConscripts and Overleaf

```python
# **** Setup and configuration *****

import pystatacons
env = pystatacons.init_env()

# optional cache (disabled by default)
AddOption('--mycache-enable',
    dest    = 'mycache_enable',
    action  = 'store_true',
    default = False,
    help    = 'mycache enable'
)
CacheDir(env['CONFIG']['Project']['cache_dir'] if GetOption('mycache_enable') else None)

Help("""
To build outputs (default):
    statacons
To post outputs to Overleaf:
    statacons post_to_overleaf
To enable cache:
    --mycache-enable
    (additional options --cache-readonly, --cache-force, --cache-debug=-)
""", append=True)

# **** Substance begins        *****

Export('env')

SConscript(['Estimation.SConscript',
            'TabFig.SConscript',
            'Descriptive.SConscript'])

# any tasks not in SConscripts (e.g., analysis prep shared across SConscripts)
analysis_prep = env.StataBuild(
    target  = ['output/data/analysis-sample.dta'],
    source  = 'code/analysisprep.do',
    depends = ['input/data/raw.dta']
)

# import variables from SConscripts
Import('*')

# #### post to Overleaf
overleaf_dir = env['CONFIG']['Project']['overleaf_dir']

toPost_Tables     = estimation_tables     + descriptive_tables
toPost_Figs       = estimation_figs
toPost_Figs_Notes = estimation_figs_notes

env.Install(overleaf_dir + '/tab',     toPost_Tables)
env.Install(overleaf_dir + '/fig/pdf', toPost_Figs)
env.Install(overleaf_dir + '/fig/tex', toPost_Figs_Notes)

env.Alias('post_to_overleaf', overleaf_dir)
```

---

## Appendix D: Canonical `config_project.ini`

```ini
[SCons]
#use_custom_datasignature
# how to determine whether a .dta file has changed
#False: use standard MD5 hash for .dta files.
#   Because Stata embeds a timestamp in .dta files, the standard MD5 hash
#     will change each time the file is re-written, even if there are no
#     substantive changes in the file
#DataOnly: use Stata's datasignature to calculate time-invariant hash
#   that depends on data only, not any metadata
#LabelsFormatsOnly: use custom_datasignature.ado to calculate time-invariant hash
#   that depends on data, variable formats, and variable and value labels
#   (but not on notes, characteristics or dataset labels)
#Strict: use custom_datasignature.ado to calculate time-invariant hash
#   that depends on data and all metadata
#   (variable formats, variable, value and dataset labels, notes, characteristics)
use_custom_datasignature: Strict
#use_custom_datasignature: LabelsFormatsOnly

#dta_sig_mode
# controls the "fast" mode of Stata's datasignature
# Fast: faster, but not machine-independent
#    (signature may be different across different users or machines)
# Slow: machine-independent, but slower
# by default, we use Fast unless a CacheDir() is specified in the SConstruct
#   (specifying CacheDir() indicates a collaborative workflow is likely,
#     so we use Slow so that different users will generate the same signature)
# can override by specifying option below
#dta_sig_mode: Fast
#dta_sig_mode: Slow

#stata_chdir
# option to change directory when running do-files
# if 0 or omitted, no change from where SCons wants to be
#   by default this is the directory where the SConstruct is found
# if 1 then change to the directory where the do-file is found
# if a valid path, then Stata will cd to that path
#stata_chdir: 0
```

---

## Appendix E: Canonical `config_local_template.ini`

```ini
# note that this *template* config_local_template.ini is kept under version control
# but the actual config file config_local.ini is not
# to use, save this template as "config_local.ini" (i.e., drop _template suffix) and edit

[Programs]
# Use forward slashes for paths
# stata_exe: path to Stata executable
stata_exe: "C:/Program Files/StataNow19/StataMP-64.exe"

[SCons]
# What to do with Stata batch-mode logs when successful (error logs always left)
# empty for delete
#success_batch_log_dir:
# provide path to destination to move
success_batch_log_dir: output/log/log

[Project]
# overleaf
#overleaf_dir: C:/Users/rpguiter/Dropbox/apps/Overleaf/<ProjectName>

# cache directory (shared via Dropbox)
#cache_dir: C:/Users/rpguiter/Dropbox/<ProjectPath>/scons_cache
```
