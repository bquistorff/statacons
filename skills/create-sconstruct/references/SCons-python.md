# SCons for Python Workflows

Reference for writing SConstruct/SConscript files that manage Python scripts
as build steps, typically alongside (or instead of) Stata do-files.

Synthesized from:
- SCons User Guide, https://scons.org/doc/production/HTML/scons-user/
- Carpentries SCons novice lesson, https://carpentries-incubator.github.io/scons-novice/
- Existing project SConstructs in `W:\`

---

## 1. Core Mechanism: `env.Command`

Python scripts are run as build tasks via `env.Command`. SCons has no built-in
"run a Python script" builder, so `env.Command` is the workhorse:

```python
import os
env = Environment(ENV=os.environ.copy())

env.Command(
    target = ['output/data/result.csv'],
    source = ['code/analysis.py', 'input/data/raw.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

Key points:
- `target` — file(s) the script produces.
- `source` — the Python script **and** its input files. Listing the script as
  a source means that changing the script triggers a rebuild (not just the data).
- `action` — shell command string. SCons substitutes `${...}` variables at
  build time (see Section 2).

### Statacons projects

In a mixed Stata + Python project using pystatacons, the environment is created
differently (pystatacons wraps it), but `env.Command` is still available and
works identically:

```python
import pystatacons
env = pystatacons.init_env()

env.Command(
    target = ['output/data/result.csv'],
    source = ['code/analysis.py', 'input/data/raw.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

---

## 2. Substitution Variables in Action Strings

Inside action strings, SCons substitutes `${...}` at build time:

| Variable | Expands to |
|----------|-----------|
| `${TARGET}` | First (or only) target |
| `${TARGETS}` | All targets (space-separated) |
| `${SOURCE}` | First source |
| `${SOURCES}` | All sources (space-separated) |
| `${SOURCES[0]}` | First source (Python-style indexing) |
| `${SOURCES[1]}` | Second source |
| `${SOURCES[1:]}` | All sources except the first |
| `${SOURCES[-1]}` | Last source |

### Placing the script in sources

The standard pattern puts the script **first** in `source` so its index is
predictable:

```python
env.Command(
    target = ['output/data/out.csv'],
    source = ['code/myscript.py', 'input/data/in.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

Alternatively, put data files first and the script last (`${SOURCES[-1]}`),
matching the Carpentries convention:

```python
env.Command(
    target = ['output/data/out.csv'],
    source = ['input/data/in.csv', 'code/myscript.py'],
    action = ['python ${SOURCES[-1]} ${SOURCES[0]} ${TARGET}'],
)
```

Pick one convention and apply it consistently within a project.

---

## 3. Multiple Inputs and Outputs

### Multiple inputs

```python
env.Command(
    target = ['output/data/merged.csv'],
    source = ['code/merge.py',
              'output/data/step1.csv',
              'output/data/step2.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]} ${SOURCES[2]} ${TARGET}'],
)
```

Or pass all data sources as a slice:

```python
# script expects: python merge.py out.csv in1.csv in2.csv ...
action = ['python ${SOURCES[0]} ${TARGET} ${SOURCES[1:]}']
```

### Multiple outputs from one script

List all outputs in `target`. SCons will rebuild if any are stale:

```python
env.Command(
    target = ['output/fig/pdf/figure1.pdf',
              'output/tab/tex/table1.tex'],
    source = ['code/tabfig.py', 'output/data/estimates.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]}'],
)
```

The script is responsible for writing all listed targets. If it does not
produce one of them, SCons will report an error on the next build.

---

## 4. Handling Many Outputs

When a script produces many output files, three strategies are available:

- **A — List comprehensions** (preferred when outputs are enumerable)
- **B — Natural sentinel** (one real output represents the whole step)
- **C — Marker file** (last resort when outputs are determined at runtime)

See **`Statacons-general.md` § 14 "Handling many outputs: three strategies"**
for full guidance and a decision table. That section uses Stata examples but
the logic is identical for Python scripts.

### Python-specific implementation notes for Strategy C

Writing the marker from inside the Python script avoids shell-quoting issues
(and the Windows `cmd /c "... && echo done > target"` complication):

```python
# at end of import-tiles.py
with open(sentinel_path, 'w') as f:
    f.write('done\n')
```

SConstruct:

```python
import_tiles = env.Command(
    target  = ['output/data/tiles/tiles-import.done'],
    source  = ['code/tiles/import-tiles.py',
               'input/data/tiles/raw.zip'],
    action  = ['${PYTHON} ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

The script receives the sentinel path as `sys.argv[2]` / `${TARGET}` and
writes it only after all real work is complete. If the script raises an
exception, the sentinel is not written and SCons will retry on the next build.

Downstream tasks that do not pass the sentinel as an argument to the script
should still list it (or the task node) in `source` / `depends` so SCons
enforces ordering:

```python
merge = env.Command(
    target  = ['output/data/merged.csv'],
    source  = ['code/merge.py',
               'output/data/tiles/tiles-import.done',
               'output/data/other.csv'],
    action  = ['${PYTHON} ${SOURCES[0]} ${SOURCES[2]} ${TARGET}'],
)
```

`${SOURCES[2]}` skips the sentinel (index 1) in the argument list — it tracks
the dependency but does not pass the `.done` path to the merge script.

---

## 5. Script Dependencies Only (No Data Input)

Sometimes a script reads inputs via hardcoded paths rather than arguments.
Include the script plus any input files in `source`; SCons will track them
even if the action string does not use `${SOURCES[1:]}`:

```python
task = env.Command(
    target  = ['output/data/result.csv'],
    source  = ['code/analysis.py',
               'input/data/config.yaml',
               'input/data/raw.csv'],
    action  = ['python ${SOURCES[0]}'],
)
```

This is a "false" source from the script's perspective (it doesn't receive
them as arguments), but a "true" dependency from SCons's perspective — any
change to those files will trigger a rebuild.

---

## 6. Using `sys.argv` in Python Scripts

For scripts that accept command-line arguments, `sys.argv` is the standard
Python mechanism:

```python
# code/analysis.py
import sys
import pandas as pd

input_path  = sys.argv[1]
output_path = sys.argv[2]

df = pd.read_csv(input_path)
# ... process ...
df.to_csv(output_path, index=False)
```

Corresponding SConstruct:

```python
env.Command(
    target = ['output/data/result.csv'],
    source = ['code/analysis.py', 'input/data/raw.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

---

## 7. Using `argparse` in Python Scripts (Recommended)

For scripts that accept path arguments, `argparse` is preferred over
`sys.argv` because it produces self-documenting action strings, allows
arguments in any order, and provides `--help` automatically.

### Why this matters for SCons

SCons tracks what a task reads and writes through `source=` and `target=`.
If a script ignores those and computes its own paths at runtime
(e.g. `Path.cwd() / "output" / "result.csv"`), the declared graph and the
actual I/O are disconnected — SCons may think a task is up-to-date while
the script wrote to a different location. Having scripts accept path
arguments lets the SConscript pass `${SOURCES[...]}` and `${TARGETS[...]}`
directly, so the declared graph and actual I/O are the same thing.

### Basic pattern

```python
# code/analysis.py
import argparse, pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('--input',  required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()

df = pd.read_csv(args.input)
df.to_csv(args.output, index=False)
```

Corresponding action string:

```python
action = ['${PYTHON} ${SOURCES[0]} --input ${SOURCES[1]} --output ${TARGET}']
```

Named flags make action strings self-documenting and are less fragile than
positional `sys.argv` arguments.

### Providing defaults for standalone use

Scripts used both from SCons and interactively should default to the standard
project paths so they can still be run from the terminal without arguments:

```python
parser.add_argument(
    '--input',
    default='input/data/spotChecks/raw/gpkg/combined-plots-raw.gpkg',
    help='Input GeoPackage (default: %(default)s)',
)
```

When run standalone the defaults apply; when run via SCons the SConscript
overrides them with `${SOURCES[...]}` / `${TARGETS[...]}`.

### Decision guide: argparse vs sys.argv vs hardcoded

| Situation | Recommended approach |
|-----------|---------------------|
| Writing a new script for a pipeline | argparse with defaults |
| Retrofitting an existing script | argparse if straightforward, else leave hardcoded (§5) |
| Very simple script, two arguments | `sys.argv` acceptable (§6) |
| Script's output paths vary by run | argparse required |

---

## 8. Python Action Functions (In-Process Execution)

Instead of a shell command string, the action can be a Python function defined
inside the SConstruct. This runs in the same Python process as SCons — no
subprocess overhead, no shell quoting issues:

```python
import shutil

def copy_and_log(target, source, env):
    shutil.copy(str(source[0]), str(target[0]))
    print(f"Copied {source[0]} -> {target[0]}")
    return None   # return None or 0 on success; non-zero = failure

env.Command(
    target = ['output/data/copy.csv'],
    source = ['input/data/raw.csv'],
    action = copy_and_log,
)
```

The function signature must be `f(target, source, env)`:
- `target` — list of SCons Node objects (convert to string with `str(...)`)
- `source` — list of SCons Node objects
- `env`    — the construction environment

Return `None` or `0` for success; return a non-zero integer or raise an
exception to signal failure.

### Adding a display message

Wrap the function in `Action` to control what SCons prints:

```python
from SCons.Script import Action

act = Action(copy_and_log, cmdstr="Copying ${SOURCE} -> ${TARGET}")
env.Command(target=[...], source=[...], action=act)
```

---

## 9. Pseudo-Builder for Python Scripts

For projects where many tasks call Python scripts in the same style, encapsulate
the pattern as a pseudo-builder added to the environment. This keeps SConstruct
files clean and enforces consistent conventions:

```python
def python_build(env, target, source, extra_deps=None, extra_args=''):
    """Run a Python script with standard argument conventions.

    source[0] : the Python script
    source[1:]: data input files passed as positional arguments
    extra_deps: additional dependencies that are NOT passed as arguments
                (e.g. helper modules, config files)
    extra_args: additional argument string appended to the action
    """
    deps = list(source)
    if extra_deps:
        deps = deps + list(extra_deps)
    return env.Command(
        target = target,
        source = deps,
        action = [f'python ${{SOURCES[0]}} ${{SOURCES[1:{len(source)}}]}} {extra_args}'],
    )

env.AddMethod(python_build, 'PythonBuild')
```

Usage:

```python
task = env.PythonBuild(
    target     = ['output/data/result.csv'],
    source     = ['code/analysis.py', 'input/data/raw.csv'],
    extra_deps = ['code/utils/helpers.py'],
)
```

---

## 10. Task Variable Naming and Formatting Conventions

Follow the same conventions as for Stata tasks (see `Statacons-habits.md`):

```python
# 4-space indent; = signs aligned
dataprep = env.Command(
    target  = ['output/data/clean.csv'],
    source  = ['code/dataprep.py', 'input/data/raw.csv'],
    action  = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)

estimation = env.Command(
    target  = ['output/data/estimates.csv'],
    source  = ['code/estimation.py', 'output/data/clean.csv'],
    action  = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

- Name task variables by role (`dataprep`, `estimation`, `tabfig`) — no
  `cmd_` prefix.
- Pass the task node variable as a dependency to downstream tasks, just as
  with `StataBuild` tasks:

```python
tabfig = env.Command(
    target  = ['output/fig/pdf/fig1.pdf'],
    source  = ['code/tabfig.py'],
    action  = ['python ${SOURCES[0]}'],
    # implicit: depends on estimation's targets because estimation node is listed
)
Depends(tabfig, estimation)   # or: list estimation targets in source
```

---

## 11. Mixing Python and Stata Tasks

Python tasks (`env.Command`) and Stata tasks (`env.StataBuild`) interoperate
naturally — both return SCons Node objects that can be passed as dependencies
to each other:

```python
import pystatacons
env = pystatacons.init_env()

# Stata dataprep
dataprep = env.StataBuild(
    target  = ['output/data/clean.dta'],
    source  = 'code/dataprep.do',
    depends = ['input/data/raw.dta'],
)

# Python estimation step that reads the Stata output
estimation = env.Command(
    target  = ['output/data/estimates.csv'],
    source  = ['code/estimation.py', 'output/data/clean.dta'],
    action  = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)

# Stata tabfig that reads Python output
tabfig = env.StataBuild(
    target  = ['output/tab/tex/table1.tex'],
    source  = 'code/tabfig.do',
    depends = [estimation, 'output/data/clean.dta'],
)
```

SCons correctly resolves the full dependency chain across both step types.

---

## 12. Dependency on Python Helper Modules

If a script imports a local helper module, list that module as a dependency
so SCons rebuilds when the helper changes:

```python
estimation = env.Command(
    target  = ['output/data/estimates.csv'],
    source  = ['code/estimation.py',
               'code/utils/model_helpers.py',   # helper; not passed as arg
               'output/data/clean.csv'],
    action  = ['python ${SOURCES[0]} ${SOURCES[-1]} ${TARGET}'],
)
```

Here `${SOURCES[-1]}` is the data file (last in list); the helper is in the
middle — it is tracked as a dependency but not referenced in the action string.

---

## 13. Glob-Driven Python Tasks

Use `Glob` to build task lists dynamically from a directory of input files:

```python
import pathlib

raw_csvs = Glob('input/data/regions/*.csv', strings=True)

processed = [
    env.Command(
        target = ['output/data/regions/' + pathlib.Path(f).name],
        source = ['code/process_region.py', f],
        action = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
    )
    for f in raw_csvs
]

# combine into one alias
env.Alias('process_regions', processed)
```

### Caveats

`Glob` has two important limitations (see also `SCons-general.md` §11 for
the general discussion):

1. **Silent missing-file failure.** If an expected input file is absent,
   Glob silently omits it and the build proceeds with fewer inputs than
   expected — no error is raised. An explicit list would cause SCons to
   error on the missing file.

2. **Cannot reference files that do not yet exist.** Glob matches only
   files present on disk at SCons evaluation time. Never use Glob for
   `target=` lists (outputs don't exist before the build runs).

3. **Startup overhead.** Glob over a very large directory (e.g., ~1,900
   KML files) is evaluated at every statacons invocation, adding measurable
   startup latency. If this becomes a problem, consider Strategy C (marker
   file, `SCons-general.md` §14) with a single representative dependency
   instead.

**When Glob is justified:** the input file set is too large or too
irregularly named to enumerate with list comprehensions. Document the
silent-failure risk with a comment in the SConscript.

---

## 14. Detecting the Python Executable

Hard-coding `python` in action strings may invoke the wrong Python
(e.g., system Python instead of a conda environment). Use `sys.executable`
to capture the interpreter that is running SCons itself.

### Set `env['PYTHON']` once in the SConstruct — not in each SConscript

The correct place to set this is in the root `SConstruct`, immediately after
`init_env()`, so that every SConscript that imports `env` automatically
inherits `${PYTHON}`:

```python
# SConstruct
import pystatacons
import sys

env = pystatacons.init_env()
env['PYTHON'] = sys.executable   # inherited by all SConscripts via Export('env')

Export('env')
SConscript([...])
```

Then in any SConscript, action strings can simply use `${PYTHON}`:

```python
# any .SConscript
Import('env')

task = env.Command(
    target  = ['output/data/result.csv'],
    source  = ['code/analysis.py', 'input/data/raw.csv'],
    action  = ['${PYTHON} ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

Setting `env['PYTHON']` inside a SConscript also works but is repetitive
and easy to forget. Setting it once in the SConstruct is the robust pattern.

### Fallback: local Python variable (for one-off use)

If you need the interpreter path in just one place without modifying the
environment, a local variable works — but the double-brace escaping required
in f-strings is ugly and error-prone:

```python
import sys
PYTHON = sys.executable

action = [f'{PYTHON} ${{SOURCES[0]}} ${{SOURCES[1]}} ${{TARGET}}']
```

Prefer the `env['PYTHON']` approach for any project with Python tasks.

---

## 15. The Built-in Python Scanner

SCons ships with a Python source scanner (available since SCons 4.0) that
automatically detects implicit dependencies between local `.py` files. Load it
with:

```python
env.Tool('python')
```

### What it does

When any `.py` file appears in a `source=` list, the scanner reads that file,
finds all `import` and `from ... import ...` statements, and resolves them to
`.py` files on disk by searching:

1. The source file's own directory
2. Entries in the `PYTHONPATH` environment variable

It handles dotted imports (`import x.y.z`), relative imports (`from . import x`,
`from ..foo import y`), comma-separated `from` imports, and aliased imports.
It is recursive — it also scans imported files.

**It does NOT detect:**
- Third-party or stdlib packages (geopandas, numpy, etc.) — by design, these
  are in site-packages, not on PYTHONPATH
- Data file dependencies (`.gpkg`, `.csv`, `.kml`, etc.)
- Dynamic imports (`__import__()`, `importlib.import_module()`)
- Imports inside strings or generated with `eval()`

### When to use it vs. explicit `source=`

| Dependency type | Python scanner | Explicit `source=` |
|---|---|---|
| Script imports a **local helper module** | ✅ Auto-detects | Must list manually |
| Scripts share a **local package** (`__init__.py`) | ✅ Recursive auto-detect | Tedious to maintain |
| Dependency is a **data file** (`.gpkg`, `.csv`) | ❌ Invisible | ✅ Always explicit |
| Dependency is a **third-party package** | ❌ Not tracked | ❌ Not practical |

The two approaches are complementary: `source=` handles data dependencies (which
the scanner cannot see); the scanner handles Python module dependencies (which
`source=` can miss when local modules evolve).

### Recommendation

**Always add `env.Tool('python')`** to any SConscript that manages Python tasks.
It has no effect when scripts are self-contained (nothing for it to find), and
activates automatically the moment shared local modules appear. There is no cost
to loading it when it finds nothing.

```python
# SConscript (or SConstruct)
Import('env')
env.Tool('python')   # enable Python import scanner

import sys
env['PYTHON'] = sys.executable
```

### Current-project note (cropResidueBurning)

The `spotChecksPython.SConscript` scripts are self-contained (no local module
imports), so the scanner adds nothing today. All inter-script dependencies are
data files handled by explicit `source=` listing. If a shared helper module
(e.g., `code/py/shared/geo_utils.py`) is introduced later, the scanner will
pick it up automatically once `env.Tool('python')` is present.

---

## 16. Key Patterns Summary

| Situation | Pattern |
|-----------|---------|
| Single-input, single-output script | `env.Command` with `python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}` |
| Script with named arguments | `python ${SOURCES[0]} --input ${SOURCES[1]} --output ${TARGET}` |
| Script produces many files | Sentinel file pattern (script writes `.done` marker at end) |
| Script reads inputs internally (not as args) | List inputs in `source`; use `python ${SOURCES[0]}` only in action |
| Script depends on helper module | Include helper in `source`; skip it in action string with indexing |
| Python task → Stata task | Pass Python Command node in `depends=` of `StataBuild` |
| Stata task → Python task | Pass StataBuild node in `source=` or via `Depends()` in Command |
| Many files of same type | `Glob` + list comprehension |
| Script depends on local helper module (auto-detect) | Add `env.Tool('python')` — scanner finds local `.py` imports automatically |
| Ensure correct Python | Use `sys.executable` or `env['PYTHON'] = sys.executable` |

---

## 17. Debugging Checklist (Python-specific)

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Script runs but target not created | Script exits without writing target | Add error handling; check script returns 0 |
| Target not rebuilt after helper module edited | Helper not listed in `source` | Add helper `.py` to `source=` list |
| Wrong Python version runs | `python` resolves to system Python | Use `sys.executable` in action string |
| `${SOURCES[n]}` passes wrong file | Indexing off | Print `${SOURCES}` in action; recount |
| Sentinel written even on error | `&&` not used | Use `python script.py && echo done > ${TARGET}` |
| Downstream Stata task does not rebuild | Python task node not in `depends=` | Pass Python task variable to `depends=` |

---

*Sources: SCons User Guide (scons.org/doc/production/HTML/scons-user/),
Carpentries SCons Novice Lesson (CC-BY 4.0),
in-project SConstruct files in `W:\`.*
