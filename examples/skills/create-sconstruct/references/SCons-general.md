# SCons General Reference

Synthesized from the Carpentries SCons novice lesson
(https://carpentries-incubator.github.io/scons-novice/).
Intended as a reference for writing SConscript files; not a tutorial.

---

## 1. What SCons Is

SCons is a Python-based build tool that executes commands to transform input
files into output files and tracks which outputs need to be rebuilt when inputs
change. Compared to a shell script, SCons:

- records the dependency graph explicitly (what files are needed to build what),
- rebuilds only the targets that are out-of-date,
- uses **content signatures** (md5 hashes) rather than timestamps by default,
  so a target is not rebuilt if its sources have changed but its content would
  be identical to the existing target.

SCons uses Python as its configuration language, so any valid Python is
available inside SConscript files.

Other build tools exist (GNU Make, doit, Apache Ant, nmake). The concepts
below are largely universal.

---

## 2. Core Concepts

| Term | Meaning |
|------|---------|
| **Target** | File (or directory) to be created or updated |
| **Source** / **Dependency** | File(s) needed to build the target |
| **Action** | Shell command(s) that create the target from the sources |
| **Task** | The combination of target(s), source(s), and action(s) |
| **Content signature** | md5 hash of file content; used to decide if a target is stale |
| **Incremental build** | Rebuilding only stale targets, not the whole pipeline |
| **False dependency** | A dependency that does not actually affect the target's content — avoid these |

Dependencies must form a **directed acyclic graph** (DAG). A target cannot
depend (directly or transitively) on itself.

---

## 3. SConscript Files

### 3.1 File naming

- `SConstruct` — conventional name for the **root** configuration file; SCons
  looks for this by default.
- `SConscript` — conventional name for secondary configuration files included
  from `SConstruct`.
- Any filename works; use `--sconstruct=MyFile` to point SCons at a
  non-default root file.
- The `.scons` extension can be used for clarity (e.g., `install.scons`).

### 3.2 Construction environment

Every task is attached to a **construction environment** (`env`). Multiple
environments can coexist in one project (e.g., for mutually exclusive
toolchains). For most workflows, one environment inherited from the shell is
sufficient:

```python
import os
env = Environment(ENV=os.environ.copy())
```

`ENV=os.environ.copy()` passes the active shell environment (PATH, conda
activation, etc.) into SCons. SCons does **not** inherit the shell environment
automatically.

---

## 4. Defining Tasks with `env.Command`

```python
env.Command(
    target=["output.dat"],
    source=["input.txt"],
    action=["python myscript.py input.txt output.dat"],
)
```

- `target`, `source`, and `action` accept a **string or list of strings**.
- Multiple actions execute in order, like a shell recipe.
- The task tells SCons: *to build `output.dat` from `input.txt`, run this
  command*.

### Running SCons

```bash
scons            # build all default targets
scons -Q         # suppress status messages (quiet)
scons target.dat # build a specific target by name
scons --clean    # remove all default targets
scons . --clean  # remove all targets (the '.' alias = all targets)
scons target.dat --clean  # remove one specific target
scons --dry-run  # show what would be run without running it
scons --debug=explain  # explain why each target would be rebuilt
```

### Up-to-date messages

| Message | Meaning |
|---------|---------|
| `` `.' is up to date `` | All targets are current |
| `` `target' is up to date `` | Specific target is current |
| `Nothing to be done for 'x'` | File exists but no task defines it |

---

## 5. Special Substitution Variables

Inside action strings, SCons substitutes `${...}` placeholders at build time:

| Variable | Expands to |
|----------|-----------|
| `${TARGET}` | The first (or only) target of the current task |
| `${TARGETS}` | All targets of the current task |
| `${SOURCE}` | The first source of the current task |
| `${SOURCES}` | All sources of the current task (space-separated) |
| `${SOURCES[0]}` | First source (Pythonic zero-based indexing) |
| `${SOURCES[1]}` | Second source |
| `${SOURCES[1:]}` | All sources except the first (slice) |
| `${SOURCES[-1]}` | Last source (negative indexing) |

Custom keyword arguments passed to `env.Command` are also available:

```python
env.Command(
    target=["out.dat"],
    source=["in.txt", "script.py"],
    action=["${language} ${SOURCES[-1]} ${SOURCES[0]} ${TARGET}"],
    language="python",
)
```

---

## 6. Aliases and Default Targets

### `env.Alias`

Groups multiple targets under a convenient name:

```python
env.Alias("dats", ["isles.dat", "abyss.dat", "last.dat"])
```

```bash
scons dats        # equivalent to: scons isles.dat abyss.dat last.dat
scons dats --clean
```

### `env.Default`

Restricts which targets are built when `scons` is called with no arguments
(otherwise all targets are built by default):

```python
env.Default(["results.txt"])
```

`Default` does not affect explicit target requests — `scons dats` still works.

---

## 7. Content Signatures vs Timestamps

SCons uses **md5 content signatures** by default. Key implications:

- `touch file.txt` does **not** trigger a rebuild (timestamp changes, content
  does not).
- Appending a blank line (`echo "" >> file.txt`) **does** trigger a rebuild.
- If an intermediate target is rebuilt but its content is unchanged, downstream
  targets are **not** rebuilt. This stops pipelines early when intermediate
  outputs are stable — valuable for long-running tasks.
- SCons also tracks **action signatures**: changing the action string (e.g.,
  adding a flag) triggers a rebuild even if sources are unchanged.

To use timestamp-based tracking instead (Make-style), configure the
decider explicitly (not covered in the novice lesson).

---

## 8. Dependencies on Scripts

Output files depend on the **scripts** that produce them, not just the input
data. If `countwords.py` changes, `.dat` files should be rebuilt:

```python
env.Command(
    target=["isles.dat"],
    source=["books/isles.txt", "countwords.py"],
    action=["python countwords.py ${SOURCES[0]} ${TARGET}"],
)
```

Adding `countwords.py` as a second source means:
- a change to `countwords.py` triggers a rebuild of `isles.dat`,
- `${SOURCES[0]}` still refers only to `books/isles.txt`.

### Transitive dependencies

If A depends on B and B depends on C, changing C triggers an update to B and
then potentially to A. SCons handles the full chain automatically, but will stop
early if B's content is unchanged after rebuild (content-signature behaviour).

### Avoid false dependencies

Do not list files as sources if they do not actually affect the target's content.
Listing `testzipf.py` as a source of `results.txt` when the action is
`python testzipf.py ${SOURCES} > ${TARGET}` causes `testzipf.py` to be passed
as a data argument to itself — a bug, not a feature. Use indexing
(`${SOURCES[0]}`, `${SOURCES[1:]}`) to disambiguate roles.

---

## 9. Builders and Pseudo-Builders

### 9.1 Builders

A `Builder` encapsulates a reusable action pattern, analogous to Make pattern
rules. Create one, then add it to the environment:

```python
count_words_builder = Builder(
    action=["python ${SOURCES[-1]} ${SOURCES[0]} ${TARGET}"],
)
env.Append(BUILDERS={"CountWords": count_words_builder})
```

Use it like a built-in builder:

```python
env.CountWords(
    target=["isles.dat"],
    source=["books/isles.txt", "countwords.py"],
)
```

### 9.2 Pseudo-builders

Pseudo-builders are ordinary Python functions added to the environment with
`env.AddMethod`. They are more verbose than `Builder` but far more flexible —
they can accept arbitrary arguments, compute paths, loop over lists, etc.:

```python
import pathlib

def count_words(env, data_file, language="python", count_source="countwords.py"):
    data_path = pathlib.Path(data_file)
    text_file = pathlib.Path("books") / data_path.with_suffix(".txt")
    return env.Command(
        target=[data_file],
        source=[text_file, count_source],
        action=["${language} ${count_source} ${SOURCES[0]} ${TARGET}"],
        language=language,
        count_source=count_source,
    )

env.AddMethod(count_words, "CountWords")
```

Call as:

```python
env.CountWords("isles.dat")
```

The `env` parameter is injected automatically when called via `env.CountWords`;
do not pass it explicitly.

### 9.3 Dynamic targets with `COMMAND_LINE_TARGETS`

To handle targets not pre-defined in the SConstruct:

```python
for target in COMMAND_LINE_TARGETS:
    if pathlib.Path(target).suffix == ".dat":
        env.CountWords(target)
```

```bash
scons sierra.dat   # triggers the pseudo-builder for sierra.dat
```

---

## 10. Variables (Configuration Constants)

Python variables defined at the top of an SConstruct file (or in an imported
module) serve as configuration constants:

```python
COUNT_SOURCE = "countwords.py"
LANGUAGE     = "python"
ZIPF_SOURCE  = "testzipf.py"
```

- All-caps names indicate constants (PEP 8 convention).
- Reference them in action strings via SCons substitution syntax
  `${variable_name}` when passed as keyword arguments to `env.Command`.
- Keep SConstruct clean: move builders, pseudo-builders, and constants into a
  separate `.py` module, then import it:

```python
from scons_lesson_configuration import *
```

A wildcard import merges the module namespace into the SConstruct namespace; be
careful not to redefine names from the module.

---

## 11. Glob and List Functions

### `Glob`

`SCons.Script.Glob` returns a list of SCons file nodes matching a pattern:

```python
import SCons.Script
TEXT_FILES = SCons.Script.Glob("books/*.txt")
```

Inside `SConstruct`, `Glob` is available without the module prefix. Inside
imported Python modules (`.py` files), the module prefix is required.

### Caveats: prefer list comprehensions when files are enumerable

`Glob` has two important limitations compared to explicit list comprehensions:

1. **Silent missing-file failure.** Glob matches only files that *exist* at
   the time SCons runs. If an expected input file is absent, Glob silently
   omits it and proceeds — SCons never raises an error. A list comprehension
   that names the file explicitly will cause SCons to error if the file is
   missing, which is almost always the more useful behaviour.

2. **Cannot reference files that do not yet exist.** This matters for
   `target=` lists: files that a build step will *create* do not exist before
   the build, so Glob cannot find them. Always use explicit lists or list
   comprehensions for targets.

**Prefer list comprehensions whenever the file names are enumerable:**

```python
# preferred: errors if any file is absent
wage_data = ["input/wagedata" + n + ".xlsx" for n in ["1","2","3","4","5"]]

# acceptable only when the full set of files cannot be predicted in advance
wage_data = Glob("input/wagedata[1-5].xlsx")
```

Reserve `Glob` for cases where the complete set of input files genuinely
cannot be enumerated in advance — for example, a directory of ~1,000+
user-uploaded files with unpredictable names. Even then, document the
silent-failure risk in a comment.

### List comprehensions for derived file lists

```python
import pathlib
DATA_FILES = [
    pathlib.Path(str(f)).with_suffix(".dat").name
    for f in TEXT_FILES
]
```

Pass lists directly to pseudo-builders and `Alias`:

```python
env.CountWords(DATA_FILES)
env.Alias("dats", DATA_FILES)
```

### Custom command-line options

```python
AddOption(
    "--variables",
    action="store_true",
    default=False,
    help="Print variable values and exit (default: '%default')",
)
if GetOption("variables"):
    print(f"DATA_FILES: {DATA_FILES}")
    Exit(0)   # 0 = success
```

- `AddOption` / `GetOption` follow the Python `optparse` interface.
- `Exit(0)` halts configuration immediately (no build phase).
- `print` writes to STDOUT (the terminal).
- `Execute(cmd)` runs a shell command immediately during configuration
  (not as a task).

---

## 12. Self-Documentation

SCons provides `--help` (custom help) and `-H` (SCons built-in help).

### Basic `Help` call

```python
env.Help("\n\nDefault Targets:\n  results.txt\n\nAliases:\n  dats",
         append=True, keep_local=True)
```

`append=True` appends to SCons's own help text.
`keep_local=True` shows custom options before the SCons options.

### Dynamic help from `DEFAULT_TARGETS` and `default_ans`

```python
from SCons.Script import DEFAULT_TARGETS
from SCons.Node.Alias import default_ans
```

- `DEFAULT_TARGETS` — list of SCons node objects set by `env.Default(...)`.
- `default_ans` — dict-like object of all defined aliases.

Build the help message after all targets and aliases are defined, then call
`SCons.Script.Help(message, append=True, keep_local=True)`. This way, adding or
removing targets automatically updates `--help` output.

---

## 13. Key Patterns Summary

```python
import os
import pathlib
from my_module import *          # constants, pseudo-builders

# Environment
env = Environment(ENV=os.environ.copy())
env.AddMethod(my_pseudo_builder, "BuilderName")

# Tasks
env.Command(
    target=["out.dat"],
    source=["in.txt", "script.py"],
    action=["${lang} ${SOURCES[-1]} ${SOURCES[0]} ${TARGET}"],
    lang="python",
)

# Glob-driven tasks
FILES = [pathlib.Path(str(f)).with_suffix(".dat").name
         for f in Glob("raw/*.txt")]
env.BuilderName(FILES)

# Aliases and defaults
env.Alias("outputs", FILES)
env.Default(["results.txt"])

# Self-doc (must come after all Default / Alias calls)
project_help(help_content)

# Dynamic targets
for t in COMMAND_LINE_TARGETS:
    if pathlib.Path(t).suffix == ".dat":
        env.BuilderName(t)
```

---

## 14. Handling Many Outputs: Three Strategies

When a single task produces many output files, three strategies are available.
The right choice depends on whether the full set of outputs is predictable and
enumerable before the build runs.

### Strategy A — Enumerate targets with list comprehensions (preferred)

Use when the output filenames follow a predictable pattern. SCons has full
visibility into the dependency graph and can detect if any individual target
is missing or stale.

```python
# one file per combination of two parameter dimensions
results_targets = [
    'output/' + method + '_' + spec + '.dat'
    for method in ['ols', 'iv']
        for spec in ['baseline', 'extended', 'robust']
]

estimation = env.Command(
    target = results_targets,
    source = ['code/estimate.py', 'input/data/clean.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]}'],
)
```

Derive sub-lists from existing ones rather than re-enumerating:

```python
table_notes = [t.replace('.tex', '-notes.tex') for t in table_targets]
```

**This is the preferred strategy** whenever the naming pattern is regular
enough to express in Python.

### Strategy B — Natural sentinel (one real output represents the step)

Use when the script produces many intermediate outputs but ultimately produces
one authoritative final output that downstream tasks consume. Declare only
that final output as the target.

```python
# script writes one figure per region, then combines into a single PDF
combine_figs = env.Command(
    target = ['output/fig/all-regions.pdf'],
    source = ['code/combine.py', 'input/data/regions.csv'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

**Trade-off:** SCons does not know about the intermediate files. If one is
deleted, SCons will not rebuild unless the declared target is also stale. Only
use this when the declared target genuinely represents full completion of the
step.

### Strategy C — Sentinel marker file (last resort)

Use when the set of output files is determined at runtime and cannot be
enumerated in advance (e.g., one file per record found in the input data).
The script writes a small marker file after all real work is complete.

```python
import_data = env.Command(
    target = ['output/data/import.done'],
    source = ['code/import.py', 'input/data/raw.zip'],
    action = ['python ${SOURCES[0]} ${SOURCES[1]} ${TARGET}'],
)
```

The script writes the marker at the very end (after all outputs are written),
so the marker is absent if the script fails partway through. Downstream tasks
depend on the marker to enforce ordering, but typically do not pass it as an
argument to their own scripts.

**Trade-off:** SCons tracks only the marker. A corrupted or missing output
file will not trigger a rebuild. Use only when Strategies A and B are not
feasible.

### Choosing a strategy

| Situation | Recommended strategy |
|-----------|----------------------|
| Outputs follow a predictable naming pattern | **A** — list comprehension |
| Many intermediates + one authoritative final output | **B** — natural sentinel |
| Outputs not enumerable in advance (runtime-determined) | **C** — marker file |

---

## 15. Making Scripts Accept Path Arguments

Scripts called via `env.Command` should accept their input and output paths
as arguments (rather than computing them with hardcoded logic) so that SCons's
declared `source=` and `target=` lists match what the script actually reads
and writes. When they do not match, SCons may silently track the wrong files.

For Python-specific guidance (argparse, sys.argv, providing defaults for
standalone use, decision guide), see **`SCons-python.md` §7**.

---

## 16. Debugging Checklist

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Target not rebuilt after source edit | Using `touch` (content unchanged) | Actually modify file content |
| Unexpected rebuild | Action string changed | Check for whitespace or quoting differences |
| Script change not triggering rebuild | Script not listed as source | Add script to `source=` list |
| `${SOURCES}` passes unwanted files to script | Script and data mixed in sources | Use `${SOURCES[0]}` / `${SOURCES[1:]}` indexing |
| Task defined but never runs | Not in default target list and not requested explicitly | Add to `env.Default` or request by name |
| Module variable not found in SConstruct | Forgot `from module import *` or name collision | Check imports; avoid name clashes |

---

*Source: Carpentries SCons Novice Lesson (CC-BY 4.0),
https://carpentries-incubator.github.io/scons-novice/*
