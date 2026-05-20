---
header-includes:
  - \usepackage{amsmath}
---

# Sources: Applied Use of Stata Frames

This document catalogues sources gathered on the practical use of Stata frames and `.dtas` framesets. All files are saved in this directory (`documentation/applications/`), organized into subfolders.

---

## Subfolder Structure

```
applications/
  help-files/        Stata internal help files (.sthlp) + markdown conversions
  datasets/          Example .dta datasets (Stata installation + Stata Press webuse)
  official-docs/     PDF manuals for applied frame commands
  blog-posts/        Stata blog posts with worked examples
  examples/          Self-contained replicable .do files
```

---

## Stata Internal Help Files (`help-files/`)

All `.sthlp` files were copied verbatim from `C:\Program Files\StataNow19\ado\base\f\`. Each was converted to a clean markdown (`.md`) file in the same folder.

### `frames_intro.sthlp` / `frames_intro.md`
**Version:** 1.2.1, 05 Aug 2025

The primary practical guide to using frames. Covers all major use cases with worked
examples: multitasking, working with simultaneous datasets, simulation via `frame post`,
the preserve/restore performance benefit, and a full tutorial on every frames command.
Also covers ado and Mata programming patterns. Most valuable single source for
applied use.

### `frames.sthlp` / `frames.md`
**Version:** 1.2.1, 05 Aug 2025

Quick-reference index listing syntax for every frame-related command and function with
one-line descriptions and cross-references. Good starting point for looking up syntax.

### `frlink.sthlp` / `frlink.md`
**Version:** 1.1.1, 10 Jul 2024

Full syntax and examples for `frlink` (link frames via key variables). Documents
`1:1` and `m:1` linkages, the `frame()` option for different variable names across
frames, `frlink dir`, `frlink describe`, and `frlink rebuild`. Includes three detailed
examples: persons-counties (m:1), generational data with six simultaneous linkages,
and discharge data (1:1).

### `frget.sthlp` / `frget.md`
**Version:** 1.1.0, 06 Mar 2023

Syntax and options for `frget` -- copies variables from a linked frame to the current
frame. Documents `prefix()`, `suffix()`, `exclude()` options and stored results.

### `fralias.sthlp` / `fralias.md`
**Version:** 1.0.1, 15 Mar 2023

Syntax and examples for `fralias add` (Stata 18+) -- creates memory-efficient alias
variables that reference variables in linked frames without copying. Contrasts with
`frget`. Covers `fralias describe`.

### `frames_save.sthlp` / `frames_save.md`
**Version:** 1.1.0, 20 Mar 2025

Full option set for `frames save`: `frames()`, `replace`, `linked`, `relaxed`,
`complevel()`, `nolabel`, `orphans`, `emptyok`. Notes that `linked` recursively saves
all transitively linked frames.

### `frames_use.sthlp` / `frames_use.md`
**Version:** 1.1.0, 20 Mar 2025

Full option set for `frames use`: `frames()`, `clear`, `replace`. Notes on how
`clear` sets the working frame and how `replace` interacts with existing frames.

### `frames_describe.sthlp` / `frames_describe.md`
**Version:** 1.0.0, 21 Feb 2023

Two syntaxes (in-memory vs. `using filename`). Documents `simple`, `short`,
`fullnames`, `numbers` options and stored results including `r(changed)`.

### `frames_modify.sthlp` / `frames_modify.md`
**Version:** 1.0.1, 05 May 2025

Syntax for adding or dropping frames from a `.dtas` file on disk without loading the
full frameset into memory. Documents `add(framelist [, replace])` and `drop(framelist)`.

### `frame_post.sthlp` / `frame_post.md`
**Version:** 1.0.0, 14 Jun 2019

The `frame create newframename newvarlist` / `frame post framename (exp)...` pattern
for accumulating results from simulations. Notes that `tempname` should be used for
the frame name in programs. Allows `strL` (unlike `postfile`).

### `frame_put.sthlp` / `frame_put.md`
**Version:** 1.0.1, 13 Jan 2020

`frame put varlist [if] [in], into(newframename)` -- copies a subset of variables or
observations from the current frame to a new frame, leaving the current frame unchanged.

### Additional `.sthlp` files copied (not converted to `.md`)

The following were copied from the Stata installation for reference but are smaller
command pages fully covered by `frames_intro.md` and `frames.md`:

- `frame_change.sthlp`, `frame_copy.sthlp`, `frame_drop.sthlp`
- `frame_prefix.sthlp`, `frame_putlabel.sthlp`, `frame_rename.sthlp`
- `frames_dir.sthlp`, `frames_reset.sthlp`

---

## PDF Manuals (`official-docs/`)

Downloaded from `https://www.stata.com/manuals/`.

### `stata-frlink.pdf`
**URL:** https://www.stata.com/manuals/dfrlink.pdf

Full [D] frlink manual including Quick start and Remarks and examples sections not
present in the help file. Contains detailed worked examples with the `persons` and
`txcounty` datasets and the generational family linkage example.

### `stata-frget.pdf`
**URL:** https://www.stata.com/manuals/dfrget.pdf

Full [D] frget manual including the explanation of how `frget` handles underscore
variables and match variables.

### `stata-fralias.pdf`
**URL:** https://www.stata.com/manuals/dfralias.pdf

Full [D] fralias manual including Quick start and detailed remarks on how alias
variables differ from copies and their memory implications.

### `stata-frames-modify.pdf`
**URL:** https://www.stata.com/manuals/dframesmodify.pdf

Full [D] frames modify manual including Quick start and Remarks.

*Note: PDFs for `frames intro`, `frames save`, `frames use`, and `frames describe` were
downloaded during the format documentation phase and are in `documentation/format/`.*

---

## Datasets (`datasets/`)

### From Stata installation (`C:\Program Files\StataNow19\ado\base\`)

| File | Description | Used in |
|------|-------------|---------|
| `auto.dta` | 1978 automobile data (74 obs, 12 vars) | General examples; `dtas.sthlp` |
| `auto2.dta` | Automobile data with extra variables | `dtas.sthlp` format example |
| `auto16.dta` | Automobile data (Stata 16 format) | Format testing |
| `census.dta` | 1980 US census by state (50 obs) | `frames_save` and `frames_describe` examples |

### From Stata Press web server (`http://www.stata-press.com/data/r19/`)

| File | Description | Used in |
|------|-------------|---------|
| `persons.dta` | Person-level data with `countyid` | `frlink` m:1 example |
| `txcounty.dta` | Texas county-level data | `frlink` m:1 example |
| `family.dta` | Generational family data with parent IDs | `frlink` self-link example |
| `discharge1.dta` | Hospital discharge data, part 1 | `frlink` 1:1 example |
| `discharge2.dta` | Hospital discharge data, part 2 | `frlink` 1:1 example |
| `hsng.dta` | Housing cost data (50 obs) | `frames_save` and `frames_modify` examples |

---

## Blog Posts (`blog-posts/`)

### `stata-blog-fun-with-frames-2019.md`
**URL:** https://blog.stata.com/2019/09/06/fun-with-frames/
**Author:** Chuck Huber | **Date:** September 6, 2019

The Stata 16 launch blog post on frames. Demonstrates five applied scenarios: (1)
fitting models on multiple datasets and comparing estimates, (2) storing `margins`
output in a separate frame for a contour plot, (3) using `frval()` for inline
cross-frame calculations, (4) using `frget` to pull demographics into a longitudinal
dataset for mixed-effects modeling, and (5) opening 22 chromosome datasets
simultaneously in Stata/MP. Key practical insight: frames eliminate the
clear/load/run/save cycle when coordinating multiple datasets.

### `stata-blog-framesets-alias-2023.md`
**URL:** https://blog.stata.com/2023/09/12/from-datasets-to-framesets-and-alias-variables-data-management-advances-in-stata/
**Author:** Kreshna Gopal | **Date:** September 12, 2023

The Stata 18 blog post introducing framesets (`.dtas`) and alias variables. Covers the
full workflow: creating multiple frames, saving them with `frames save`, describing with
`frames describe using`, reloading with `frames use`, saving with the `linked` option,
and creating alias variables with `fralias add`. Includes a historical timeline of
Stata data management milestones from 1985 to 2023.

*Note: An earlier version was saved in `documentation/format/stata-blog-framesets-alias-2023.md`.*

---

## Example Do-files (`examples/`)

Self-contained replicable scripts demonstrating key workflows. Each script lists
required datasets at the top. Where `webuse` is used, the dataset is also available
in the `datasets/` folder.

### `example-01-basic-frames.do`
Basic frame management: `frame create`, `frame change`, `frame prefix`, `frame copy`,
`frame put`, `frame drop`, `frames reset`. Uses `sysuse auto` and `sysuse census`.

### `example-02-frlink-frget.do`
Linking frames with `frlink`: m:1 (persons-counties), 1:1 (discharge data), self-link
(generational family). Also demonstrates `frget`, `fralias add`, and `frval()`.
Uses `webuse persons`, `webuse txcounty`, `webuse family`, `webuse discharge1/2`.

### `example-03-simulation-frame-post.do`
Monte Carlo simulation using `frame create` / `frame post`. Runs 1,000 OLS replications
and collects results (slope estimate, SE, CI coverage) in a separate frame. Tests that
the 95% CI covers the true slope approximately 95% of the time. Uses no external datasets.

### `example-04-frameset-save-use.do`
Full frameset lifecycle: `frames save`, `frames describe using`, `frames use`,
`frames modify add`, `frames modify drop`. Uses `sysuse census` and `webuse hsng`.
