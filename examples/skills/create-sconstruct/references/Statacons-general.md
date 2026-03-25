# Statacons General Reference

Synthesized from:
- Guiteras, Kim, Quistorff & Shumway, "statacons: An SCons-based build tool for
  Stata," *The Stata Journal* 23(1):149–196, 2023. doi:10.1177/1536867X231162032
- Project web page: https://bquistorff.github.io/statacons/
- Project wiki: https://github.com/bquistorff/statacons/wiki
- `statacons`, `stataconsign`, `complete_datasignature` help files
- `pystatacons` Python API documentation

Intended as a dense reference for writing SConstruct files for Stata workflows.

---

## 1. What Statacons Is

Statacons is a wrapper around the SCons build system that integrates
Stata-specific features: running do-files in batch mode, smart content
signatures for `.dta` files, and a Stata-side command (`statacons`) so users
never need to leave Stata to run a build.

It replaces the traditional "master do-file" pattern. Instead of commenting
and uncommenting lines in a master script, you declare your pipeline once in
an `SConstruct` file and let statacons figure out what needs to be rebuilt.

**Components:**

| Component | Role |
|-----------|------|
| `statacons.ado` | Stata command that calls SCons from inside Stata |
| `pystatacons` (Python pkg) | Provides `init_env()` and `StataBuild()` for SConstructs |
| `complete_datasignature.ado` | Stata command for timestamp-independent `.dta` signatures |
| `stataconsign.ado` | Wrapper around `sconsign` to inspect the signature database |
| `SConstruct` | Root build script (Python file written by the user) |
| `config_project.ini` | Project-wide configuration (git-tracked) |
| `config_local.ini` | Machine-specific configuration (not git-tracked) |

---

## 2. Installation

### Requirements

- Stata 16 or later
- Python 3.6 or later (3.8+ for some advanced options)
- SCons 4.3 or later (SCons 4.5+ requires statacons 3.0.1+)

### Python packages

```bash
pip install scons
pip install pystatacons
pip install pywin32          # Windows only
```

### Stata package

```stata
net install statacons, from(https://raw.github.com/bquistorff/statacons/main/) force replace
```

### Project files (templates)

From the project root directory in Stata:

```stata
net get statacons, from(https://raw.github.com/bquistorff/statacons/main/)
unzipfile project_files
rm project_files.zip
```

This installs: `SConstruct`, `config_project.ini`,
`utils/config_local_template.ini`, `utils/profile_template.do`,
`utils/debugging-checklist_template.do`, `utils/.gitignore_template`.

### Verify installation

```stata
python which SCons       // case-sensitive
python which pystatacons
statacons, show_config   // show detected configuration
```

### Updating

```stata
net install statacons, from(https://raw.github.com/bquistorff/statacons/main/) force replace
```

```bash
pip install --upgrade pystatacons
```

---

## 3. The SConstruct File

Every project has exactly one root `SConstruct` (plus optional `SConscript`
sub-files). The `SConstruct` is a Python file.

### Minimal boilerplate

```python
import pystatacons
env = pystatacons.init_env()

# --- tasks below ---
```

`pystatacons.init_env()` reads `config_project.ini` and `config_local.ini`,
auto-detects Stata, patches SCons for `.dta`-aware signatures, and attaches
`StataBuild()` to the environment.

### Basic task recipe

```python
task_name = env.StataBuild(
    target = ['path/to/output1.dta', 'path/to/output2.tex'],
    source = 'code/myscript.do'
)
Depends(task_name, ['path/to/input.dta',
                    'code/ado/personal/myhelper.ado'])
```

**Equivalent alternative using `depends=` keyword** (cleaner style, avoids
a separate `Depends()` call):

```python
task_name = env.StataBuild(
    target  = ['path/to/output1.dta', 'path/to/output2.tex'],
    source  = 'code/myscript.do',
    depends = ['path/to/input.dta',
               'code/ado/personal/myhelper.ado']
)
```

Both forms are equivalent. The project convention (see `skills.md`) is to use
`depends=`.

---

## 4. `env.StataBuild()` — Full Parameter Reference

```python
env.StataBuild(
    target   = ['path/to/target1.ext', ...],   # required
    source   = 'path/to/dofile.do',            # or use do_file=
    do_file  = 'path/to/dofile.do',            # alternative to source
    file_cmd = 'do',                           # default; change to 'dyndoc', 'markdoc', etc.
    params   = '"arg1" "arg2"',                # arguments appended to the batch-mode call
    depends  = ['path/to/dep1', ...],          # additional dependencies
    full_cmd = 'dyndoc myfile.dyndoc, ...',    # overrides file_cmd + source + params
)
```

### How the batch-mode call is constructed

`statacons` calls Stata in batch mode as:

```
stata_exe /e <file_cmd> "<source>" <params>
```

With defaults this becomes:

```
stata_exe /e do "code/myscript.do"
```

With `params`:

```python
env.StataBuild(
    target   = ['outputs/data/isles.dta'],
    source   = 'code/countWords.do',
    params   = '"isles"'
)
# → stata_exe /e do "code/countWords.do" "isles"
```

With `file_cmd`:

```python
env.StataBuild(
    target   = ['statacons.sthlp'],
    do_file  = 'statacons.ado',
    file_cmd = 'markdoc',
    params   = ', export(statacons.sthlp) mini replace'
)
# → stata_exe /e markdoc "statacons.ado" , export(statacons.sthlp) mini replace
```

### Key behaviors

- All targets are automatically marked `Precious()` (SCons will not delete
  them on error or interrupt).
- Batch-mode log files are named with a short hash suffix for uniqueness.
  By default successful logs are **deleted**; set `success_batch_log_dir`
  in `config_local.ini` to a path to keep them.
- On Windows with `pywin32` installed, Stata batch-mode runs in a hidden
  desktop to prevent focus stealing. Process IDs are printed so tasks can be
  killed via Task Manager if needed.

### Using Python loops to reduce repetition

```python
cmds = {}
for book in ["isles", "abyss", "last"]:
    cmds[book] = env.StataBuild(
        target  = f'outputs/data/dta/{book}.dta',
        source  = 'code/countWords.do',
        params  = f'"{book}"',
        depends = [f'inputs/txt/{book}.txt']
    )
```

---

## 5. Running Statacons (Stata-side Command)

### Syntax

```stata
statacons [targets] [, option(value)]
```

### Most-used options

| Stata option | SCons equivalent | Description |
|---|---|---|
| *(none)* | `scons` | Build all default targets |
| `clean` | `-c` | Remove specified targets |
| `dry_run` | `-n` | Show what would be done; don't run |
| `debug(explain)` | `--debug=explain` | Explain why each target is being rebuilt |
| `tree(status,prune)` | `--tree=status,prune` | Show dependency tree with file status |
| `q` | `-Q` | Suppress SCons progress messages |
| `silent` | `-s` | Suppress all output |
| `file(MyFile)` | `-f MyFile` | Use a non-default SConstruct file |
| `directory(path)` | `-C path` | Change to directory before building |
| `help` | `-h` | Print help message |

### Custom statacons options (no SCons equivalent)

| Option | Description |
|--------|-------------|
| `assume_built("target")` | Skip task if all targets listed; mark as up-to-date |
| `assume_done("filename.do")` | Skip the specified do-file; mark targets as up-to-date |
| `assume_done(*)` | Skip all do-files; mark all targets as up-to-date |
| `config_file(FILE)` | Specify alternate configuration file |
| `show_config` | Display current configuration |

### Common invocations

```stata
statacons                                // build all default targets
statacons outputs/data/result.dta        // build one specific target
statacons, clean                         // remove default targets
statacons, dry_run debug(explain)        // preview with explanations
statacons, debug(explain) tree(status,prune)  // full diagnostic view
statacons, show_config                   // check configuration
statacons, assume_done(*)                // mark everything built (use with care)
```

### Return value

`r(py_rc)`: Python return code. Non-zero triggers Stata error 7103.

---

## 6. Configuration Files

Two `.ini` files control statacons behavior. Both use standard Python
`configparser` format (`key: value`, section headers `[Section]`).

### `config_project.ini` (git-tracked; shared across team)

```ini
[SCons]
use_custom_datasignature: Strict
# Options: Strict | LabelsFormatsOnly | DataOnly | False
# Strict        = data + all metadata (labels, notes, characteristics)
# LabelsFormatsOnly = data + variable formats + variable/value labels
# DataOnly      = data only (= Stata's datasignature)
# False         = plain MD5 (not recommended: .dta timestamp always changes)

#dta_sig_mode: Slow
# Slow = machine-independent (required for shared cache / collaboration)
# Fast = faster, but signatures may differ across machines (default unless CacheDir used)

#stata_chdir: 0
# 0 = run from project root (default)
# 1 = cd to do-file's directory before running
# path = cd to that path
```

### `config_local.ini` (NOT git-tracked; machine-specific)

```ini
[Programs]
stata_exe: "C:/Program Files/Stata18/StataMP-64.exe"
# Path to Stata executable. Omit if auto-detection works.
# win_stata_hidden: False   # disable hidden-desktop on Windows if needed

[SCons]
success_batch_log_dir: output/log/log/
# Where to put successful batch logs (empty = delete them)

[Project]
cache_dir: ./scons_cache
# Path to SCons cache directory for collaborative workflows
# overleaf_dir: C:/Users/.../Dropbox/apps/Overleaf/ProjectName
# dropbox_dir:  C:/Users/.../Dropbox/ProjectName
```

Reading config values in the SConstruct:

```python
CacheDir(env['CONFIG']['Project']['cache_dir'])
overleaf = env['CONFIG']['Project']['overleaf_dir']
```

### `profile.do` (project-level Stata profile)

```stata
// keep ado-files local to this project
sysdir set PLUS     code/ado/plus
sysdir set PERSONAL code/ado/personal
sysdir set OLDPLACE code/ado

if "`c(mode)'"=="batch" {
    set graphics off
}
else {
    set graphics on
}
```

---

## 7. Content Signatures for `.dta` Files

### The problem

Stata embeds a timestamp in every `.dta` file. A plain MD5 hash changes every
time the file is saved, even if the data are identical — causing unnecessary
rebuilds.

### `complete_datasignature`

Custom ado-file included with statacons. Creates a timestamp-independent
signature, with user control over what metadata is included.

```stata
complete_datasignature [, dta_file("file.dta") fname("sig.txt") nometa fast labels_formats_only]
```

| Option | What the signature covers |
|--------|--------------------------|
| *(none)* | Data + all metadata (labels, notes, characteristics) |
| `labels_formats_only` | Data + variable formats + variable/value labels |
| `nometa` | Data only (identical to Stata's `datasignature`) |
| `fast` | Uses `_datasignature fast` — faster but **not machine-independent** |

Stored result: `r(signature)`.

### Signature modes in `config_project.ini`

| `use_custom_datasignature` value | Covers |
|---|---|
| `Strict` | Data + all metadata |
| `LabelsFormatsOnly` | Data + formats + variable/value labels |
| `DataOnly` | Data only |
| `False` | Plain MD5 (timestamps will cause false rebuilds) |

**Recommended**: `Strict` for solo work; `Strict` + `dta_sig_mode: Slow` for
collaborative projects (machine-independent hashes are required when using
the SCons cache).

### Using metadata separation to avoid false rebuilds

Problem: if `regressions.do` depends on `auto-modified.dta` and you change
only a variable label (metadata), statacons will re-run regressions
unnecessarily (even with `LabelsFormatsOnly` mode, because the label *is*
part of the signature).

Solution — separate metadata from data:

1. Create `auto-noMeta.dta` by stripping all labels/notes from
   `auto-modified.dta` (via a `removeMeta.do`).
2. Make `regressions.sters` depend on `auto-noMeta.dta` (data only).
3. Make `tabfig.do` depend on both `auto-modified.dta` (for labels) and
   `regressions.sters` (for results).

```python
cmd_removeMeta = env.StataBuild(
    target  = ['outputs/auto-noMeta.dta'],
    source  = 'code/removeMeta.do',
    depends = ['outputs/auto-modified.dta']
)
cmd_regressions = env.StataBuild(
    target  = ['outputs/regressions.sters'],
    source  = 'code/regressions.do',
    depends = ['outputs/auto-noMeta.dta']
)
cmd_tabfig = env.StataBuild(
    target  = ['outputs/scatterplot.pdf', 'outputs/regressionTable.tex'],
    source  = 'code/tabfig.do',
    depends = ['outputs/auto-modified.dta', 'outputs/regressions.sters']
)
```

---

## 8. Separation of Concerns

A core design principle: split do-files so each does one logical thing.
A change to table formatting should not force regressions to re-run.

**Typical split:**
- `dataprep.do` → `outputs/auto-modified.dta`
- `regressions.do` → `outputs/regressions.sters` (uses `estwrite ... reproducible`)
- `tabfig.do` → figures + tables (uses `estread`, loads `auto-modified.dta` for labels)

**In the do-files:**

```stata
// regressions.do — save estimates reproducibly
estwrite linear quadratic using "outputs/regressions.sters", reproducible replace
exit

// tabfig.do — reload estimates and labels separately
use "outputs/auto-modified.dta", clear
estimates clear
estread using "outputs/regressions.sters"
```

**Key**: `estwrite ..., reproducible` produces a machine-independent `.sters`
file so SCons content signatures are stable across machines.

---

## 9. Aliases and Default Targets

### `Alias`

```python
env.Alias("dats", ["outputs/data/dta/isles.dta",
                   "outputs/data/dta/abyss.dta"])
```

```stata
statacons dats           // build all files in the alias
statacons dats, clean    // clean them
```

### `Default`

```python
env.Default(["outputs/tables/results.txt"])
```

Targets listed in `Default()` are built when `statacons` is called with no
target argument. Other targets can still be built by name.

### `Ignore`

```python
Ignore('.', 'some_file.ext')
```

Excludes a target from the default build.

---

## 10. SConscripts and Hierarchical Builds

For large projects, split the SConstruct into sub-files. Use `Export()` and
`Import()` to pass environments and variables between files.

```python
# SConstruct
import pystatacons
env = pystatacons.init_env()
Export('env')
SConscript('SConscript-dataprep')
SConscript('SConscript-analysis')
```

```python
# SConscript-dataprep
Import('env')
dataprep_Targets = ['outputs/auto-modified.dta']
Alias('dataprep', dataprep_Targets)
cmd_dataprep = env.StataBuild(
    target  = dataprep_Targets,
    source  = 'code/dataprep.do',
    depends = ['inputs/auto-original.dta']
)
Export('dataprep_Targets')
```

```python
# SConscript-analysis
Import('env')
Import('dataprep_Targets')
cmd_analysis = env.StataBuild(
    target  = ['outputs/scatterplot.pdf', 'outputs/regressionTable.tex'],
    source  = 'code/analysis.do',
    depends = dataprep_Targets
)
```

**When to use SConscripts:** large project with many do-files; modular
project with separate phases (data ingestion, cleaning, analysis, outputs);
when different parts need different SCons options (e.g., separate parallel
settings).

---

## 11. Parallel Builds

SCons supports parallel builds natively (`scons -j N`). The `statacons`
Stata command does **not** support parallel builds directly — use `scons`
from a terminal instead.

```python
# in SConstruct or SConscript
SetOption('num_jobs', 2)     # or: scons -j 2 --file=SConstructParallel
SConsignFile("sconsignParallel")   # use separate sconsign database

cmds = {}
for outcome in ["awards", "decisions", "jallowrate", "dispositions"]:
    cmds[outcome] = env.StataBuild(
        source  = f"code/sunabraham_estimation_{outcome}.do",
        target  = [f'outputs/dta/sunAbrahamResults_{outcome}.dta'],
        depends = [f'outputs/dta/sunAbrahamSample_{outcome}.dta']
    )
```

**Cautions:**
- Multiple Stata processes can safely *read* the same file simultaneously.
- Never have two parallel tasks *write* to the same output file.
- Parallel efficiency depends on Stata edition (number of cores), RAM, and I/O.
- For Monte Carlo / bootstrap parallelism, `parallel` (Vega Yon & Quistorff,
  SJ 2019) is a better fit than statacons parallel builds.

---

## 12. Collaborative Workflows and the SCons Cache

### The core problem

SCons decisions are based on its `.sconsign.dblite` database — built when
SCons ran on *your* machine. If a collaborator shares updated `.dta` files,
your SCons will see that the source has changed since it last built the
target and will force a rebuild, even if the collaborator's build is current.

### Preferred solution: the SCons cache

A shared folder (Dropbox, network drive) stores built files by their
content signature. Before building a target, SCons checks the cache first.

```python
# in SConstruct
SConsignFile(".sconsignCache")          # separate DB for cache-mode builds
CacheDir(env['CONFIG']['Project']['cache_dir'])
```

`config_local.ini` holds the path (different per user):

```ini
[Project]
cache_dir: C:/Users/UserName/Dropbox/ProjectName/scons_cache
```

### Cache workflow discipline

| Cache option | Effect |
|---|---|
| *(default)* | Read from cache; write newly built files to cache |
| `cache_readonly` | Read from cache; do NOT write |
| `cache_disable` | Ignore cache entirely |
| `cache_force` | Write ALL derived files to cache (force populate) |
| `cache_show` | Print what *would have been done* instead of "retrieved from cache" |
| `cache_debug(-)` | Print cache file details to screen |

**Best practice:**
1. While developing/testing, use `statacons, cache_readonly` or
   `statacons, cache_disable` to avoid polluting the shared cache.
2. Once your build is confirmed correct, use `statacons, cache_force` to
   populate the cache for collaborators.

### `assume_built` / `assume_done` (manual override)

Use sparingly when you know a file is up-to-date but SCons cannot verify it
(e.g., after receiving a collaborator's pre-built file).

```stata
statacons, assume_built("outputs/auto-modified.dta")
statacons, assume_done("code/dataprep.do")
statacons, assume_done(*)    // mark everything as done — use with extreme care
```

### What NOT to do

- Do **not** share the `.sconsign.dblite` database via Dropbox or git. It is
  a binary file tied to one machine's build history; sharing it causes
  confusion and corruption.

---

## 13. `stataconsign` — Inspecting the Signature Database

```stata
stataconsign                         // print database to Stata window
stataconsign -r                      // human-readable timestamps
stataconsign dbs/.sconsignParallel.dblite  // examine a named DB
```

The database (`SConsignFile`) records content signatures and dependency lists
for every target SCons has built. Use `SConsignFile("path/name")` in the
SConstruct to give it a custom location/name (useful when running multiple
parallel SConstructs).

---

## 14. Key Patterns Reference

### Standard SConstruct skeleton

```python
import pystatacons
env = pystatacons.init_env()

# Optional: shared cache
# SConsignFile(".sconsignCache")
# CacheDir(env['CONFIG']['Project']['cache_dir'])

# --- Tasks ---

cmd_dataprep = env.StataBuild(
    target  = ['outputs/data/cleaned.dta'],
    source  = 'code/dataprep.do',
    depends = ['inputs/data/raw.dta',
               'code/ado/personal/myhelper.ado']
)

cmd_analysis = env.StataBuild(
    target  = ['outputs/sters/results.sters'],
    source  = 'code/analysis.do',
    depends = [cmd_dataprep, 'inputs/data/other.dta']
)

cmd_tabfig = env.StataBuild(
    target  = ['outputs/tab/tex/table1.tex',
               'outputs/fig/pdf/fig1.pdf'],
    source  = 'code/tabfig.do',
    depends = [cmd_analysis, cmd_dataprep]
)

env.Default(['outputs/tab/tex/table1.tex', 'outputs/fig/pdf/fig1.pdf'])
```

### Python loop for parametric tasks

```python
ado_list = ["code/ado/personal/" + f + ".ado"
            for f in ['prog1', 'prog2']]

cmds = {}
for g in ["group1", "group2", "group3"]:
    cmds[g] = env.StataBuild(
        target  = [f'outputs/data/{g}-results.dta'],
        source  = 'code/analysis.do',
        params  = f'"{g}"',
        depends = [f'inputs/data/{g}.dta'] + ado_list
    )
```

### SConscript-based hierarchical build

```python
# SConstruct
import pystatacons
env = pystatacons.init_env()
Export('env')
SConscript('code/SConscript-dataprep')
SConscript('code/SConscript-analysis')
```

### Passing arguments to do-files

A do-file that accepts arguments (`args`):

```stata
// code/myanalysis.do
args group
use "inputs/data/`group'.dta", clear
// ...
save "outputs/data/`group'-results.dta", replace
```

SConstruct:

```python
env.StataBuild(
    target = ['outputs/data/group1-results.dta'],
    source = 'code/myanalysis.do',
    params = '"group1"'
)
```

### Handling many outputs

See **`SCons-general.md` § 14 "Handling many outputs: three strategies"** for
the full decision guide. Strategy A (list comprehensions) is the most common
in Stata workflows. A real example from `BD_Sanitation_Social`:

```python
# ~20 .sters files across combinations of weight × period × outcome
estimation_targets_sters = [
    'output/sters/grSh_' + z + y + '_SingleTreat' + w + '.sters'
    for w in ['_wtd', '']
        for z in ['r5', 'el']
            for y in ['HygOwn', 'AnyOwn', 'HygAcc', 'AnyAcc', 'LatPrimOD', 'RegOD']
                if not (z == 'r5' and y == 'RegOD')
]
estimation_targets = estimation_targets_sters + \
    ['output/tab/dta/group_analysis_SingleTreat.dta']

estimation = env.StataBuild(
    target  = estimation_targets,
    source  = 'code/basicProgramEffects-SingleTreat-regressions.do',
    depends = ['output/data/group_analysis.dta'],
)
```

For Strategy C (marker file), the Stata convention is to use a `.dtas`
extension. The do-file writes the marker at the very end:

```stata
// at end of import.do
file open fh using "output/data/shrug/shrug-punjab.dtas", write replace
file write fh "done"
file close fh
```

See `SCons-python.md` § 4 for Python-specific implementation notes on
Strategy C.

---

## 15. Debugging and Troubleshooting

### Diagnostic commands

```stata
statacons, dry_run debug(explain)             // what will be built and why
statacons, debug(explain) tree(status,prune)  // full dependency tree
statacons, show_config                        // show detected configuration
stataconsign                                  // inspect signature database
```

### Tree status legend

```
E  = file exists on disk
R  = exists in repository (cache) only
b  = implicit builder
B  = explicit builder (defined in SConstruct)
S  = side effect
P  = precious (will not be deleted on error)
A  = always build
C  = current (up to date)
N  = no clean
H  = no cache
```

### `utils/debugging-checklist.do`

Copy from template (`debugging-checklist_template.do`) and run interactively
to verify:
- Python and SCons versions visible to Stata
- `pystatacons` importable from Stata
- Configuration files found and parsed correctly
- Stata executable detected correctly

### Common problems

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Target rebuilt even though nothing changed | Using `False` datasig mode (MD5 on .dta) | Set `use_custom_datasignature: Strict` in `config_project.ini` |
| "No previous build information found" | First time building this target with statacons | Normal; rebuild will happen once |
| Collaborator's files trigger rebuild | `.sconsign.dblite` is machine-specific | Use SCons cache (`CacheDir`) or `assume_built` |
| Stata not found | Auto-detection failed | Set `stata_exe` in `config_local.ini` |
| Wrong Stata version used | Multiple versions installed | Set `stata_exe` to full path of preferred version |
| Batch log accumulation | Default deletes on success; dir not writable | Set `success_batch_log_dir` or leave empty to delete |
| All files rebuilding after minor builder change | Action signature changed | Use `assume_done(*)` once to reset |
| `python which SCons` fails in Stata | Package not on Stata's Python path | Run `pip show scons` and `python set userpath` |

### Git configuration

Files to track:
- `SConstruct`, `SConscript-*`
- `config_project.ini`
- `code/ado/plus/`, `code/ado/personal/` (for reproducible ado environments)

Files to **exclude** (add to `.gitignore`):
```gitignore
config_local.ini
.sconsign.dblite
*.log           # batch Stata logs (if in root)
**/*__pll*      # parallel temp files
```

---

## 16. Advanced / Miscellaneous

### Non-do-file commands

`file_cmd` can be any Stata batch-mode command:

```python
env.StataBuild(
    target   = ['output/report.html'],
    do_file  = 'code/report.dyndoc',
    file_cmd = 'dyndoc',
    params   = ', saving(output/report.html) replace'
)
```

### `content-timestamp-newer` Decider

If users sometimes run do-files *outside* of statacons (e.g., interactively),
the resulting `.dta` will be newer than what statacons knows about. By
default, statacons would re-run the do-file anyway (content changed from its
perspective). The `content-timestamp-newer` decider only rebuilds if a
dependency is *both* different in content *and* newer than all targets:

```python
import pystatacons
env = pystatacons.init_env()
Decider(pystatacons.decider_str_lookup['content-timestamp-newer'])
```

### `SConsignFile`

Specify a custom name/location for the SCons signature database:

```python
SConsignFile("dbs/.sconsignParallel.dblite")
```

Useful when running multiple SConstructs (e.g., a parallel sub-build) to
avoid database conflicts.

### Reading config values in SConstruct

```python
env['CONFIG']['Project']['cache_dir']
env['CONFIG']['Project']['overleaf_dir']
env['CONFIG']['SCons']['use_custom_datasignature']
```

---

*Sources: statacons (Guiteras et al., SJ 2023); project documentation at
https://bquistorff.github.io/statacons/; project wiki at
https://github.com/bquistorff/statacons/wiki.*
