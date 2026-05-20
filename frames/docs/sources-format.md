---
header-includes:
  - \usepackage{amsmath}
---

# Sources: Stata `.dtas` File Format

This document catalogues sources gathered on the `.dtas` file format (Stata framesets) and the
underlying `.dta` format. All files are saved in this directory (`documentation/format/`).

---

## Official Stata Manuals (PDFs)

### `stata-fileformats-dtas.pdf`
**URL:** https://www.stata.com/manuals/pfileformatsdtas.pdf

The primary technical reference for the `.dtas` format, intended for programmers who want
other software to create or read frameset files. Documents the internal structure: a `.dtas`
file is a zip archive (using Stata's `zipfile`/`unzipfile` commands internally) containing
one `.dta` file per frame, plus a manifest of frame names and internal filenames. Covers
compression levels (0--9, default 1). This is the most authoritative source for format
internals.

### `stata-fileformats-dta.pdf`
**URL:** https://www.stata.com/manuals/pfileformatsdta.pdf

Current (Stata 18/19) technical specification of the underlying `.dta` file format, for
programmers. Covers the binary layout of a single-frame dataset: header, variable types
(byte, int, long, float, double, str#, strL), value labels, notes, and metadata chunks.
Format numbers 119--121 are documented here. Essential background since each frame inside a
`.dtas` is a `.dta` file.

### `stata14-fileformats-dta.pdf`
**URL:** https://www.stata.com/manuals14/pfileformatsdta.pdf

Stata 14 version of the `.dta` format spec, covering format 118. Useful for understanding
the format history and what changed between versions. Format 118 is the first version with
the XML-like chunked structure introduced in Stata 13.

### `stata-frames-intro.pdf`
**URL:** https://www.stata.com/manuals/dframesintro.pdf

Introduction to Stata frames (Stata 16+). Explains the conceptual model: multiple named
datasets held simultaneously in memory, linked via `frlink`. Background needed to understand
why framesets exist.

### `stata-frames-save.pdf`
**URL:** https://www.stata.com/manuals/dframessave.pdf

Manual page for the `frames save` command. Documents syntax, options (including `linked` to
auto-include linked frames and `complevel(#)` for zip compression), and behavior when
overwriting existing `.dtas` files.

### `stata-frames-use.pdf`
**URL:** https://www.stata.com/manuals/dframesuse.pdf

Manual page for the `frames use` command. Documents how a `.dtas` file is read back into
memory, including the `frames()` option to load a subset of frames and behavior on name
conflicts.

### `stata-frames-describe.pdf`
**URL:** https://www.stata.com/manuals/dframesdescribe.pdf

Manual page for the `frames describe` command. Shows how to inspect a `.dtas` file on disk
without loading it -- reporting frame names, variable counts, observation counts, and
`.dta` format version of each frame.

### `stata-zipfile.pdf`
**URL:** https://www.stata.com/manuals/dzipfile.pdf

Manual page for Stata's `zipfile` and `unzipfile` commands. Relevant because `.dtas` files
are zip archives; Stata uses these commands internally when saving and loading framesets.
Useful for understanding the container format at the zip level.

---

## Stata Internal Help Files (SMCL, from local installation)

These files were copied from the Stata 19 installation at
`C:\Program Files\StataNow19\ado\base\`. They are SMCL (Stata Markup and Control Language)
source files that Stata renders in its Help viewer. They may contain information not in the
public PDF manuals.

### `stata-help-dtas.sthlp`
**Path:** `C:\Program Files\StataNow19\ado\base\d\dtas.sthlp`
**Version stamp:** 1.0.0, 06 Mar 2023

The most technically detailed single source for the `.dtas` format. Documents the internal
structure of the zip archive and, crucially, the exact format of the `.frameinfo` manifest
file that must be present in every `.dtas`:

- Line 1: `*! VERSION 1` (`.frameinfo` schema version)
- Line 2: `*! COMPLEVEL n` (recorded but has no effect on reading)
- Remaining lines: three whitespace-separated columns -- frame name, `.dta` filename
  (no extension, no spaces), and format number (e.g., 118)

Also documents the optional per-frame `.hdr` header file (created with
`save filename, headeronly`) that allows `frames describe` to work efficiently without
loading the full dataset.

### `stata-help-set_dtascomplevel.sthlp`
**Path:** `C:\Program Files\StataNow19\ado\base\s\set_dtascomplevel.sthlp`
**Version stamp:** 1.0.0, 21 Feb 2023

Documents `set dtascomplevel #` (integer 0--9, default 1). Explains the compression
tradeoff: higher levels produce smaller files but take longer; on slow I/O systems,
level 1 can be faster than level 0; levels 2--9 are rarely worth it unless file size
is the primary concern.

---

## Unofficial / Third-Party Sources (Markdown)

### `readstata13-cran-manual.md`
**URL:** https://cran.r-project.org/web/packages/readstata13/vignettes/readstata13_basic_manual.html

Vignette for the `readstata13` R package, which can read `.dtas` files via `read.dtas()`
and inspect them via `get.frames()`. Documents supported format numbers by Stata version
(formats 102--121), `.dtas` handling, strL long-string support, missing value encoding, and
endianness. Useful as an independent implementer's perspective on the format.

### `stata-blog-framesets-alias-2023.md`
**URL:** https://blog.stata.com/2023/09/12/from-datasets-to-framesets-and-alias-variables-data-management-advances-in-stata/

Official Stata blog post (September 2023) announcing frameset and alias variable features in
Stata 18. Provides historical context (frames added in Stata 16, framesets in Stata 18),
workflow examples, and a plain-language description of how `.dtas` files work. Good
orientation piece, not a format spec.

### `stata-features-frameset.md`
**URL:** https://www.stata.com/features/overview/frameset/

Stata product features page for framesets. Brief marketing-oriented overview of `frames
save`, `frames use`, and `frames describe`, confirming that `.dtas` is described as "the
plural of `.dta`" and that compression is automatic. No format internals, but useful for
understanding intended use cases.

---

## Sources Not Retrieved (Access Blocked)

### Library of Congress: Stata Data File Format (.dta), Version 118
**URL:** https://www.loc.gov/preservation/digital/formats/fdd/fdd000471.shtml

The Library of Congress Sustainability of Digital Formats database entry for the Stata `.dta`
format (version 118 / format number 118). Likely contains format registry information,
file signatures, and preservation notes. Returned HTTP 403 at time of access (2026-05-19);
worth retrying or accessing via browser.
