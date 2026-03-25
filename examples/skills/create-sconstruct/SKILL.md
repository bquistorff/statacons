---
name: create-sconstruct
description: Expert workflow for creating, editing, and improving SConstruct and SConscript files for Stata/statacons research projects. Use this skill whenever the user wants to build or edit a statacons build system, set up dependency tracking for a Stata project, encode do-file build order, run scan_project.py or gen_sconstruct.py to auto-generate a SConstruct, write StataBuild tasks, set up config_project.ini or config_local.ini, understand SConstruct conventions, troubleshoot a statacons build, or manage Python scripts as pipeline steps via env.Command (including argparse, sys.executable, the Python scanner, or mixing Python and Stata tasks). If the conversation involves do-files, SConstructs, statacons, SCons + Stata, or SCons + Python pipeline scripts in any way, use this skill.
---

# Create SConstruct for Stata / Statacons Workflows

This skill covers two paths to a working SConstruct:

- **Workflow A (recommended):** Auto-generate a draft via the scanner scripts, then refine it.
- **Workflow B:** Write manually from scratch or heavily edit an existing file.

## Reference files — read when needed

| File | Read when… |
|------|-----------|
| `references/Statacons-habits.md` | Writing style, StataBuild patterns, ado lists, SConscripts, config files |
| `references/Statacons-general.md` | Statacons API, `init_env`, `StataBuild` options, `pystatacons` details |
| `references/SCons-general.md` | Core SCons concepts: DAGs, Glob, Default, content signatures |
| `references/SCons-python.md` | Python tasks via `env.Command`, argparse, `sys.executable`, Python scanner |
| `assets/SConstruct-template.py` | Minimal working template to start from |

Scripts live in `scripts/`:
- `scripts/scan_project.py` — scans a Stata project directory → `scan_results.yaml`
- `scripts/gen_sconstruct.py` — `scan_results.yaml` → `SConstruct.draft`

---

## Workflow A: Auto-generate with the scanner

### Step 1 — Run `scan_project.py`

```bash
python scripts/scan_project.py <project_root> [options]
```

**Before running**, confirm these options with the user:

**Adopath options** (BASE and SITE always excluded):

| Flag | Effect | Default |
|------|--------|---------|
| `--no-personal` | Exclude Stata PERSONAL ado path | *included* |
| `--no-plus` | Exclude Stata PLUS ado path | *included* |
| `--include-oldplace` | Include Stata OLDPLACE ado path | *excluded* |
| `--extra-ado DIR` | Additional ado directory (repeatable) | — |

*Offer to include PERSONAL and PLUS, exclude OLDPLACE unless the user says otherwise.*

**Project ado-file options** (for `code/ado/`):

| Flag | Effect | Default |
|------|--------|---------|
| `--no-ado-root` | Exclude `code/ado/*.ado` (root-level ados) | *included* |
| `--no-ado-subdir NAME` | Exclude named `code/ado/<NAME>/` subdir (repeatable) | *all included* |

*Each subdirectory of `code/ado/` becomes a named dependency group. Offer all groups as separate tracked sets, then let the user opt out of any.*

**Macro expansion options:**

| Flag | Effect |
|------|--------|
| *(default)* | Full Python-side macro resolution + foreach expansion |
| `--no-expand-macros` | Skip all macro expansion; fall back to log-file path lookup, then keep unexpanded macros as-is in the output |

Use `--no-expand-macros` when: the project has complex or deeply nested macros that the scanner can't resolve, but good log files exist from a recent run.

**Do-file filter (fragment mode):**

By default the scanner examines every `code/*.do` task file. Ask the user whether they want to restrict the scan to a specific subset:

> *"Should I scan all do-files in the project (default), or restrict to a specific list? Restricting produces a `SConstructFragment` (instead of `SConstruct`) so no existing build files are overwritten."*

Choices: `Scan all do-files (default)` / `Specify a list of do-files`.

If the user chooses to specify files, ask them to list the do-file names or paths, then pass each one as `--file <path>` to `scan_project.py`. The resulting YAML will be marked `is_fragment: true`, and `gen_sconstruct.py` will automatically use Fragment naming (`SConstructFragment` / `[name]Fragment.SConscript`).

**Other flags:**
- `--out PATH` — output YAML (default: `<project_root>/scan_results.yaml`)
- `--quiet` — suppress the console report
- `--include-testing` — include `testing_*.do` and `_*.do` files (excluded by default)

### Step 2 — Review `scan_results.yaml`

The scanner produces a YAML with one entry per do-file. Each entry has:

```yaml
path: code/dataprep.do
inputs:
  - {path: input/data/raw.dta, source: dofile, confidence: high}
outputs:
  - {path: input/data/cleaned.dta, source: dofile, confidence: high}
depends_on: [code/setup.do]
raw_file_deps: [input/data/raw.dta]  # inputs not produced by any task
unresolved:                           # macros the scanner couldn't expand
  - {raw: '"output/data/`filename'.dta"', line_no: 42}
as_is_inputs: []    # unexpanded-macro inputs (only with --no-expand-macros)
as_is_outputs: []   # unexpanded-macro outputs (only with --no-expand-macros)
conditionals: []    # paths inside if/foreach blocks (verify manually)
```

**Common issues to address before generating:**

| Symptom in YAML | Likely cause | Fix |
|----------------|-------------|-----|
| `outputs: []` or log-only target | Unusual `save`/`export` syntax or macro-wrapped filename | Check the do-file; add the path manually in `outputs:` |
| `depends_on: []` for a task that should chain | DAG linker missed a link (intermediate file path differs) | Add the upstream task to `depends_on:` manually |
| Entries in `unresolved` | Macro not found by scanner | Check the do-file for the macro definition; edit the YAML to move the entry to `inputs:` or `outputs:` |
| Entries in `as_is_inputs/outputs` | `--no-expand-macros` used; log lookup found no match | Expand manually or leave as-is (they appear verbatim in the SConstruct with a TODO comment) |
| Entries in `conditionals` | Path inside `if`/`foreach` block | Verify the dependency is real; if so, the DAG already links it via W3 — no action needed |
| `header_discrepancies` | Mismatch between do-file comment header and scanner findings | Usually benign; resolve if the header is the reliable source |

Edit the YAML freely — it is the user-facing intermediate representation before code generation. Changes here carry through to the SConstruct.

### Step 3 — Run `gen_sconstruct.py`

**Before running**, check whether `SConstruct` or any `*.SConscript` files already exist in the write directory (typically the project root):

```powershell
$writeDir = "<project_root>"
$existing = @(
    if (Test-Path "$writeDir\SConstruct") { "SConstruct" }
) + @(Get-ChildItem "$writeDir\*.SConscript" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Name)
$existing
```

- **If existing files are found:** use `ask_user` to ask whether to proceed in draft mode (write `SConstructDraft` / `[name]Draft.SConscript` alongside the existing files — **this is the default**) or to overwrite the existing files (must be actively chosen). Pass `--draft` to the script if draft mode is selected.
- **If no existing files:** write directly (no `--draft` needed).
- **If the scan was a fragment scan** (YAML has `is_fragment: true`): Fragment naming is applied automatically — no check or prompt needed. `gen_sconstruct.py` will write `SConstructFragment` / `[name]Fragment.SConscript` and refuse to overwrite those if they already exist.

```bash
# draft mode (existing files present, user chose draft — recommended default)
python scripts/gen_sconstruct.py scan_results.yaml --out <project_root> --draft

# overwrite mode (user explicitly chose to overwrite)
python scripts/gen_sconstruct.py scan_results.yaml --out <project_root>

# fragment mode (auto-applied when YAML has is_fragment: true)
python scripts/gen_sconstruct.py scan_results.yaml --out <project_root>
# → writes SConstructFragment, never overwrites SConstruct
```

**Generator flags:**

| Flag | Effect |
|------|--------|
| `-d`, `--draft` | Write `SConstructDraft` / `[name]Draft.SConscript` instead of overwriting `SConstruct` / `[name].SConscript` |
| `-f`, `--file DO_FILE` | Restrict output to specific do-files from the YAML; forces Fragment naming. Use when the user ran a full scan but only wants a fragment at generation time. |
| `--sconscripts` | Also generate one SConscript per task group |
| `--no-track-ado` | Omit ALL external ado groups from `depends=` |
| `--no-track-ado-plus` | Omit only the `ado_plus` group |
| `--no-track-ado-personal` | Omit only the `ado_personal` group |
| `--no-ado-list` | Omit all ado deps entirely |
| `--out DIR` | Output directory (default: project root from YAML) |

Output filenames:
- **Normal mode:** `SConstruct`, `[name].SConscript`
- **Draft mode:** `SConstructDraft`, `[name]Draft.SConscript`
- **Fragment mode:** `SConstructFragment`, `[name]Fragment.SConscript` (never overwrites existing Fragment files)

### Step 4 — Review and finalise the generated SConstruct

Work through the file top to bottom:

1. **Fix `# TODO:` comments** — log-file placeholders mean the scanner found no output; unresolved-macro comments mean targets or deps need manual values.
2. **Verify `target=` lists** — make sure all important outputs (`.dta`, `.ster`, `.tex`, `.pdf`) are listed, not just logs.
3. **Confirm `depends=` chains** — every task that reads another task's output should list that task variable.
4. **Ado groups** — verify which ado lists are appropriate for each task (not all tasks need all groups).
5. **Task order** — tasks should appear in build order (sources before consumers). Reorder if the auto-sort placed them incorrectly.

---

## Workflow B: Manual writing

**Before creating any `SConstruct` or `*.SConscript` file directly** (using the `create` tool), check whether those files already exist in the write directory. If any are found, use `ask_user` to ask whether to write as draft (`SConstructDraft` / `[name]Draft.SConscript` — **default**) or to overwrite the existing files (must be actively chosen).

Read `references/Statacons-habits.md` for the full style guide. Key points:

### Standard SConstruct skeleton

```python
# **** Setup and configuration *****

import pystatacons
env = pystatacons.init_env()

# **** Substance begins        *****

# Ado-file dependency groups
ado_plus     = [f for f in Glob('C:/.../.ado/plus/**/*.ado',     strings=True)]
ado_personal = [f for f in Glob('C:/.../.ado/personal/**/*.ado', strings=True)]
ado_root     = [f for f in Glob('code/ado/*.ado',                strings=True)]
# named subdir groups, e.g.:
# ado_sims = [f for f in Glob('code/ado/policy_simulations/*.ado', strings=True)]

# ---- Dataprep ----

dataprep = env.StataBuild(
    target  = ['input/data/cleaned.dta'],
    source  = ['code/dataprep.do'],
    depends = ado_plus + ado_root + ['input/data/raw.dta'],
)

# ---- Estimation ----

main_model = env.StataBuild(
    target  = ['output/sters/main.ster',
                'output/tab/tex/main-table.tex'],
    source  = ['code/main-model.do'],
    depends = ado_plus + ado_root + [dataprep],
)

# ---- Figures and tables ----

tabfig = env.StataBuild(
    target  = ['output/fig/pdf/main-fig.pdf',
                'output/tab/tex/main-fig-notes.tex'],
    source  = ['code/tabfig.do'],
    depends = ado_plus + ado_root + [main_model],
)

Default([dataprep, main_model, tabfig])
```

### `StataBuild` call rules

- **4-space indent, aligned `=`:** `target  =`, `source  =`, `depends =` (two spaces before `=` for target/source, one for depends — aligns the `=` column).
- **Always `depends=` keyword**, never a separate `Depends()` call.
- **Task variable name** = do-file stem, hyphens → underscores (`main-model.do` → `main_model`).
- **Wrap task variables in `[...]`** when passing to `depends=` (e.g., `[dataprep]`).
- **Don't put temp files** (`temp/`) or log files in `target=` unless the log is the only meaningful output.
- **Section headers** use the banner style: `# ---- Section Name ----`.

### SConscripts (for large or collaborative projects)

When a project has many do-files grouped by analysis phase, split into SConscripts:

```python
# In SConstruct:
Export('env')
SConscript(['analysis/First.SConscript',
            'analysis/Second.SConscript'])
Import('*')
```

Each SConscript uses `Import('env')` at the top and `Export(...)` at the bottom to share task variables with other files. See `references/Statacons-habits.md` §6 for a full multi-SConscript example.

### Config files

- **`config_project.ini`** — committed to the repo; sets `program` (Stata executable), `batchmode`, log dirs, etc.
- **`config_local.ini`** — machine-local overrides, NOT committed. Typically just overrides the Stata executable path.

See `references/Statacons-habits.md` §4 for canonical templates.

---

## Common problems and fixes

| Problem | Fix |
|---------|-----|
| Scanner misses `save` outputs | Macro-wrapped filenames; use `--no-expand-macros` + run with a recent log, or add targets manually to the YAML |
| foreach loop outputs missing | Scanner only expands `foreach VAR in val1 val2` (literal lists); indirect loops via macros need log lookup or manual addition |
| DAG not chaining tasks | Normalise the intermediate file path so producer and consumer agree |
| `ado_plus + [dataprep]` TypeError | Both are SCons node lists — this usually works; if not, wrap in `Flatten([ado_plus, [dataprep]])` |
| Block comments shift line numbers | Update to latest `scan_project.py` (preserves `\n` inside block comments) |
| `StataBuild` re-runs unexpectedly | A file in `depends=` changed content — check ado files or config; use `.sconsign.dblite` deletion to reset |
| Missing targets for tabfig | Common: foreach loop over subsidy levels etc. — add each expanded path to `target=` in the YAML |

---

## Scanner internals (for debugging unresolved macros)

The scanner uses layered resolution:
1. **Command regex** — ~20 Stata I/O patterns extract raw path strings
2. **Macro resolution** — do-file defs → setup files → log-file `local macro = value` lookup
3. **W1 — foreach expansion** — `foreach VAR in val1 val2` → one path per value
4. **W2 — line-aware cutoff** — only uses macro definitions above the reference line (prevents future-definition contamination)
5. **W3 — conditional-path DAG** — paths inside `if`/`foreach` blocks still create DAG edges when the path matches a known producer
6. **D3 — foreach-override retry** — for transitive macro chains (`filename_sim` = `"\`name'-sub\`SUBSIDY'"` inside a foreach), retries resolution with each foreach value combination

With `--no-expand-macros`, layers 2–6 are skipped. The scanner instead calls `_parse_log_for_paths()` on the do-file's log file and matches raw macro-containing paths to log paths by requiring all literal string fragments (non-macro parts) to appear in order in the log path.
