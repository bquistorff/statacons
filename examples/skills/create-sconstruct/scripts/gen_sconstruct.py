#!/usr/bin/env python3
"""
gen_sconstruct.py — SConstruct generator for Stata projects

Reads scan_results.yaml (produced by scan_project.py, possibly edited by the
user) and writes a draft SConstruct — and optionally SConscript files — that
follow the conventions in Statacons-habits.md.

Usage:
    python gen_sconstruct.py <scan_results.yaml> [options]

Options:
    -d, --draft         Write SConstructDraft / [name]Draft.SConscript instead of
                        SConstruct / [name].SConscript (default: off; auto-prompted
                        when existing build files are found in the output directory)
    -f, --file DO_FILE  Restrict output to these do-file(s) (repeatable or
                        space-separated). Match by filename or relative path. Forces
                        Fragment naming (SConstructFragment / [name]Fragment.SConscript)
                        and refuses to overwrite existing Fragment files. Also
                        auto-triggered when scan_results.yaml has is_fragment: true.
    --sconscripts   Also write one SConscript per task group
    --out DIR       Output directory (default: project_root from YAML)
    --no-ado-list   Omit all ado deps from depends= lines
"""

import argparse
import re
import sys
from pathlib import Path

import yaml


# ===========================================================================
# 1.  Task grouping
# ===========================================================================

# (group_name, [keyword_substrings_that_match_do-file-stem])
_GROUPS = [
    ('Dataprep',   ['dataprep', 'clean', 'import', 'build', 'prep', 'construct', 'merge',
                    'append', 'reshape', 'recode', 'deflat']),
    ('Estimation', ['estimat', 'regress', 'gmm', 'iv', 'ols', 'fe', 'probit', 'logit',
                    'event', 'did', 'diff', 'rdrobust', 'spec']),
    ('Simulation', ['sim', 'simulat', 'monte', 'boot', 'permut']),
    ('TabFig',     ['tabfig', 'table', 'figure', 'fig', 'tab', 'plot', 'graph', 'bar',
                    'scatter', 'descstat', 'sumstat', 'balance']),
    ('Appendix',   ['appendix', 'robust', 'sensitivity', 'placebo', 'hetero']),
]


def group_tasks(dofiles: list[dict]) -> dict[str, list[dict]]:
    """
    Assign each do-file to the first matching group.
    Unmatched files go to 'Main'.
    Returns an ordered dict (groups with no members are omitted).
    """
    buckets: dict[str, list[dict]] = {g[0]: [] for g in _GROUPS}
    buckets['Main'] = []

    for df in dofiles:
        stem = re.sub(r'[-.]', '_', Path(df['path']).stem).lower()
        placed = False
        for grp_name, keywords in _GROUPS:
            if any(kw in stem for kw in keywords):
                buckets[grp_name].append(df)
                placed = True
                break
        if not placed:
            buckets['Main'].append(df)

    return {k: v for k, v in buckets.items() if v}


# ===========================================================================
# 1b. Topological sort
# ===========================================================================

def topo_sort_dofiles(dofiles: list[dict], all_parsed: dict) -> list[dict]:
    """Return dofiles in topological order (dependencies before dependents).

    Uses Kahn's algorithm with the original list position as a tiebreaker so
    that tasks with no ordering constraint stay close to their original position.
    Cycles (which should not occur in a valid Stata project) are broken by
    appending cycle members in their original order at the end, with a
    # WARNING comment inserted by the caller.
    Only edges whose upstream path is actually in `all_parsed` (i.e. is itself
    a task, not a raw input file) are considered.
    """
    import heapq

    path_to_df = {df['path']: df for df in dofiles}
    original_pos = {df['path']: i for i, df in enumerate(dofiles)}

    # Build: for each task path, who depends on it (successors)?
    in_degree: dict[str, int] = {df['path']: 0 for df in dofiles}
    successors: dict[str, list[str]] = {df['path']: [] for df in dofiles}

    for df in dofiles:
        for dep_path in df.get('depends_on', []):
            if dep_path in path_to_df:          # upstream is also a task
                successors[dep_path].append(df['path'])
                in_degree[df['path']] += 1

    # Kahn's: start with all nodes that have no in-task dependencies
    heap: list[tuple[int, str]] = []
    for path, deg in in_degree.items():
        if deg == 0:
            heapq.heappush(heap, (original_pos[path], path))

    result: list[dict] = []
    while heap:
        _, path = heapq.heappop(heap)
        result.append(path_to_df[path])
        for succ in successors[path]:
            in_degree[succ] -= 1
            if in_degree[succ] == 0:
                heapq.heappush(heap, (original_pos[succ], succ))

    # Any remaining nodes form a cycle — append in original order
    if len(result) < len(dofiles):
        emitted = {df['path'] for df in result}
        result.extend(df for df in dofiles if df['path'] not in emitted)

    return result


def topo_sort_groups(
    groups: dict[str, list[dict]],
    all_parsed: dict,
) -> dict[str, list[dict]]:
    """Return groups (and tasks within each group) in dependency order.

    1. Tasks within each group are topo-sorted using topo_sort_dofiles.
    2. Groups themselves are topo-sorted: if any task in group A depends on
       a task in group B, group A must be emitted after group B.
    3. Unresolvable cross-group forward references (after group reordering)
       are flagged by setting a '_cross_group_fwd_refs' key on affected tasks.
    """
    import heapq

    # Step 1 — sort tasks within each group
    sorted_groups: dict[str, list[dict]] = {
        grp: topo_sort_dofiles(dofiles, all_parsed)
        for grp, dofiles in groups.items()
    }

    # Step 2 — build group-level dependency graph
    path_to_group: dict[str, str] = {
        df['path']: grp
        for grp, dofiles in sorted_groups.items()
        for df in dofiles
    }
    group_names = list(sorted_groups.keys())
    grp_pos = {g: i for i, g in enumerate(group_names)}

    grp_in_degree: dict[str, int] = {g: 0 for g in group_names}
    grp_successors: dict[str, list[str]] = {g: [] for g in group_names}
    seen_grp_edges: set[tuple[str, str]] = set()

    for grp, dofiles in sorted_groups.items():
        for df in dofiles:
            for dep_path in df.get('depends_on', []):
                upstream_grp = path_to_group.get(dep_path)
                if upstream_grp and upstream_grp != grp:
                    edge = (upstream_grp, grp)  # upstream must come before grp
                    if edge not in seen_grp_edges:
                        seen_grp_edges.add(edge)
                        grp_successors[upstream_grp].append(grp)
                        grp_in_degree[grp] += 1

    heap = [(grp_pos[g], g) for g, d in grp_in_degree.items() if d == 0]
    heapq.heapify(heap)
    ordered_group_names: list[str] = []
    while heap:
        _, g = heapq.heappop(heap)
        ordered_group_names.append(g)
        for succ in grp_successors[g]:
            grp_in_degree[succ] -= 1
            if grp_in_degree[succ] == 0:
                heapq.heappush(heap, (grp_pos[succ], succ))

    # Cycle fallback — append remaining groups in original order
    emitted_grps = set(ordered_group_names)
    for g in group_names:
        if g not in emitted_grps:
            ordered_group_names.append(g)

    result = {g: sorted_groups[g] for g in ordered_group_names}

    # Step 3 — flag any cross-group forward references that remain
    # (can only occur in cycles, which we cannot fix by reordering)
    emit_pos: dict[str, int] = {}   # path -> position in final flat order
    flat_pos = 0
    for grp in ordered_group_names:
        for df in result[grp]:
            emit_pos[df['path']] = flat_pos
            flat_pos += 1

    for grp in ordered_group_names:
        for df in result[grp]:
            fwd: list[str] = []
            for dep_path in df.get('depends_on', []):
                if dep_path in emit_pos and emit_pos[dep_path] >= emit_pos[df['path']]:
                    fwd.append(dep_path)
            if fwd:
                df.setdefault('_cross_group_fwd_refs', []).extend(fwd)

    return result


# ===========================================================================
# 2.  Variable-name generation
# ===========================================================================

_RE_INVALID = re.compile(r'[^a-zA-Z0-9_]')
_RE_LEADING = re.compile(r'^[0-9]')
_RE_HAS_MACRO = re.compile(r'[`$]')


def make_varname(dofile_path: str) -> str:
    """Convert a do-file path to a valid Python identifier."""
    stem = Path(dofile_path).stem
    name = _RE_INVALID.sub('_', stem)
    if _RE_LEADING.match(name):
        name = '_' + name
    return name


def _ado_varname(group_key: str) -> str:
    """Convert an ado group key to a Python variable name.

    'root'                -> 'ado_root'
    'policy_simulations'  -> 'ado_policy_simulations'
    """
    clean = _RE_INVALID.sub('_', group_key) if group_key else 'root'
    return f'ado_{clean}'


def _ado_glob_pattern(group_key: str) -> str:
    """Return the Glob pattern string for a given ado group."""
    if not group_key or group_key == 'root':
        return 'code/ado/*.ado'
    return f'code/ado/{group_key}/*.ado'


def _groups_for_task(df: dict, ado_groups: dict[str, list[str]]) -> list[str]:
    """
    Determine which ado group variable names a task needs in its depends=.

    If the task has detected ado_deps, map each dep path to its group.
    If no deps are detected, fall back to all available groups (safe default).
    Returns list of Python variable names, sorted for deterministic output.
    """
    if not ado_groups:
        return []

    task_ado_deps = df.get('ado_deps', [])
    if task_ado_deps:
        used: set[str] = set()
        for dep_path in task_ado_deps:
            parts = Path(dep_path.replace('\\', '/')).parts
            # Expected: ('code', 'ado', [subdir/...,] 'file.ado')
            if len(parts) >= 3 and parts[0] == 'code' and parts[1] == 'ado':
                grp = parts[2] if len(parts) > 3 else 'root'
            else:
                grp = 'root'
            if grp in ado_groups:
                used.add(grp)
        return [_ado_varname(g) for g in sorted(used)]

    # No detected ado deps → use all groups (conservative fallback)
    return [_ado_varname(g) for g in sorted(ado_groups.keys())]


# ===========================================================================
# 3.  Formatting helpers
# ===========================================================================

# Alignment: 'depends' is longest keyword at 7 chars; pad all to 8.
_KW = 8       # keyword + padding width before '='
_INDENT = '    '
# Opening bracket column: 4 (indent) + 8 (kw) + 2 ('= ') + 1 ('[') = 15
_CONT = ' ' * 15


def _fmt_list(paths: list[str]) -> str:
    """Format a Python list of quoted path strings."""
    if not paths:
        return '[]'
    if len(paths) == 1:
        return f"['{paths[0]}']"
    # Multi-line: first item on same line, rest aligned under '['
    items = [f"'{p}'" for p in paths]
    sep = ',\n' + _CONT
    return '[' + sep.join(items) + ']'


def _fmt_depends(dep_parts: list[str]) -> str:
    """
    Format a depends= expression from a list of fragments.
    Each fragment is either a bare variable name ('ado_root', 'dataprep')
    or an already-quoted/wrapped expression ("[dataprep]", "['code/subdo/x.do']").
    Returns '[]' when the list is empty (no known dependencies).
    """
    if not dep_parts:
        return '[]'
    return ' + '.join(dep_parts)


def _kv(key: str, val: str, comma: bool = True) -> str:
    """One key = value line with standard alignment."""
    c = ',' if comma else ''
    return f"{_INDENT}{key:<{_KW}}= {val}{c}"


# ===========================================================================
# 4.  StataBuild entry generator
# ===========================================================================

def _dofile_entry(
    df: dict,
    all_parsed: dict,
    ado_groups: dict[str, list[str]],
    include_ado: bool = True,
) -> str:
    """
    Generate a StataBuild(...) block for one do-file, following the conventions
    in Statacons-habits.md:
      - 4-space indent, aligned = (target  =, source  =, depends =)
      - depends= kwarg (never Depends())
      - task variable names from do-file stem
    """
    varname = make_varname(df['path'])

    # Target list: exclude unresolved macros, low-confidence entries,
    # and temp/ scratch files (temp_file: True).
    targets = [
        e['path'] for e in df.get('outputs', [])
        if e.get('path')
        and e.get('confidence') != 'low'
        and not _RE_HAS_MACRO.search(e.get('path', ''))
        and not e.get('temp_file', False)
    ]
    # Low-confidence, macro-containing, or temp_file outputs flagged as TODO
    low_conf = [
        e['path'] for e in df.get('outputs', [])
        if e.get('path') and (
            e.get('confidence') == 'low'
            or _RE_HAS_MACRO.search(e.get('path', ''))
            or e.get('temp_file', False)
        )
    ]

    # as_is_outputs: paths with unexpanded macros from --no-expand-macros mode.
    # Added verbatim to the target list (user must verify).
    as_is_out_paths = [e['path'] for e in df.get('as_is_outputs', []) if e.get('path')]
    as_is_in_paths  = [e['path'] for e in df.get('as_is_inputs',  []) if e.get('path')]
    targets.extend(as_is_out_paths)

    log_placeholder = False
    if not targets:
        # No reliable outputs — use log SMCL as placeholder
        stem = Path(df['path']).stem
        targets = [f'output/log/smcl/{stem}.smcl']
        log_placeholder = True

    # Source: the do-file itself
    sources = [df['path']]

    # Depends: ado_group_vars + ['raw_file_deps'] + [prev_task_vars] + ['subdo/paths']
    dep_parts: list[str] = []
    if include_ado:
        dep_parts.extend(_groups_for_task(df, ado_groups))

    # D2: raw file inputs (not produced by any task) as literal string deps
    for raw_path in df.get('raw_file_deps', []):
        dep_parts.append(f"['{raw_path}']")

    for dep_do in df.get('depends_on', []):
        # Only wrap in [...] if it is a task do-file (not a subdo)
        if dep_do in all_parsed:
            dep_parts.append(f'[{make_varname(dep_do)}]')

    for entry in df.get('subdo_deps', []):
        p = entry.get('path', '')
        # Skip setup files (code/setup/) — they are boilerplate, not task deps
        if p and 'setup' not in p.lower():
            dep_parts.append(f"['{p}']")

    # as_is_inputs: unexpanded-macro input paths from --no-expand-macros mode.
    for p in as_is_in_paths:
        dep_parts.append(f'["{p}"]')

    target_str = _fmt_list(targets)
    source_str = _fmt_list(sources)
    dep_str    = _fmt_depends(dep_parts)

    lines: list[str] = []

    # WARNING for cross-group forward references that could not be fixed by reordering
    fwd_refs = df.get('_cross_group_fwd_refs', [])
    if fwd_refs:
        ref_names = ', '.join(make_varname(p) for p in fwd_refs)
        lines.append(
            f'# WARNING: {varname} depends on [{ref_names}] which could not be '
            f'moved before this task (likely a dependency cycle). '
            f'Move one of these tasks manually.'
        )

    # TODO comments for issues
    n_unr = len(df.get('unresolved', []))
    if n_unr:
        lines.append(f'# TODO: {n_unr} unresolved path(s) in this do-file — see scan_results.yaml')
    if as_is_out_paths:
        lines.append(f'# TODO: target(s) contain unexpanded macro(s) — verify: '
                     f'{", ".join(as_is_out_paths)}')
    if as_is_in_paths:
        lines.append(f'# TODO: dep(s) contain unexpanded macro(s) — verify: '
                     f'{", ".join(as_is_in_paths)}')
    if low_conf:
        temp_out = [p for p in low_conf if not _RE_HAS_MACRO.search(p)]
        macro_out = [p for p in low_conf if _RE_HAS_MACRO.search(p)]
        if temp_out:
            lines.append(f'# NOTE: temp/ outputs omitted from target (scratch files): {", ".join(temp_out)}')
        if macro_out:
            lines.append(f'# TODO: low-confidence outputs — verify: {", ".join(macro_out)}')
    if log_placeholder:
        lines.append('# TODO: no outputs detected — using log as placeholder; update target')

    lines += [
        f'{varname} = env.StataBuild(',
        _kv('target',  target_str),
        _kv('source',  source_str),
        _kv('depends', dep_str, comma=False),
        ')',
    ]

    return '\n'.join(lines)


# ===========================================================================
# 5.  SConstruct generator
# ===========================================================================

_SCONSTRUCT_HEADER = """\
import os
from pystatacons import init_env

env = init_env()

# **** Setup and configuration *****
"""


def _ado_setup_lines(ado_groups: dict[str, list[str]]) -> str:
    """Generate the ado-list variable declarations for the SConstruct setup section."""
    if not ado_groups:
        return ''
    lines: list[str] = []
    for grp_key in sorted(ado_groups.keys()):
        varname = _ado_varname(grp_key)
        pattern = _ado_glob_pattern(grp_key)
        lines.append(f"{varname} = [f for f in Glob('{pattern}', strings=True)]")
    return '\n'.join(lines)


def generate_sconstruct(
    dofiles: list[dict],
    all_parsed: dict,
    ado_groups: dict[str, list[str]],
    groups: dict[str, list[dict]],
    use_sconscripts: bool,
    include_ado: bool = True,
    ordered_groups: 'dict[str, list[dict]] | None' = None,
) -> str:
    """Generate SConstruct content (inline or SConscript-based).

    When use_sconscripts=True, pass ordered_groups (from topo_sort_groups) to
    avoid calling topo_sort_groups a second time and accidentally duplicating
    the _cross_group_fwd_refs side-effect.
    """
    lines = [_SCONSTRUCT_HEADER.rstrip()]

    # Ado group variable declarations
    if include_ado and ado_groups:
        lines.append('')
        lines.append(_ado_setup_lines(ado_groups))

    lines.append('')
    lines.append('# **** Substance begins        *****')

    if use_sconscripts:
        # Delegate to SConscript files — order groups by dependency.
        # Use pre-computed ordered_groups when available so that
        # topo_sort_groups (which mutates dofile dicts) is called only once.
        if ordered_groups is None:
            ordered_groups = topo_sort_groups(groups, all_parsed)
        lines.append('')
        for grp_name in ordered_groups:
            lines.append(f"SConscript('{grp_name}.SConscript', exports='env')")
        lines.append('')
        lines.append("Import('*')")
        lines.append('')
        # Default: concatenate all group target lists in load order
        all_grp = [f"{g.lower()}_targets" for g in ordered_groups]
        default_arg = ' + '.join(all_grp) if all_grp else '[]'
        lines.append(f'env.Default({default_arg})')

    else:
        # Inline all tasks — topo-sort globally so every variable is defined
        # before it is referenced, regardless of which keyword group it belongs to.
        # Group headers are emitted whenever the group label changes.
        path_to_group: dict[str, str] = {
            df['path']: grp
            for grp, grp_dofiles in groups.items()
            for df in grp_dofiles
        }
        sorted_dofiles = topo_sort_dofiles(dofiles, all_parsed)
        all_varnames: list[str] = []
        current_grp: str | None = None

        for df in sorted_dofiles:
            grp = path_to_group.get(df['path'], 'Main')
            if len(groups) > 1 and grp != current_grp:
                lines.append(f'\n# ---- {grp} ----')
                current_grp = grp
            lines.append('')
            lines.append(_dofile_entry(df, all_parsed, ado_groups,
                                       include_ado=include_ado))
            all_varnames.append(make_varname(df['path']))

        lines.append('')
        if len(all_varnames) <= 6:
            default_arg = ', '.join(all_varnames)
        else:
            pad = ',\n    '
            default_arg = '\n    ' + pad.join(all_varnames) + '\n'
        lines.append(f'env.Default({default_arg})')

    return '\n'.join(lines) + '\n'


# ===========================================================================
# 6.  SConscript generator
# ===========================================================================

def generate_sconscript(
    grp_name: str,
    dofiles: list[dict],
    all_parsed: dict,
    ado_groups: dict[str, list[str]],
    include_ado: bool = True,
) -> str:
    """Generate one SConscript for a task group.

    Tasks are emitted in topological order within the group so that
    intra-group forward references are eliminated.  Any remaining
    cross-group forward references (cannot be fixed by intra-group sorting)
    are surfaced as # WARNING comments by _dofile_entry.
    """
    sorted_dofiles = topo_sort_dofiles(dofiles, all_parsed)

    lines = [
        f"# {grp_name}.SConscript",
        '',
        "Import('env')",
        '',
    ]

    varnames: list[str] = []
    for df in sorted_dofiles:
        lines.append(_dofile_entry(df, all_parsed, ado_groups, include_ado=include_ado))
        lines.append('')
        varnames.append(make_varname(df['path']))

    # Group target list and Export
    grp_list_name = f'{grp_name.lower()}_targets'
    if len(varnames) <= 6:
        targets_expr = ' + '.join(f'[{vn}]' for vn in varnames)
    else:
        pad = ' +\n    '
        targets_expr = pad.join(f'[{vn}]' for vn in varnames)

    lines.append(f'{grp_list_name} = {targets_expr}')
    lines.append(f"Export(['{grp_list_name}'])")

    return '\n'.join(lines) + '\n'


# ===========================================================================
# 7.  Main
# ===========================================================================

def main() -> None:
    ap = argparse.ArgumentParser(
        description='Generate SConstruct from scan_results.yaml',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument('scan_results', nargs='?', default=None,
                    help='Path to scan_results.yaml. If omitted, looks for '
                         'scan_results.yaml in the --out directory (default: project root).')
    ap.add_argument('--sconscripts', action='store_true',
                    help='Also generate per-group SConscript files')
    ap.add_argument('--out', default=None,
                    help='Output directory (default: project_root from YAML)')
    ap.add_argument('--no-ado-list', action='store_true',
                    help='Omit all ado deps from depends= lines')
    ap.add_argument('--no-track-ado-plus', action='store_true',
                    help='Exclude ado_plus group from all depends= lines')
    ap.add_argument('--no-track-ado-personal', action='store_true',
                    help='Exclude ado_personal group from all depends= lines')
    ap.add_argument('--no-track-ado', action='store_true',
                    help='Exclude ALL external ado groups (combines --no-track-ado-plus '
                         'and --no-track-ado-personal)')
    ap.add_argument('-d', '--draft', action='store_true', default=False,
                    help='Write SConstructDraft and [name]Draft.SConscript instead of '
                         'SConstruct and [name].SConscript. Enabled automatically '
                         'when existing build files are found in the output directory.')
    ap.add_argument('-f', '--file', metavar='DO_FILE', nargs='+', default=[],
                    help='Restrict output to these do-file(s). Match by filename or '
                         'relative path. Forces Fragment naming (SConstructFragment / '
                         '[name]Fragment.SConscript). Existing Fragment files are '
                         'never overwritten.')
    args = ap.parse_args()

    # Resolve scan_results.yaml path.
    # If not given explicitly, look for it in the --out directory.
    # This means a single --out DIR for both scan_project.py and gen_sconstruct.py
    # keeps scan_results.yaml co-located with SConstruct.draft.
    if args.scan_results:
        yaml_path = Path(args.scan_results)
    else:
        search_dir = Path(args.out) if args.out else Path('.')
        yaml_path = search_dir / 'scan_results.yaml'
        if not yaml_path.exists():
            ap.error(f'scan_results.yaml not found in {search_dir}. '
                     f'Pass the path explicitly or run scan_project.py --out {search_dir} first.')

    with open(yaml_path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)

    root_str = data.get('project_root', '.')
    root     = Path(root_str)
    out_dir  = Path(args.out) if args.out else root
    out_dir.mkdir(parents=True, exist_ok=True)

    # Determine draft mode: use flag, or prompt when existing build files are found.
    # Skip this block entirely when fragment_mode is active (Fragment naming wins).
    draft_mode = args.draft
    if not fragment_mode and not draft_mode:
        existing = (
            [out_dir / 'SConstruct'] if (out_dir / 'SConstruct').exists() else []
        ) + sorted(out_dir.glob('*.SConscript'))
        if existing:
            names = ', '.join(f.name for f in existing[:3])
            if len(existing) > 3:
                names += f', ... ({len(existing)} total)'
            print(f'Existing build file(s) found in {out_dir}:  {names}')
            resp = input(
                'Write as draft (SConstructDraft / [name]Draft.SConscript)? [Y/n] '
            ).strip().lower()
            draft_mode = resp not in ('n', 'no')

    dofiles= data.get('dofiles', [])
    ado_files  = data.get('ado_files', [])
    ado_groups = data.get('ado_groups', {})
    issues     = data.get('issues', [])

    # Fragment mode: triggered by --file or is_fragment: true in the YAML.
    # Fragment naming (SConstructFragment / [name]Fragment.SConscript) takes
    # precedence over draft naming.  Existing Fragment files are never overwritten.
    fragment_mode = bool(args.file) or data.get('is_fragment', False)
    if fragment_mode and args.file:
        spec_names = {Path(s).name for s in args.file}
        spec_rel   = {s.replace('\\', '/') for s in args.file}

        def _matches_file_spec(df: dict) -> bool:
            p = df.get('path', '')
            if Path(p).name in spec_names:
                return True
            if p in spec_rel or p.replace('\\', '/') in spec_rel:
                return True
            return False

        original_count = len(dofiles)
        dofiles = [df for df in dofiles if _matches_file_spec(df)]
        print(f'--file filter: {len(dofiles)} of {original_count} do-file(s) selected.')

    # Remove user-requested groups from ado_groups before passing downstream.
    # This means they won't appear in setup variable declarations or depends= lines.
    skip_ado = set()
    if args.no_track_ado or args.no_track_ado_plus:
        skip_ado.add('plus')
    if args.no_track_ado or args.no_track_ado_personal:
        skip_ado.add('personal')
    if skip_ado:
        ado_groups = {k: v for k, v in ado_groups.items() if k not in skip_ado}

    include_ado = not args.no_ado_list and bool(ado_files)

    # Build lookup dict for dependency resolution
    all_parsed = {df['path']: df for df in dofiles}

    groups = group_tasks(dofiles)

    # Pre-compute group order (and intra-group order) once.
    # topo_sort_groups mutates dofile dicts (_cross_group_fwd_refs side-effect),
    # so it must be called exactly once.
    ordered_groups = topo_sort_groups(groups, all_parsed) if args.sconscripts else None

    # SConstruct
    # Pass pre-computed ordered_groups so generate_sconstruct doesn't call
    # topo_sort_groups a second time.
    sconstruct = generate_sconstruct(
        dofiles, all_parsed, ado_groups, groups,
        use_sconscripts=args.sconscripts,
        include_ado=include_ado,
        ordered_groups=ordered_groups,
    )
    sc_path = out_dir / (
        'SConstructFragment' if fragment_mode else
        'SConstructDraft'    if draft_mode    else
        'SConstruct'
    )
    if fragment_mode and sc_path.exists():
        print(f'Error: {sc_path} already exists. '
              f'Fragment files are never overwritten. Delete it first.',
              file=sys.stderr)
        sys.exit(1)
    sc_path.write_text(sconstruct, encoding='utf-8')
    print(f'Written: {sc_path}')

    # SConscripts (optional)
    # Use pre-computed ordered_groups so that (a) tasks within each SConscript
    # are in dependency order, and (b) SConscript files are listed in the
    # SConstruct in an order consistent with cross-group dependencies.
    if args.sconscripts and ordered_groups is not None:
        n_warnings = 0
        for grp_name, grp_dofiles in ordered_groups.items():
            content = generate_sconscript(
                grp_name, grp_dofiles, all_parsed, ado_groups, include_ado=include_ado,
            )
            scs_path = out_dir / (
                f'{grp_name}Fragment.SConscript' if fragment_mode else
                f'{grp_name}Draft.SConscript'   if draft_mode    else
                f'{grp_name}.SConscript'
            )
            if fragment_mode and scs_path.exists():
                print(f'Error: {scs_path} already exists. '
                      f'Fragment files are never overwritten. Delete it first.',
                      file=sys.stderr)
                sys.exit(1)
            scs_path.write_text(content, encoding='utf-8')
            print(f'Written: {scs_path}')
            n_warnings += sum(1 for df in grp_dofiles if df.get('_cross_group_fwd_refs'))
        if n_warnings:
            print(f'\n  {n_warnings} task(s) have cross-group forward references that '
                  f'could not be resolved by reordering (see # WARNING comments). '
                  f'Move those tasks to an earlier SConscript manually.')

    # Summary
    if fragment_mode:
        sc_name = 'SConstructFragment'
        print(f'\nDone. Review {sc_name}.')
    elif draft_mode:
        sc_name = 'SConstructDraft'
        print(f'\nDone. Review {sc_name}, then rename to SConstruct.')
    else:
        sc_name = 'SConstruct'
        print(f'\nDone. {sc_name} written.')

    # Report ordering fixes applied
    sorted_all = topo_sort_dofiles(dofiles, all_parsed)
    original_pos = {df['path']: i for i, df in enumerate(dofiles)}
    reordered = [(original_pos[df['path']], i, df['path'])
                 for i, df in enumerate(sorted_all)
                 if original_pos[df['path']] != i]
    if reordered:
        print(f'  Ordering: {len(reordered)} task(s) moved to satisfy dependency order '
              f'(would have caused NameError if emitted in scanner order):')
        for orig, new, path in reordered:
            print(f'    {Path(path).name}  (was position {orig+1}, now {new+1})')

    if issues:
        n_unr = sum(1 for i in issues if i.get('type') == 'unresolved_macro')
        n_hdr = sum(1 for i in issues if i.get('type') == 'header_mismatch')
        n_cnd = sum(1 for i in issues if i.get('type') == 'conditional_path')
        print(f'Issues flagged in scan_results.yaml:')
        if n_unr: print(f'  {n_unr} unresolved macro(s)')
        if n_hdr: print(f'  {n_hdr} header mismatch(es)')
        if n_cnd: print(f'  {n_cnd} conditional path(s)')


if __name__ == '__main__':
    main()
