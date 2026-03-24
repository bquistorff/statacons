# SConstruct Template — Stata / Statacons
#
# Copy this file to your project root as `SConstruct`.
# Adjust paths, task names, and dependency groups for your project.
# Reference: rpg_my_copilot/create-sconstruct/references/Statacons-habits.md

# **** Setup and configuration *****

import pystatacons
import sys

env = pystatacons.init_env()

# If the project includes Python script tasks (env.Command), set PYTHON once
# here so every SConscript inherits ${PYTHON} via the exported env.
# Remove this line if the project has no Python tasks.
env['PYTHON'] = sys.executable

# **** Substance begins        *****

# ---------------------------------------------------------------------------
# Ado-file dependency groups
#
# List every group of ado-files that do-files depend on.
# Pass the relevant groups in the `depends=` of each StataBuild call.
# Adjust the Glob patterns to match your machine's Stata ado paths.
# ---------------------------------------------------------------------------

# External (user-installed) ado files — adjust paths as needed
ado_plus     = [f for f in Glob(
    'C:/Users/<user>/AppData/Roaming/Stata/ado/plus/**/*.ado',
    strings=True)]
ado_personal = [f for f in Glob(
    'C:/Users/<user>/AppData/Roaming/Stata/ado/personal/**/*.ado',
    strings=True)]

# Project ado files — root level and named subdirs
ado_root     = [f for f in Glob('code/ado/*.ado',  strings=True)]
# Uncomment and rename for each code/ado/<subdir>/ that exists:
# ado_sims = [f for f in Glob('code/ado/policy_simulations/*.ado', strings=True)]

# ---------------------------------------------------------------------------
# ---- Dataprep ----
# ---------------------------------------------------------------------------

dataprep = env.StataBuild(
    target  = ['input/data/cleaned.dta'],
    source  = ['code/dataprep.do'],
    depends = ado_plus + ado_root + ['input/data/raw.dta'],
)

# ---------------------------------------------------------------------------
# ---- Estimation ----
# ---------------------------------------------------------------------------

# Example: multiple outputs from one do-file
estimation_targets = [
    'output/sters/main-model.ster',
    'output/data/estimation-summary.dta',
]

estimation = env.StataBuild(
    target  = estimation_targets,
    source  = ['code/estimation.do'],
    depends = ado_plus + ado_root + [dataprep],
)

# ---------------------------------------------------------------------------
# ---- Figures and tables ----
# ---------------------------------------------------------------------------

tabfig = env.StataBuild(
    target  = ['output/fig/pdf/main-fig.pdf',
                'output/fig/tex/main-fig-notes.tex',
                'output/tab/tex/main-table.tex'],
    source  = ['code/tabfig.do'],
    depends = ado_plus + ado_root + [estimation],
)

# ---------------------------------------------------------------------------
# Default targets — what `scons` builds with no arguments
# ---------------------------------------------------------------------------

Default([dataprep, estimation, tabfig])

# **** Substance ends          *****
