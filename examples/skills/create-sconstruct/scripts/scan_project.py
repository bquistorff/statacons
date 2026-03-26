#!/usr/bin/env python3
"""
scan_project.py — Stata project scanner

Scans a Stata research project directory and produces scan_results.yaml,
recording discovered inputs, outputs, and build dependencies for each do-file.
The YAML can be reviewed and edited by the user before passing to
gen_sconstruct.py to generate a draft SConstruct.

Parsing strategy (multi-layer):
  Layer 1 — Stata command regex:  ~20 I/O command patterns parsed from every line
  Layer 2 — Macro resolution:     look in do-file first, then setup files
  Layer 3 — Log-file resolution:  plain-text .log preferred; fall back to .smcl
  Layer 4 — Header cross-check:   inputs:/outputs: block compared to command results

Usage:
    python scan_project.py <project_root> [options]

Options:
    --out PATH          Output YAML file or directory.
                        If PATH is a directory, saves scan_results.yaml inside it.
                        Default: <project_root>/scan_results.yaml
    -f, --file DO_FILE  Restrict scan to specified do-file(s) (repeatable or
                        space-separated). Match by filename, relative path, or
                        absolute path. Marks the output YAML with is_fragment: true,
                        so gen_sconstruct.py automatically uses Fragment naming.
    --log-txt-dir D     Plain-text log directory (default: <root>/output/log/log)
    --log-smcl-dir D    SMCL log directory      (default: <root>/output/log/smcl)
    --include-testing   Include testing/utility do-files (testing_*.do, _*.do)
                        Excluded by default.
    --quiet             Suppress stdout report

Adopath options (BASE and SITE always excluded):
    --no-personal       Exclude Stata PERSONAL ado path (included by default)
    --no-plus           Exclude Stata PLUS ado path (included by default)
    --include-oldplace  Include Stata OLDPLACE ado path (excluded by default)
    --extra-ado DIR     Additional ado directory to scan (repeatable)

Project ado-file options (code/ado/):
    --no-ado-root       Exclude code/ado/*.ado (root-level ados)
    --no-ado-subdir N   Exclude a named code/ado/<N>/ subdirectory (repeatable)
"""

import argparse
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml


# ===========================================================================
# 1.  Directory scanner
# ===========================================================================

# Do-files whose names match these patterns are testing/utility scripts,
# not part of the main build pipeline.  Excluded by default.
_RE_TESTING = re.compile(r'^(testing_|test_|_)', re.IGNORECASE)


def scan_directory(
    root: Path,
    include_testing: bool = False,
    exclude_ado_root: bool = False,
    exclude_ado_subdirs: set[str] | None = None,
) -> dict:
    """Walk project tree and classify files by role.

    Parameters
    ----------
    root                Project root directory.
    include_testing     If True, include testing_*.do and _*.do as task files.
    exclude_ado_root    If True, omit code/ado/*.ado (root-level ados).
    exclude_ado_subdirs Names of code/ado/<N>/ subdirectories to skip.
    """
    if exclude_ado_subdirs is None:
        exclude_ado_subdirs = set()

    manifest = {
        'task_dofiles':    [],   # code/*.do          — one build task each
        'testing_dofiles': [],   # code/testing_*.do / code/_*.do (excluded by default)
        'subdo_files':     [],   # code/subdo/**/*.do  — dependencies only
        'ado_groups':      {},   # {group_name: [Path, ...]} e.g. {'root': [...], 'policy_simulations': [...]}
        'ado_files':       [],   # flat list (all included ados, for backward compat)
        'setup_dofiles':   [],   # code/setup/*.do     — excluded from tasks
        'log_txt':         [],   # output/log/log/*.log
        'log_smcl':        [],   # output/log/smcl/*.smcl
    }

    code_dir = root / 'code'
    if code_dir.exists():
        for f in sorted(code_dir.glob('*.do')):
            if not include_testing and _RE_TESTING.match(f.name):
                manifest['testing_dofiles'].append(f)
            else:
                manifest['task_dofiles'].append(f)

        subdo = code_dir / 'subdo'
        if subdo.exists():
            for f in sorted(subdo.rglob('*.do')):
                manifest['subdo_files'].append(f)

        ado = code_dir / 'ado'
        if ado.exists():
            # Root ados: code/ado/*.ado
            if not exclude_ado_root:
                root_ados = sorted(ado.glob('*.ado'))
                if root_ados:
                    manifest['ado_groups']['root'] = root_ados
                    manifest['ado_files'].extend(root_ados)

            # Subdirectory ados: code/ado/<subdir>/*.ado
            for subdir in sorted(d for d in ado.iterdir() if d.is_dir()):
                if subdir.name in exclude_ado_subdirs:
                    continue
                sub_ados = sorted(subdir.rglob('*.ado'))
                if sub_ados:
                    manifest['ado_groups'][subdir.name] = sub_ados
                    manifest['ado_files'].extend(sub_ados)

        setup = code_dir / 'setup'
        if setup.exists():
            for f in sorted(setup.glob('*.do')):
                manifest['setup_dofiles'].append(f)

    log_txt_dir  = root / 'output' / 'log' / 'log'
    log_smcl_dir = root / 'output' / 'log' / 'smcl'
    if log_txt_dir.exists():
        for f in sorted(log_txt_dir.glob('*.log')):
            manifest['log_txt'].append(f)
    if log_smcl_dir.exists():
        for f in sorted(log_smcl_dir.glob('*.smcl')):
            manifest['log_smcl'].append(f)

    return manifest


# ===========================================================================
# 2.  Stata command parser
# ===========================================================================

# (pattern, io_type, path_hint)
# path_hint:
#   'direct' — path immediately follows the command keyword(s)
#   'using'  — path follows the 'using' keyword
#   'either' — direct or after 'using'
#   'subdo'  — sub-do dependency (not a data file)
_IO_SPECS = [
    # ---- Inputs ----
    (r'\b(?:use|us)\b',                       'input',  'either'),
    (r'\b(?:merge|me)\b.+\busing\b',          'input',  'using'),
    (r'\b(?:append|ap)\s+using\b',            'input',  'using'),
    (r'\bimport\s+excel\b',                   'input',  'either'),
    (r'\bimport\s+delimited\b',               'input',  'either'),
    (r'\bimport\s+sasxport(?:5|8)?\b',        'input',  'direct'),
    (r'\binfile\b.*\busing\b',                'input',  'using'),
    (r'\binsheet\b.*\busing\b',               'input',  'using'),
    (r'\bestread\b',                           'input',  'direct'),
    (r'\bestimates\s+use\b',                  'input',  'direct'),
    (r'\bgraph\s+use\b',                      'input',  'direct'),
    # ---- Sub-do dependencies ----
    (r'^\s*(?:do|run|include)\b',             'subdo',  'direct'),
    # ---- Outputs ----
    (r'\b(?:save|sa)\b',                      'output', 'direct'),
    (r'\bsaveold\b',                          'output', 'direct'),
    (r'\bexport\s+excel\b',                   'output', 'either'),
    (r'\bexport\s+delimited\b',               'output', 'either'),
    (r'\blog\s+using\b',                      'output', 'using'),
    (r'\b(?:esttab|estout)\b.*\busing\b',     'output', 'using'),
    (r'\bestwrite\b',                         'output', 'direct'),
    (r'\bestimates\s+save\b',                 'output', 'direct'),
    (r'\bgraph\s+export\b',                   'output', 'direct'),
    (r'\btexsave\b.*\busing\b',              'output', 'using'),
    (r'\bdataout\b.*\busing\b',              'output', 'using'),
    (r'\boutfile\b.*\busing\b',              'output', 'using'),
    (r'\boutsheet\b.*\busing\b',             'output', 'using'),
    (r'\bputexcel\s+set\b',                  'output', 'direct'),
    (r'\bframesave\b',                        'output', 'direct'),
    (r'\bfile\s+open\s+\w+\s+using\b',       'output', 'using'),
]

_COMPILED_IO = [
    (re.compile(pat, re.IGNORECASE), iotype, hint)
    for pat, iotype, hint in _IO_SPECS
]

_RE_USING      = re.compile(r'\busing\s+', re.IGNORECASE)
_RE_QUOTED     = re.compile(r'"([^"]+)"')
_RE_UNQUOTED   = re.compile(r'''(?:^|\s)((?:[`${\w./\\-][^\s,]*)(?:/[^\s,]*)*)''')
# Stata: copy "src" "dest" [, replace text binary]
_RE_STATA_COPY = re.compile(r'^\s*copy\b', re.IGNORECASE)

# Stata: foreach VAR in val1 val2 val3 [{ ] — literal value list only
# Does NOT match "foreach VAR of varlist/numlist/newlist/local/global"
_RE_FOREACH_IN = re.compile(
    r'^\s*foreach\s+(\w+)\s+in\s+(.*?)(?:\s*\{)?\s*$',
    re.IGNORECASE,
)
# Stata: foreach VAR of local MACRONAME — where MACRONAME holds space-separated values
_RE_FOREACH_OF_LOCAL = re.compile(
    r'^\s*foreach\s+(\w+)\s+of\s+local\s+(\w+)\s*(?:\{)?\s*$',
    re.IGNORECASE,
)

# Conditional / loop block openers
_RE_COND_BLOCK = re.compile(
    r'^\s*(?:if|else(?:\s+if)?|foreach|forval(?:ues)?|while)\b.*\{',
    re.IGNORECASE
)
_RE_CLOSE = re.compile(r'^\s*\}')

# Log-file helpers (used by --no-expand-macros mode)
_RE_SMCL_TAG     = re.compile(r'\{[^}]*\}')
_RE_LOG_FILE_PATH = re.compile(r'"([^"\n]+\.\w{2,6})"')
_RE_MACRO_SEP    = re.compile(r'`[^\']*\'|\$\{?[A-Za-z_]\w*\}?')


def _preprocess(path: Path) -> list[tuple[int, str]]:
    """
    Read a do-file and return (orig_lineno, stmt) pairs:
      - block comments removed
      - continuation lines (///) joined
      - inline comments (//) stripped
      - blank lines discarded

    orig_lineno is the 1-indexed line number in the ORIGINAL file.
    Block comments are erased by replacing all non-newline characters
    with spaces (preserving newlines), so the processed line count stays
    in sync with the original file. This is critical for W2 (line-aware
    macro resolution), where we use line numbers as cutoffs into do_lines.
    """
    try:
        text = path.read_text(encoding='utf-8', errors='replace')
    except OSError:
        return []

    # Remove /* ... */ block comments while PRESERVING newlines so that
    # processed line numbers align 1:1 with original file line numbers.
    def _blank_comment(m: re.Match) -> str:
        return re.sub(r'[^\n]', ' ', m.group(0))

    text = re.sub(r'/\*.*?\*/', _blank_comment, text, flags=re.DOTALL)
    raw = text.splitlines()

    result: list[tuple[int, str]] = []
    i = 0
    while i < len(raw):
        line = raw[i]
        orig = i + 1
        # Join continuation lines
        while line.rstrip().endswith('///') and i + 1 < len(raw):
            i += 1
            line = line.rstrip()[:-3] + ' ' + raw[i].lstrip()
        # Strip inline comment
        line = re.sub(r'\s*//.*$', '', line)
        if line.strip():
            result.append((orig, line))
        i += 1

    return result


def _extract_path(stmt: str, hint: str) -> str | None:
    """
    Extract the raw file-path string from a Stata statement.
    Prefers quoted strings ("..."); falls back to path-like unquoted tokens.
    Returns None if nothing path-like is found.
    """
    if hint == 'using':
        m = _RE_USING.search(stmt)
        if not m:
            return None
        segment = stmt[m.end():]
    elif hint == 'either':
        m = _RE_USING.search(stmt)
        segment = stmt[m.end():] if m else stmt
    else:  # 'direct'
        segment = stmt

    # First quoted string wins
    qm = _RE_QUOTED.search(segment)
    if qm:
        return qm.group(1).strip()

    # Unquoted fallback: first token that looks like a path
    for tok in segment.split():
        tok = tok.strip(',')
        if re.search(r'[`$./\\]', tok):
            return tok

    return None


def parse_stata_commands(path: Path) -> list[dict]:
    """
    Return list of I/O hits from a do-file:
      {cmd_type, raw_path, line_no, in_conditional, raw_stmt}
    """
    stmts = _preprocess(path)
    hits: list[dict] = []
    depth = 0

    for orig_no, stmt in stmts:
        if _RE_COND_BLOCK.match(stmt):
            depth += 1
        if _RE_CLOSE.match(stmt):
            depth = max(0, depth - 1)
            continue

        # Special case: Stata copy "src" "dest" [, replace text binary]
        # Generates two hits (input for src, output for dest) from one statement.
        if _RE_STATA_COPY.match(stmt):
            quoted = _RE_QUOTED.findall(stmt)
            if len(quoted) >= 2:
                hits.append({'cmd_type': 'input',  'raw_path': quoted[0],
                             'line_no': orig_no, 'in_conditional': depth > 0,
                             'raw_stmt': stmt.strip()})
                hits.append({'cmd_type': 'output', 'raw_path': quoted[1],
                             'line_no': orig_no, 'in_conditional': depth > 0,
                             'raw_stmt': stmt.strip()})
            elif len(quoted) == 1:
                hits.append({'cmd_type': 'output', 'raw_path': quoted[0],
                             'line_no': orig_no, 'in_conditional': depth > 0,
                             'raw_stmt': stmt.strip()})
            continue  # skip _COMPILED_IO loop

        for pattern, iotype, hint in _COMPILED_IO:
            if pattern.search(stmt):
                raw = _extract_path(stmt, hint)
                if raw is not None:
                    hits.append({
                        'cmd_type':       iotype,
                        'raw_path':       raw,
                        'line_no':        orig_no,
                        'in_conditional': depth > 0,
                        'raw_stmt':       stmt.strip(),
                    })
                break  # one match per statement

    return hits


# ===========================================================================
# 2b. foreach literal expansion
# ===========================================================================

def _collect_foreach_literals(lines: list[str]) -> dict[str, list[str]]:
    """
    Scan raw do-file lines for foreach constructs whose values form a literal
    whitespace-separated list, and return {VAR: [val1, val2, ...]}:

      - "foreach VAR in val1 val2 ..."  — explicit literal form
      - "foreach VAR of local MACRONAME" — where MACRONAME is a simple string
        macro defined earlier in the file (value split on whitespace)

    Only handles these two forms; "of varlist/numlist/newlist/global" are not
    expanded (values would require Stata runtime information).
    When the same VAR appears in multiple foreach blocks, later definitions
    overwrite earlier ones (last wins).
    """
    macros = _collect_macros(lines)  # full macro dict (all assignments)
    result: dict[str, list[str]] = {}
    for line in lines:
        # Direct literal form: foreach VAR in val1 val2 ...
        m = _RE_FOREACH_IN.match(line)
        if m:
            varname = m.group(1)
            values_str = m.group(2).strip()
            values = [v for v in values_str.split() if v]
            if values:
                result[varname] = values
            continue
        # Indirect form: foreach VAR of local MACRONAME
        m = _RE_FOREACH_OF_LOCAL.match(line)
        if m:
            varname = m.group(1)
            local_ref = m.group(2)
            if local_ref in macros:
                val_str = macros[local_ref].strip()
                values = [v for v in val_str.split() if v]
                if values:
                    result[varname] = values
    return result


def _expand_foreach_hits(
    hits: list[dict],
    foreach_literals: dict[str, list[str]],
) -> list[dict]:
    """
    For each hit whose raw_path contains a local macro ref that matches a
    foreach literal variable, produce N copies of the hit (one per loop value),
    substituting the macro with the concrete value.

    If a path contains multiple foreach variables, all combinations are emitted
    (cross-product). Hits with no foreach variable references are returned
    unchanged.

    Expanded hits are marked with '_foreach_expanded' for debugging.
    """
    if not foreach_literals:
        return hits

    result: list[dict] = []
    for hit in hits:
        raw = hit['raw_path']
        local_refs = set(_RE_LOCAL_REF.findall(raw))
        expansion_vars = [
            (var, foreach_literals[var])
            for var in local_refs
            if var in foreach_literals
        ]
        if not expansion_vars:
            result.append(hit)
            continue

        # Build cross-product of all foreach-variable values found in this path
        expanded_raws: list[str] = [raw]
        for var_name, values in expansion_vars:
            new_raws: list[str] = []
            for path_template in expanded_raws:
                for val in values:
                    substituted = re.sub(
                        rf'`{re.escape(var_name)}\'', val, path_template
                    )
                    new_raws.append(substituted)
            expanded_raws = new_raws

        tag = 'foreach ' + ', '.join(v for v, _ in expansion_vars) + ' in ...'
        for expanded_raw in expanded_raws:
            new_hit = dict(hit)
            new_hit['raw_path'] = expanded_raw
            new_hit['in_conditional'] = False  # loop body counts as resolved
            new_hit['_foreach_expanded'] = tag
            result.append(new_hit)

    return result


# ===========================================================================
# 3.  Macro resolver
# ===========================================================================

_RE_LOCAL_DEF  = re.compile(r'^\s*loc(?:al)?\s+(\w+)\s+(.*)', re.IGNORECASE)
_RE_GLOBAL_DEF = re.compile(r'^\s*glob(?:al)?\s+(\w+)\s+(.*)', re.IGNORECASE)
_RE_LOCAL_REF  = re.compile(r'`(\w+)\'')
_RE_GLOBAL_REF = re.compile(r'\$\{?(\w+)\}?')
_RE_TEMPFILE   = re.compile(r'^\s*tempfile\s+(.+)', re.IGNORECASE)

_MAX_DEPTH = 6


def _collect_macros(lines: list[str], before_line: int | None = None) -> dict[str, str]:
    """Extract macro definitions from a list of raw do-file lines.

    If before_line is given, only includes assignments on lines strictly before
    that line number (1-indexed). This allows resolving a macro to the value it
    held at a specific point in the file — critical when the same macro name is
    reassigned multiple times (e.g., `graph_name` set before each graph export).
    """
    macros: dict[str, str] = {}
    for i, line in enumerate(lines, start=1):
        if before_line is not None and i >= before_line:
            break
        for pat in (_RE_LOCAL_DEF, _RE_GLOBAL_DEF):
            m = pat.match(line)
            if m:
                name = m.group(1)
                val  = m.group(2).strip()
                # Strip matching outer quotes only (paired), preserving inner content.
                # Using .strip('"').strip("'") would incorrectly eat trailing apostrophes
                # from macro references like `name_do' stored as values.
                if len(val) >= 2 and val[0] == '"' and val[-1] == '"':
                    val = val[1:-1]
                elif len(val) >= 2 and val[0] == "'" and val[-1] == "'":
                    val = val[1:-1]
                macros[name] = val
                break
    return macros


def _collect_tempfiles(lines: list[str]) -> set[str]:
    """
    Collect all macro names declared via 'tempfile' in a list of lines.
    Stata's 'tempfile name1 [name2 ...]' assigns OS temp paths to local macros;
    those paths are session-scoped scratch and should not appear in the build graph.
    """
    names: set[str] = set()
    for line in lines:
        m = _RE_TEMPFILE.match(line)
        if m:
            names.update(m.group(1).split())
    return names


def _substitute(raw: str, macros: dict[str, str]) -> str:
    """Recursively resolve macros in a raw path string."""
    result = raw
    for _ in range(_MAX_DEPTH):
        prev = result

        def _sub_local(m: re.Match) -> str:
            return macros.get(m.group(1), m.group(0))

        def _sub_global(m: re.Match) -> str:
            return macros.get(m.group(1), m.group(0))

        result = _RE_LOCAL_REF.sub(_sub_local, result)
        result = _RE_GLOBAL_REF.sub(_sub_global, result)
        if result == prev:
            break
    return result


def _has_macros(s: str) -> bool:
    return bool(_RE_LOCAL_REF.search(s) or _RE_GLOBAL_REF.search(s))


def _find_log(base: str,
              log_txt_dir: Path | None,
              log_smcl_dir: Path | None,
              do_mtime: float | None) -> tuple[Path | None, str]:
    """
    Find the best log file for macro resolution.
    Prefers plain-text .log; falls back to .smcl.
    Returns (path_or_None, 'log_txt'|'log_smcl'|'').
    """
    max_age_s = 48 * 3600  # 48 hours

    for log_dir, suffix, label in [
        (log_txt_dir,  '.log',  'log_txt'),
        (log_smcl_dir, '.smcl', 'log_smcl'),
    ]:
        if not log_dir or not log_dir.exists():
            continue
        candidate = log_dir / (base + suffix)
        if not candidate.exists():
            continue
        if do_mtime is not None:
            age = abs(candidate.stat().st_mtime - do_mtime)
            if age > max_age_s:
                continue
        return candidate, label

    return None, ''


def _search_log(macro_name: str, log_path: Path) -> str | None:
    """
    Heuristically search a log file for the expanded value of macro_name.
    Only finds values that look like file paths.
    """
    try:
        text = log_path.read_text(encoding='utf-8', errors='replace')
    except OSError:
        return None

    pats = [
        re.compile(rf'`{re.escape(macro_name)}\'\s*=\s*([^\n]+)', re.IGNORECASE),
        re.compile(rf'\b{re.escape(macro_name)}\s*=\s*"?([^"\n]+)"?', re.IGNORECASE),
    ]
    for pat in pats:
        m = pat.search(text)
        if m:
            val = m.group(1).strip().strip('"').strip("'")
            if val and re.search(r'[/\\.]', val):
                return val
    return None


def _parse_log_for_paths(log_path: Path) -> list[str]:
    """
    Extract file paths from a Stata log file (SMCL or plain text).

    Only processes command lines (those preceded by the Stata prompt '.'
    in plain-text logs, or wrapped in {com} tags in SMCL logs).
    Returns a deduplicated list of file paths (forward-slash normalised).
    """
    try:
        text = log_path.read_text(encoding='utf-8', errors='replace')
    except OSError:
        return []

    is_smcl = log_path.suffix.lower() == '.smcl'
    paths: list[str] = []

    for line in text.splitlines():
        if is_smcl:
            if '{com}' not in line:
                continue
            clean = _RE_SMCL_TAG.sub('', line).strip()
        else:
            if not re.match(r'^[.>]\s', line):
                continue
            clean = re.sub(r'^[.>]\s+', '', line)

        for m in _RE_LOG_FILE_PATH.finditer(clean):
            paths.append(m.group(1).replace('\\', '/'))

    return list(dict.fromkeys(paths))  # deduplicate, preserve order


def _match_log_paths(raw_path: str, log_paths: list[str]) -> list[str]:
    """
    Match a macro-containing raw path against expanded paths from a log file.

    Splits raw_path on macro references (``name'' / $name) and requires all
    literal fragments to appear in the candidate log path in order.
    Returns all log paths that match (may be >1 for foreach loops).
    """
    rp = raw_path.strip('"\'')
    parts = [p for p in _RE_MACRO_SEP.split(rp) if p]
    if not parts:
        return []

    results: list[str] = []
    for lp in log_paths:
        pos = 0
        for part in parts:
            idx = lp.find(part, pos)
            if idx == -1:
                break
            pos = idx + len(part)
        else:
            results.append(lp)
    return results


def resolve_macros(
    raw: str,
    dofile_lines: list[str],
    setup_lines: list[str],
    log_txt_dir: Path | None,
    log_smcl_dir: Path | None,
    do_mtime: float | None,
    base: str,
    line_no: int | None = None,
    foreach_overrides: dict[str, str] | None = None,
) -> tuple[str, str, str]:
    """
    Resolve macros in `raw` path string.
    Returns (resolved, source, confidence).
      source:     'clean' | 'dofile' | 'setup' | 'log_txt' | 'log_smcl' | 'unresolved'
      confidence: 'high'  | 'medium' | 'low'

    line_no: if provided, only macro assignments before this line are used for
    Layer 2a resolution. This ensures that when the same macro (e.g. graph_name)
    is reassigned multiple times, each hit sees the value defined just before it.

    foreach_overrides: optional {var: value} dict injected at the start of Layer 2a
    resolution. Used for D3: when a path like `filename_sim'-hh.dta is unresolved
    because filename_sim is defined as "`name_do'-sub`SUBSIDY'" inside a foreach
    loop, passing {SUBSIDY: '2000'} here allows the full chain to resolve.
    """
    if not _has_macros(raw):
        return raw, 'clean', 'high'

    # Layer 2a: macros in the do-file itself, up to line_no (if given).
    # foreach_overrides are merged in first so loop-variable values take
    # effect before any static definitions (they will be overwritten by
    # static defs if the same name is assigned — but foreach vars are
    # typically not assigned as regular locals in the same scope).
    macros = _collect_macros(dofile_lines, before_line=line_no)
    if foreach_overrides:
        # Merge overrides: foreach var values win over any static definition
        # of the same name (static defs are pre-loop placeholders at best).
        macros.update(foreach_overrides)
    resolved = _substitute(raw, macros)
    if not _has_macros(resolved):
        return resolved, 'dofile', 'high'

    # Layer 2b: macros in setup files (all lines — setup runs before the do-file)
    if setup_lines:
        macros.update(_collect_macros(setup_lines))
        resolved = _substitute(raw, macros)
        if not _has_macros(resolved):
            return resolved, 'setup', 'medium'

    # Layer 3: log file
    if base:
        log_path, log_label = _find_log(base, log_txt_dir, log_smcl_dir, do_mtime)
        if log_path:
            remaining = _RE_LOCAL_REF.findall(resolved) + _RE_GLOBAL_REF.findall(resolved)
            log_macros: dict[str, str] = {}
            for mname in remaining:
                val = _search_log(mname, log_path)
                if val:
                    log_macros[mname] = val
            if log_macros:
                macros.update(log_macros)
                resolved = _substitute(raw, macros)
                if not _has_macros(resolved):
                    return resolved, log_label, 'medium'

    return resolved, 'unresolved', 'low'


# ===========================================================================
# 4.  Header block parser (cross-check only)
# ===========================================================================

_RE_HEADER_BLOCK = re.compile(r'/\*\s*\*+.*?\*+\s*\*/', re.DOTALL)
_RE_HDR_INPUTS   = re.compile(
    r'inputs\s*:\s*(.+?)(?=outputs\s*:|v\s*\d|\*{3}|\Z)', re.IGNORECASE | re.DOTALL
)
_RE_HDR_OUTPUTS  = re.compile(
    r'outputs\s*:\s*(.+?)(?=inputs\s*:|v\s*\d|\*{3}|\Z)', re.IGNORECASE | re.DOTALL
)


def parse_dofile_header(path: Path) -> tuple[list[str], list[str]]:
    """Extract inputs/outputs from the standard /* *** */ header block."""
    try:
        text = path.read_text(encoding='utf-8', errors='replace')
    except OSError:
        return [], []

    m = _RE_HEADER_BLOCK.search(text)
    if not m:
        return [], []
    header = m.group(0)

    def _extract(section: str) -> list[str]:
        paths: list[str] = []
        for line in section.splitlines():
            line = line.strip().strip('*').strip()
            if not line or line.lower().startswith(('inputs', 'outputs', 'v1', 'v2')):
                continue
            # Quoted paths
            found = _RE_QUOTED.findall(line)
            if found:
                paths.extend(found)
            elif re.search(r'[./\\]', line):
                paths.append(line)
        return paths

    inputs, outputs = [], []
    mi = _RE_HDR_INPUTS.search(header)
    if mi:
        inputs = _extract(mi.group(1))
    mo = _RE_HDR_OUTPUTS.search(header)
    if mo:
        outputs = _extract(mo.group(1))

    return inputs, outputs


# ===========================================================================
# 5.  Full do-file parser
# ===========================================================================

def _rel(path_str: str, root: Path) -> str:
    """Normalise a path string to be relative to root."""
    p = path_str.replace('\\', '/')
    root_str = str(root).replace('\\', '/')
    if p.startswith(root_str):
        p = p[len(root_str):].lstrip('/')
    return p


def _load_setup_lines(setup_dofiles: list[Path]) -> list[str]:
    lines: list[str] = []
    for f in setup_dofiles:
        try:
            lines.extend(f.read_text(encoding='utf-8', errors='replace').splitlines())
        except OSError:
            pass
    return lines


def parse_dofile(
    path: Path,
    setup_lines: list[str],
    log_txt_dir: Path | None,
    log_smcl_dir: Path | None,
    root: Path,
    no_expand_macros: bool = False,
) -> dict:
    """Full parse of a single do-file. Returns a structured result dict.

    When no_expand_macros=True the scanner skips all Python-side macro
    resolution (foreach expansion, resolve_macros, D3 retry).  Instead it
    looks for the do-file's log file and tries to match macro-containing
    raw paths against the expanded paths found there.  Paths that cannot be
    matched via the log are stored in as_is_inputs / as_is_outputs with the
    macro syntax intact and emitted verbatim in the SConstruct.
    """
    try:
        stat     = path.stat()
        do_lines = path.read_text(encoding='utf-8', errors='replace').splitlines()
    except OSError:
        return {}

    base = path.stem
    hits = parse_stata_commands(path)

    # --no-expand-macros mode: skip all Python-side macro resolution.
    # Instead, look in the log file for expanded paths.
    if no_expand_macros:
        log_path_ne, _ = _find_log(base, log_txt_dir, log_smcl_dir, stat.st_mtime)
        log_paths_ne   = _parse_log_for_paths(log_path_ne) if log_path_ne else []
        foreach_literals: dict = {}   # skip W1/D3

        hdr_inputs, hdr_outputs = parse_dofile_header(path)
        tempfile_names = _collect_tempfiles(do_lines)

        inputs:       list[dict] = []
        outputs:      list[dict] = []
        subdos:       list[dict] = []
        conditionals: list[dict] = []
        unresolved:   list[dict] = []
        as_is_inputs:  list[dict] = []
        as_is_outputs: list[dict] = []

        for hit in hits:
            raw     = hit['raw_path']
            iotype  = hit['cmd_type']
            in_cond = hit['in_conditional']
            line_no = hit['line_no']
            rp      = raw.strip('"\'').replace('\\', '/')

            def _add_entry(path_str: str, source_label: str, conf_val: str,
                           note_str: str | None) -> dict:
                return {
                    'path':       path_str,
                    'raw':        raw,
                    'source':     source_label,
                    'confidence': conf_val,
                    'line_no':    line_no,
                    'note':       note_str,
                }

            def _classify(entry: dict, dest_in: list, dest_out: list,
                          dest_subdos: list, dest_cond: list) -> None:
                rel = entry['path']
                if iotype == 'subdo':
                    entry['note'] = 'sub-do dependency'
                    dest_subdos.append(entry)
                elif in_cond:
                    entry['note'] = f'inside conditional block (line {line_no})'
                    dest_cond.append(entry)
                elif iotype == 'input':
                    dest_in.append(entry)
                else:
                    if rel.startswith('temp/') or rel.startswith('temp\\'):
                        entry['temp_file'] = True
                    dest_out.append(entry)

            if not _has_macros(rp):
                # No macros: classify directly
                rel = _rel(rp, root)
                _classify(_add_entry(rel, 'direct', 'high', None),
                          inputs, outputs, subdos, conditionals)
            else:
                # Check tempfile names — if all macro refs are tempfiles, skip
                remaining = (
                    set(_RE_LOCAL_REF.findall(rp)) |
                    set(_RE_GLOBAL_REF.findall(rp))
                )
                if remaining and tempfile_names and remaining.issubset(tempfile_names):
                    continue

                matched = _match_log_paths(raw, log_paths_ne)
                if matched:
                    for expanded in matched:
                        rel = _rel(expanded, root)
                        _classify(
                            _add_entry(rel, 'log_match', 'medium',
                                       'expanded via log file match'),
                            inputs, outputs, subdos, conditionals,
                        )
                else:
                    # No log match — keep as-is with macro syntax
                    entry = _add_entry(rp, 'as_is', 'low',
                                       'unexpanded macro — verify manually')
                    if iotype in ('input', 'subdo'):
                        as_is_inputs.append(entry)
                    else:
                        as_is_outputs.append(entry)

        # Dedup
        def _dedup(lst: list[dict]) -> list[dict]:
            seen: set[str] = set()
            result2: list[dict] = []
            for e in lst:
                p = e.get('path', '')
                if p and p not in seen:
                    seen.add(p)
                    result2.append(e)
                elif not p:
                    result2.append(e)
            return result2

        inputs  = _dedup(inputs)
        outputs = _dedup(outputs)

        # Header cross-check
        cmd_ins  = {e['path'] for e in inputs}
        cmd_outs = {e['path'] for e in outputs}
        discrepancies: list[str] = []
        for p in set(hdr_inputs) - cmd_ins:
            discrepancies.append(f'header input not found in commands: {p}')
        for p in set(hdr_outputs) - cmd_outs:
            discrepancies.append(f'header output not found in commands: {p}')
        for p in cmd_ins - set(hdr_inputs):
            discrepancies.append(f'command input not in header: {p}')
        for p in cmd_outs - set(hdr_outputs):
            discrepancies.append(f'command output not in header: {p}')

        return {
            'path':                 str(path.relative_to(root)).replace('\\', '/'),
            '_full_path':           str(path),
            'inputs':               inputs,
            'outputs':              outputs,
            'subdo_deps':           subdos,
            'conditionals':         conditionals,
            'unresolved':           unresolved,
            'as_is_inputs':         as_is_inputs,
            'as_is_outputs':        as_is_outputs,
            'header_inputs':        hdr_inputs,
            'header_outputs':       hdr_outputs,
            'header_discrepancies': discrepancies,
            'depends_on':           [],
            'raw_file_deps':        [],
            'ado_deps':             [],
        }

    # --- Normal mode (macro expansion enabled) ---

    # W1: expand foreach literal loops — "foreach VAR in val1 val2 ..." becomes
    # one hit per value, substituting VAR with the concrete value. This catches
    # do-files that loop over a fixed list of output file stems.
    foreach_literals = _collect_foreach_literals(do_lines)
    hits = _expand_foreach_hits(hits, foreach_literals)

    hdr_inputs, hdr_outputs = parse_dofile_header(path)

    # Collect tempfile macro names — paths containing only these macros are
    # session-scoped scratch files and should not appear in the build graph.
    tempfile_names = _collect_tempfiles(do_lines)

    inputs:      list[dict] = []
    outputs:     list[dict] = []
    subdos:      list[dict] = []
    conditionals: list[dict] = []
    unresolved:  list[dict] = []
    as_is_inputs:  list[dict] = []   # only populated in no_expand_macros mode
    as_is_outputs: list[dict] = []   # only populated in no_expand_macros mode

    for hit in hits:
        raw    = hit['raw_path']
        iotype = hit['cmd_type']
        in_cond = hit['in_conditional']
        line_no = hit['line_no']

        resolved, source, conf = resolve_macros(
            raw, do_lines, setup_lines,
            log_txt_dir, log_smcl_dir,
            stat.st_mtime, base,
            line_no=line_no,
        )
        rel = _rel(resolved, root)

        # Skip entries whose unresolved macro refs are all known tempfile names.
        # These are Stata session-scoped scratch files, not persistent build products.
        if source == 'unresolved' or _has_macros(resolved):
            remaining = (
                set(_RE_LOCAL_REF.findall(resolved)) |
                set(_RE_GLOBAL_REF.findall(resolved))
            )
            if remaining and tempfile_names and remaining.issubset(tempfile_names):
                continue  # tempfile scratch — not a project dependency

        entry = {
            'path':       rel,
            'raw':        raw,
            'source':     source,
            'confidence': conf,
            'line_no':    line_no,
            'note':       None,
        }

        if iotype == 'subdo':
            entry['note'] = 'sub-do dependency'
            subdos.append(entry)
        elif source == 'unresolved' or _has_macros(resolved):
            entry['note']         = 'macro not resolved — verify manually'
            entry['cmd_type']     = iotype    # preserved for D3 retry
            entry['in_conditional'] = in_cond  # preserved for D3 retry
            unresolved.append(entry)
        elif in_cond:
            entry['note'] = f'inside conditional block (line {line_no})'
            conditionals.append(entry)
        elif iotype == 'input':
            inputs.append(entry)
        else:
            # Flag outputs whose resolved path falls under temp/ as scratch
            # files that should not appear in the SConstruct target list.
            if rel.startswith('temp/') or rel.startswith('temp\\'):
                entry['temp_file'] = True
            outputs.append(entry)

    # D3: foreach-override retry — for unresolved hits whose macros chain
    # transitively through a foreach loop variable (e.g. `filename_sim' is
    # defined as "`name_do'-sub`SUBSIDY'" inside a foreach loop), try each
    # foreach value combination as an additional macro override. If the path
    # resolves, promote it from unresolved to a proper input or output.
    if foreach_literals and unresolved:
        # Build all single-var override dicts (cross-product across all vars).
        combos: list[dict[str, str]] = [{}]
        for var_name, values in foreach_literals.items():
            new_combos: list[dict[str, str]] = []
            for combo in combos:
                for val in values:
                    new_combo = dict(combo)
                    new_combo[var_name] = val
                    new_combos.append(new_combo)
            combos = new_combos

        still_unresolved: list[dict] = []
        for entry in unresolved:
            raw       = entry['raw']
            line_no_e = entry['line_no']
            promoted  = False
            for combo in combos:
                resolved2, source2, conf2 = resolve_macros(
                    raw, do_lines, setup_lines,
                    log_txt_dir, log_smcl_dir,
                    stat.st_mtime, base,
                    line_no=line_no_e,
                    foreach_overrides=combo,
                )
                if _has_macros(resolved2):
                    continue  # still unresolved under this combo
                rel2   = _rel(resolved2, root)
                iotype = entry.get('cmd_type', 'input')  # preserved from hit
                in_cond_e = entry.get('in_conditional', False)
                new_entry = {
                    'path':       rel2,
                    'raw':        raw,
                    'source':     source2,
                    'confidence': conf2,
                    'line_no':    line_no_e,
                    'note':       f'foreach-override resolved (combo: {combo})',
                }
                if rel2.startswith('temp/') or rel2.startswith('temp\\'):
                    new_entry['temp_file'] = True
                    outputs.append(new_entry)
                elif in_cond_e:
                    conditionals.append(new_entry)
                elif iotype == 'input':
                    inputs.append(new_entry)
                else:
                    outputs.append(new_entry)
                promoted = True
            if not promoted:
                still_unresolved.append(entry)
        unresolved = still_unresolved

    # Deduplicate inputs and outputs by path (preserve first occurrence).
    def _dedup(lst: list[dict]) -> list[dict]:
        seen: set[str] = set()
        result: list[dict] = []
        for e in lst:
            p = e.get('path', '')
            if p and p not in seen:
                seen.add(p)
                result.append(e)
            elif not p:
                result.append(e)
        return result

    inputs  = _dedup(inputs)
    outputs = _dedup(outputs)

    # Header cross-check
    cmd_ins  = {e['path'] for e in inputs}
    cmd_outs = {e['path'] for e in outputs}
    discrepancies: list[str] = []
    for p in set(hdr_inputs) - cmd_ins:
        discrepancies.append(f'header input not found in commands: {p}')
    for p in set(hdr_outputs) - cmd_outs:
        discrepancies.append(f'header output not found in commands: {p}')
    for p in cmd_ins - set(hdr_inputs):
        discrepancies.append(f'command input not in header: {p}')
    for p in cmd_outs - set(hdr_outputs):
        discrepancies.append(f'command output not in header: {p}')

    return {
        'path':                 str(path.relative_to(root)).replace('\\', '/'),
        '_full_path':           str(path),   # stripped before YAML output
        'inputs':               inputs,
        'outputs':              outputs,
        'subdo_deps':           subdos,
        'conditionals':         conditionals,
        'unresolved':           unresolved,
        'as_is_inputs':         as_is_inputs,   # empty in normal mode
        'as_is_outputs':        as_is_outputs,  # empty in normal mode
        'header_inputs':        hdr_inputs,
        'header_outputs':       hdr_outputs,
        'header_discrepancies': discrepancies,
        'depends_on':           [],          # filled by build_dag
        'raw_file_deps':        [],          # filled by build_dag (D2)
        'ado_deps':             [],          # filled by assign_ado_deps
    }


# ===========================================================================
# 6.  Dependency graph
# ===========================================================================

def build_dag(manifest: dict, parsed: dict, root: Path) -> dict:
    """
    Fill 'depends_on' and 'raw_file_deps' for each do-file.

    'depends_on': other do-file keys whose outputs this task reads.
    'raw_file_deps': fully-resolved input paths NOT produced by any task
      (i.e. raw data files). These go into SConstruct depends= as literal
      strings rather than task-variable references.

    D1 note: we no longer exclude input/ paths from out_to_producer.  The
    original exclusion was meant to keep raw data from appearing as producers,
    but it also blocked legitimate cases where a task (e.g. dataprep.do) writes
    a processed dataset back into the input/ tree.  Raw data files are safe:
    they will never appear in out_to_producer because no do-file writes them.

    W3: After the main clean-path pass, also link via resolved conditional paths.
    """
    # D1: include ALL output paths — including input/-prefixed ones produced by
    # tasks such as dataprep.do. Raw data files never appear here because no
    # do-file writes them.
    out_to_producer: dict[str, str] = {}
    for key, result in parsed.items():
        for entry in result.get('outputs', []):
            p = entry['path']
            if p:
                out_to_producer[p] = key

    for key, result in parsed.items():
        deps: set[str] = set()
        raw_file_deps: set[str] = set()

        for entry in result.get('inputs', []):
            p = entry['path']
            if not p or _has_macros(p):
                continue
            producer = out_to_producer.get(p)
            if producer and producer != key:
                # D1: linked to the task that produces this file
                deps.add(producer)
            elif not producer and not p.startswith('temp/') and not p.startswith('temp\\'):
                # D2: no task produces this — it's a raw file dep
                raw_file_deps.add(p)

        for entry in result.get('subdo_deps', []):
            p = entry['path']
            if p:
                deps.add(p)

        # W3: conditional path pass — paths inside if/foreach blocks that are
        # fully resolved and match an unambiguous producer
        for entry in result.get('conditionals', []):
            p = entry.get('path', '')
            if p and not _has_macros(p):
                producer = out_to_producer.get(p)
                if producer and producer != key:
                    deps.add(producer)

        result['depends_on']    = sorted(deps)
        result['raw_file_deps'] = sorted(raw_file_deps)   # D2: new field

    return parsed


def topological_sort(parsed: dict) -> list[str]:
    """Return do-file keys in build order (Kahn's algorithm)."""
    in_deg: dict[str, int] = {k: 0 for k in parsed}
    adj:    dict[str, list] = {k: [] for k in parsed}

    for node, data in parsed.items():
        for dep in data.get('depends_on', []):
            if dep in adj:
                adj[dep].append(node)
                in_deg[node] += 1

    queue = sorted(k for k, d in in_deg.items() if d == 0)
    order: list[str] = []
    while queue:
        node = queue.pop(0)
        order.append(node)
        for nbr in sorted(adj[node]):
            in_deg[nbr] -= 1
            if in_deg[nbr] == 0:
                queue.append(nbr)

    # Remaining nodes (cycles or nodes not reachable from zero-in-degree roots)
    seen = set(order)
    order.extend(k for k in parsed if k not in seen)
    return order


# ===========================================================================
# 7.  Stata adopath helpers
# ===========================================================================

# Stata stores user-installed ado files in several standard locations.
# We always exclude (BASE) and (SITE) — those are Stata built-ins.
# By default we include (PERSONAL) and (PLUS); (OLDPLACE) is opt-in.

def _stata_default_paths() -> dict[str, Path]:
    """
    Return a dict of {adopath_type: Path} for the standard Stata user ado dirs.
    Paths that do not exist on this machine are still included (callers check).

    Standard Windows locations (Stata 16+):
      (PERSONAL)  %USERPROFILE%\\ado\\personal
      (PLUS)      %USERPROFILE%\\ado\\plus
      (OLDPLACE)  %USERPROFILE%\\ado
    Standard Unix locations:
      (PERSONAL)  ~/ado/personal
      (PLUS)      ~/ado/plus
      (OLDPLACE)  ~/ado
    """
    home = Path.home()
    return {
        'PERSONAL': home / 'ado' / 'personal',
        'PLUS':     home / 'ado' / 'plus',
        'OLDPLACE': home / 'ado',
    }


def collect_external_ado_dirs(
    include_personal: bool = True,
    include_plus: bool = True,
    include_oldplace: bool = False,
    extra_dirs: list[Path] | None = None,
) -> list[Path]:
    """
    Return the list of external ado directories to scan.
    BASE and SITE are always excluded.
    Paths that do not exist are silently skipped.
    """
    defaults = _stata_default_paths()
    candidates: list[Path] = []

    if include_personal:
        candidates.append(defaults['PERSONAL'])
    if include_plus:
        candidates.append(defaults['PLUS'])
    if include_oldplace:
        candidates.append(defaults['OLDPLACE'])
    if extra_dirs:
        candidates.extend(extra_dirs)

    return [p for p in candidates if p.exists() and p.is_dir()]


def scan_external_ado_dirs(dirs: list[Path]) -> list[Path]:
    """Recursively collect all .ado files under the given directories."""
    files: list[Path] = []
    for d in dirs:
        files.extend(sorted(d.rglob('*.ado')))
    return files


# ===========================================================================
# 8.  Ado-file detection
# ===========================================================================

def find_ado_files(manifest: dict, root: Path) -> list[str]:
    """Return project-local ado files (included groups) as root-relative paths."""
    return [
        str(f.relative_to(root)).replace('\\', '/')
        for f in manifest.get('ado_files', [])
    ]


def find_ado_groups(manifest: dict, root: Path) -> dict[str, list[str]]:
    """Return ado_groups as {group_name: [root-relative-path, ...]}."""
    result: dict[str, list[str]] = {}
    for grp_name, paths in manifest.get('ado_groups', {}).items():
        result[grp_name] = [str(f.relative_to(root)).replace('\\', '/') for f in paths]
    return result


def assign_ado_deps(
    parsed: dict,
    project_ados: list[str],
    external_ado_files: list[Path] | None = None,
) -> None:
    """
    Heuristic: for each do-file, record which ado programs it appears to call.

    project_ados        — root-relative paths of code/ado/**/*.ado (tracked deps)
    external_ado_files  — absolute Paths from PERSONAL/PLUS/etc. (for recognition
                          only; stored separately as 'external_ado_deps' and NOT
                          added to the ado_list in the SConstruct)
    """
    # Build maps: program_stem_lower → path_str
    proj_map: dict[str, str] = {Path(f).stem.lower(): f for f in project_ados}
    ext_map:  dict[str, str] = {}
    if external_ado_files:
        for f in external_ado_files:
            ext_map[f.stem.lower()] = str(f).replace('\\', '/')

    if not proj_map and not ext_map:
        return

    for key, result in parsed.items():
        full_path = result.get('_full_path')
        if not full_path:
            result['ado_deps']          = []
            result['external_ado_deps'] = []
            continue
        try:
            text = Path(full_path).read_text(encoding='utf-8', errors='replace').lower()
        except OSError:
            result['ado_deps']          = []
            result['external_ado_deps'] = []
            continue

        result['ado_deps'] = [
            path for name, path in proj_map.items()
            if re.search(r'\b' + re.escape(name) + r'\b', text)
        ]
        result['external_ado_deps'] = [
            path for name, path in ext_map.items()
            if re.search(r'\b' + re.escape(name) + r'\b', text)
        ]


# ===========================================================================
# 9.  Issue detection
# ===========================================================================

def detect_issues(parsed: dict) -> list[dict]:
    """Collect all cases that need user attention."""
    issues: list[dict] = []

    for key, result in parsed.items():
        for entry in result.get('unresolved', []):
            issues.append({
                'type':    'unresolved_macro',
                'dofile':  key,
                'raw':     entry.get('raw', ''),
                'line_no': entry.get('line_no'),
                'note':    entry.get('note', ''),
            })
        for entry in result.get('conditionals', []):
            issues.append({
                'type':    'conditional_path',
                'dofile':  key,
                'path':    entry.get('path', ''),
                'line_no': entry.get('line_no'),
                'note':    'path inside conditional/loop block — verify',
            })
        for disc in result.get('header_discrepancies', []):
            issues.append({
                'type':   'header_mismatch',
                'dofile': key,
                'detail': disc,
            })
        for entry in (result.get('as_is_inputs', []) +
                      result.get('as_is_outputs', [])):
            issues.append({
                'type':    'as_is_path',
                'dofile':  key,
                'path':    entry.get('path', ''),
                'line_no': entry.get('line_no'),
                'note':    entry.get('note', 'unexpanded macro added as-is'),
            })
        ins  = {e['path'] for e in result.get('inputs',  []) if e.get('path')}
        outs = {e['path'] for e in result.get('outputs', []) if e.get('path')}
        for p in ins & outs:
            issues.append({
                'type':   'inplace_modification',
                'dofile': key,
                'path':   p,
                'note':   'file appears as both input and output',
            })

    return issues


# ===========================================================================
# 10.  Write scan_results.yaml
# ===========================================================================

def _clean(obj):
    """Recursively convert for YAML output; drop internal _ keys."""
    if isinstance(obj, dict):
        return {k: _clean(v) for k, v in obj.items() if not k.startswith('_')}
    if isinstance(obj, list):
        return [_clean(v) for v in obj]
    if isinstance(obj, Path):
        return str(obj).replace('\\', '/')
    return obj


def write_scan_results(
    root: Path,
    parsed: dict,
    issues: list[dict],
    order: list[str],
    ado_files: list[str],
    ado_groups: dict[str, list[str]],
    external_ado_dirs: list[Path],
    outpath: Path,
    is_fragment: bool = False,
) -> None:
    ordered = [_clean(parsed[k]) for k in order if k in parsed]
    seen = set(order)
    ordered += [_clean(v) for k, v in parsed.items() if k not in seen]

    doc = {
        'project_root':       str(root).replace('\\', '/'),
        'scan_timestamp':     datetime.now(timezone.utc).isoformat(),
        'ado_files':          ado_files,
        'ado_groups':         ado_groups,
        'external_ado_dirs':  [str(d).replace('\\', '/') for d in external_ado_dirs],
        'dofiles':            ordered,
        'issues':             _clean(issues),
    }
    if is_fragment:
        doc['is_fragment'] = True
    with open(outpath, 'w', encoding='utf-8') as f:
        yaml.dump(doc, f, default_flow_style=False, allow_unicode=True, sort_keys=False)


# ===========================================================================
# 11.  Human-readable report
# ===========================================================================

def print_report(
    root: Path,
    parsed: dict,
    issues: list[dict],
    order: list[str],
    ado_files: list[str],
    ado_groups: dict[str, list[str]],
    external_ado_dirs: list[Path],
    testing_dofiles: list[Path],
) -> None:
    SEP = '=' * 62
    print(f'\n{SEP}')
    print(f'Stata project scan: {root}')
    print(SEP)
    print(f'  Task do-files : {len(parsed)}')
    if testing_dofiles:
        print(f'  Excluded (testing/util): {len(testing_dofiles)}'
              f'  (use --include-testing to add)')
        for f in testing_dofiles:
            print(f'    {f.name}')
    if ado_groups:
        print(f'  Ado groups    : {len(ado_groups)} group(s), {len(ado_files)} file(s) total')
        for grp, paths in ado_groups.items():
            label = f'code/ado/{grp}/' if grp != 'root' else 'code/ado/'
            print(f'    {grp:20s} {len(paths):3d} ado(s)  [{label}]')
    else:
        print(f'  Ado-files     : {len(ado_files)} (project, code/ado/)')
    if external_ado_dirs:
        n_ext = sum(
            len(result.get('external_ado_deps', []))
            for result in parsed.values()
        )
        print(f'  External ados : scanned {len(external_ado_dirs)} dir(s)'
              f' — {n_ext} usage(s) identified across do-files')
        for d in external_ado_dirs:
            print(f'    {d}')
    print(f'  Issues        : {len(issues)}')

    print('\nBuild order:')
    for i, key in enumerate(order, 1):
        r    = parsed.get(key, {})
        n_in = len(r.get('inputs', []))
        n_out= len(r.get('outputs', []))
        n_ur = len(r.get('unresolved', []))
        deps = [Path(d).stem for d in r.get('depends_on', [])]
        flag = '  [!] unresolved macros' if n_ur else ''
        dep_str = f'  <- {", ".join(deps)}' if deps else ''
        print(f'  {i:2d}. {key}  ({n_in} in, {n_out} out){flag}{dep_str}')

    if issues:
        print(f'\nIssues ({len(issues)}):')
        by_type: dict[str, list] = {}
        for iss in issues:
            by_type.setdefault(iss['type'], []).append(iss)
        for itype, items in sorted(by_type.items()):
            print(f'  {itype} — {len(items)} case(s):')
            for item in items[:4]:
                detail = item.get('raw') or item.get('detail') or item.get('path') or ''
                print(f'    * {item["dofile"]}: {detail}')
            if len(items) > 4:
                print(f'    ... and {len(items) - 4} more')
    else:
        print('\nNo issues found.')

    print()


# ===========================================================================
# 12.  Main
# ===========================================================================

def main() -> None:
    ap = argparse.ArgumentParser(
        description='Scan a Stata project and produce scan_results.yaml',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument('project_root', help='Root directory of the Stata project')
    ap.add_argument('--out', default=None,
                    help='Output YAML file or directory. If a directory is given, '
                         'scan_results.yaml is saved inside it. '
                         '(default: <project_root>/scan_results.yaml)')
    ap.add_argument('--log-txt-dir', default=None,
                    help='Plain-text log directory (default: <root>/output/log/log)')
    ap.add_argument('--log-smcl-dir', default=None,
                    help='SMCL log directory (default: <root>/output/log/smcl)')
    ap.add_argument('--include-testing', action='store_true', default=False,
                    help='Include testing_*.do and _*.do files as build tasks'
                         ' (excluded by default)')
    ap.add_argument('-f', '--file', metavar='DO_FILE', nargs='+', default=[],
                    help='Restrict scan to these do-file(s). Match by filename, '
                         'relative path, or absolute path. Marks the YAML with '
                         'is_fragment: true so gen_sconstruct.py uses Fragment naming.')

    # Adopath options — BASE and SITE always excluded
    ado_grp = ap.add_argument_group(
        'adopath options',
        'Control which Stata ado paths are scanned for external packages.\n'
        'BASE and SITE (Stata built-ins) are always excluded.\n'
        'Default: include PERSONAL and PLUS; exclude OLDPLACE.',
    )
    ado_grp.add_argument('--no-personal', action='store_true', default=False,
                         help='Exclude Stata PERSONAL ado path')
    ado_grp.add_argument('--no-plus', action='store_true', default=False,
                         help='Exclude Stata PLUS ado path')
    ado_grp.add_argument('--include-oldplace', action='store_true', default=False,
                         help='Include Stata OLDPLACE ado path')
    ado_grp.add_argument('--extra-ado', metavar='DIR', action='append', default=[],
                         help='Additional ado directory to scan (repeatable)')

    # Project ado-file group options
    proj_ado_grp = ap.add_argument_group(
        'project ado options',
        'Control which subsets of code/ado/ are included as dependency groups.\n'
        'By default all ado files in code/ado/ (root and all subdirs) are included.\n'
        'Each subdirectory (e.g. code/ado/policy_simulations/) forms a named group.',
    )
    proj_ado_grp.add_argument('--no-ado-root', action='store_true', default=False,
                              help='Exclude code/ado/*.ado (root-level ados)')
    proj_ado_grp.add_argument('--no-ado-subdir', metavar='NAME', action='append',
                              default=[],
                              help='Exclude a named code/ado/<NAME>/ subdir (repeatable)')

    ap.add_argument('--quiet', action='store_true',
                    help='Suppress stdout report')
    ap.add_argument('--no-expand-macros', action='store_true', default=False,
                    help='Skip Python-side macro resolution; look in log file for '
                         'expanded paths instead. Unmatched macro paths are written '
                         'as-is (with unexpanded macros) to the SConstruct.')
    args = ap.parse_args()

    root = Path(args.project_root).resolve()
    if not root.is_dir():
        print(f'Error: not a directory: {root}', file=sys.stderr)
        sys.exit(1)

    out_path_raw = Path(args.out) if args.out else root
    out_path     = (out_path_raw / 'scan_results.yaml') if out_path_raw.is_dir() else out_path_raw
    log_txt_dir  = Path(args.log_txt_dir)  if args.log_txt_dir  else root / 'output' / 'log' / 'log'
    log_smcl_dir = Path(args.log_smcl_dir) if args.log_smcl_dir else root / 'output' / 'log' / 'smcl'

    extra_ado_dirs    = [Path(d) for d in args.extra_ado]
    exclude_ado_subdirs = set(args.no_ado_subdir)

    print('Scanning directory...', file=sys.stderr)
    manifest = scan_directory(
        root,
        include_testing=args.include_testing,
        exclude_ado_root=args.no_ado_root,
        exclude_ado_subdirs=exclude_ado_subdirs,
    )

    # --file: restrict scan to specified do-files
    is_fragment = False
    if args.file:
        specs = [Path(s).resolve() for s in args.file]
        spec_names = {Path(s).name for s in args.file}

        def _matches_spec(dofile_path: Path) -> bool:
            if dofile_path.name in spec_names:
                return True
            if dofile_path.resolve() in specs:
                return True
            # relative path match (e.g. 'code/dataprep.do')
            for s in args.file:
                try:
                    if dofile_path == root / s:
                        return True
                except Exception:
                    pass
            return False

        original_count = len(manifest['task_dofiles'])
        manifest['task_dofiles'] = [f for f in manifest['task_dofiles'] if _matches_spec(f)]
        n_selected = len(manifest['task_dofiles'])
        print(f'--file filter: {n_selected} of {original_count} do-file(s) selected.',
              file=sys.stderr)
        if n_selected == 0:
            print('Warning: no do-files matched the --file specification. '
                  'Check filenames and paths.', file=sys.stderr)
        is_fragment = True

    # Report excluded testing files
    n_testing = len(manifest.get('testing_dofiles', []))
    if n_testing and not args.include_testing:
        print(f'Excluded {n_testing} testing/utility do-file(s)'
              f' (use --include-testing to include):', file=sys.stderr)
        for f in manifest['testing_dofiles']:
            print(f'  {f.name}', file=sys.stderr)

    # Report ado groups found
    ado_groups_manifest = manifest.get('ado_groups', {})
    if ado_groups_manifest:
        print(f'Ado groups ({len(ado_groups_manifest)}):',  file=sys.stderr)
        for grp, paths in ado_groups_manifest.items():
            label = f'code/ado/{grp}/' if grp != 'root' else 'code/ado/'
            print(f'  {grp:20s} {len(paths):3d} file(s)  [{label}]', file=sys.stderr)
    else:
        print('No project ado files found in code/ado/.', file=sys.stderr)

    # Collect external ado dirs (PERSONAL/PLUS/OLDPLACE as requested)
    external_ado_dirs = collect_external_ado_dirs(
        include_personal=not args.no_personal,
        include_plus=not args.no_plus,
        include_oldplace=args.include_oldplace,
        extra_dirs=extra_ado_dirs,
    )
    if external_ado_dirs:
        print(f'External ado paths ({len(external_ado_dirs)}):',  file=sys.stderr)
        for d in external_ado_dirs:
            print(f'  {d}', file=sys.stderr)
    else:
        print('No external ado paths found (PERSONAL/PLUS dirs do not exist).',
              file=sys.stderr)

    external_ado_files = scan_external_ado_dirs(external_ado_dirs)
    if external_ado_files:
        print(f'  Found {len(external_ado_files)} external .ado file(s).', file=sys.stderr)

    setup_lines = _load_setup_lines(manifest['setup_dofiles'])

    n = len(manifest['task_dofiles'])
    print(f'Parsing {n} do-file(s)...', file=sys.stderr)
    parsed: dict[str, dict] = {}
    for dofile in manifest['task_dofiles']:
        result = parse_dofile(dofile, setup_lines, log_txt_dir, log_smcl_dir, root,
                              no_expand_macros=args.no_expand_macros)
        if result:
            parsed[result['path']] = result

    project_ados  = find_ado_files(manifest, root)
    project_groups = find_ado_groups(manifest, root)
    assign_ado_deps(parsed, project_ados, external_ado_files)

    print('Building dependency graph...', file=sys.stderr)
    build_dag(manifest, parsed, root)
    order  = topological_sort(parsed)
    issues = detect_issues(parsed)

    if not args.quiet:
        print_report(root, parsed, issues, order, project_ados, project_groups,
                     external_ado_dirs, manifest.get('testing_dofiles', []))

    print(f'Writing {out_path}...', file=sys.stderr)
    write_scan_results(root, parsed, issues, order, project_ados, project_groups,
                       external_ado_dirs, out_path, is_fragment=is_fragment)
    print('Done. Review scan_results.yaml, then run gen_sconstruct.py.', file=sys.stderr)


if __name__ == '__main__':
    main()
