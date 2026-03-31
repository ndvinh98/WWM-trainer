#!/usr/bin/env python3
"""
Phase 2: Decompile bytecodes + merge into scaffold dump files.

After the in-game dump (with Save Bytecode ON) saves bytecodes to
Scripts/dumped/bytecodes/, this script:
  1. Decompiles all .luac files using unluac.jar batch mode (single JVM call)
  2. Replaces -- __DECOMPILE__<source>:<lines>__ placeholders in dump files
     with decompiled source
  3. Optionally formats merged .lua files with StyLua

Bytecode filenames use the same token as placeholders:
  Placeholder:  -- __DECOMPILE__hexm/client/combat/skill_base.lua:42-58__
  Bytecode:     __DECOMPILE__hexm_client_combat_skill_base.lua_42-58__.luac
  Decompiled:   __DECOMPILE__hexm_client_combat_skill_base.lua_42-58__.lua

Usage:
    python merge_decompiled.py <dump_dir> [options]

    dump_dir: Root dump directory (e.g. Scripts/dumped/)
              Expects bytecodes/ subfolder with .luac files

Options:
    --unluac PATH          Path to unluac.jar (default: auto-detect)
    --output DIR           Write merged files to DIR (default: <dump_dir>/../source_decompiled/)
    --in-place             Merge in-place (overwrite original files)
    --decompile-only       Only decompile bytecodes, don't merge
    --merge-only           Only merge (assumes decompiled/ already exists)
    --format-only          Only format (skip decompile + merge, scan output dir for .lua)
    --no-format            Skip StyLua formatting after merge
    --max-format-size KB   Max file size in KB for StyLua formatting (default: 512)
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

# Matches: -- __DECOMPILE__<name_id>__
# name_id example: hexm/client/combat/skill_base.lua:42-58
PLACEHOLDER_PATTERN = re.compile(r'-- __DECOMPILE__(.+?)__')

# Matches: -- Format: Success / -- Format: Failed - ...
FORMAT_STATUS_PATTERN = re.compile(r'^-- Format: (.+)$', re.MULTILINE)
HEADER_END_PATTERN = re.compile(r'^-- ={5,}$', re.MULTILINE)

# Matches StyLua per-file error lines:
#   error: could not format file path/to/file.lua: error parsing: ...
STYLUA_ERROR_PATTERN = re.compile(r'error: could not format file (.+?): (.+)')

# StyLua formatting defaults
STYLUA_BATCH_SIZE = 50
STYLUA_MAX_WORKERS = 4
STYLUA_MAX_THREADS = 8
DEFAULT_MAX_FORMAT_SIZE_KB = 4096


def name_id_to_safe_name(name_id: str) -> str:
    """Convert a placeholder name_id to the filesystem-safe stem used for .luac/.lua files."""
    safe = re.sub(r'[/\\:*?"<>|]', '_', name_id)
    return f'__DECOMPILE__{safe}__'


# ============================================================
# Phase 2a: Decompile bytecodes (single JVM batch call)
# ============================================================

def decompile_all(bytecode_dir: Path, decompiled_dir: Path, unluac_jar: str) -> bool:
    """Decompile all .luac files using unluac batch mode.
    Returns True on success."""
    decompiled_dir.mkdir(parents=True, exist_ok=True)

    luac_files = list(bytecode_dir.glob('*.luac'))
    if not luac_files:
        print(f'No .luac files found in {bytecode_dir}')
        return False

    print(f'Decompiling {len(luac_files)} bytecodes via unluac batch mode...')

    report_path = bytecode_dir.parent / 'report.md'
    cmd = [
        'java', '-jar', str(unluac_jar), '--wwm',
        '--outdir', str(decompiled_dir),
        '--report', str(report_path),
        str(bytecode_dir),
    ]

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True,
            timeout=600,  # 10 min for large batches
            creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0,
        )

        if result.stdout.strip():
            print(result.stdout.strip())
        if result.stderr.strip():
            print(result.stderr.strip(), file=sys.stderr)

        if report_path.exists():
            print(f'Report: {report_path}')

        if result.returncode != 0:
            print(f'WARNING: unluac exited with code {result.returncode}')

    except subprocess.TimeoutExpired:
        print('ERROR: unluac batch timed out (600s)')
        return False
    except Exception as e:
        print(f'ERROR: {e}')
        return False

    return True


# ============================================================
# Phase 2b: Merge decompiled sources into scaffold dumps
# ============================================================

def load_decompiled_sources(decompiled_dir: Path, name_prefixes: list = None) -> dict:
    """Load all decompiled .lua files into a dict keyed by stem (safe_name).
    If name_prefixes provided, only load sources whose stem starts with one of them."""
    sources = {}
    for path in decompiled_dir.glob('*.lua'):
        if name_prefixes and not any(path.stem.startswith(p) for p in name_prefixes):
            continue
        sources[path.stem] = path.read_text(encoding='utf-8', errors='replace').rstrip()
    return sources


def escape_for_json(text: str) -> str:
    """Escape text for embedding inside a JSON string value."""
    text = text.replace('\\', '\\\\')
    text = text.replace('"', '\\"')
    text = text.replace('\n', '\\n')
    text = text.replace('\r', '\\r')
    text = text.replace('\t', '\\t')
    return text


def merge_content(content: str, sources: dict, is_json: bool) -> tuple:
    """Replace all __DECOMPILE__ placeholders in content string.
    Returns (new_content, replacement_count)."""
    if '__DECOMPILE__' not in content:
        return content, 0

    replacements = 0

    def replacer(match):
        nonlocal replacements
        name_id = match.group(1)
        safe_name = name_id_to_safe_name(name_id)
        if safe_name in sources:
            source = sources[safe_name]
            if is_json:
                source = escape_for_json(source)
            replacements += 1
            return source
        return match.group(0)

    new_content = PLACEHOLDER_PATTERN.sub(replacer, content)
    return new_content, replacements


def merge_all(dump_dir: Path, decompiled_dir: Path, output_dir: Path = None,
              modules: list = None) -> tuple:
    """Walk dump directory and merge all placeholders.

    When output_dir is set, only files with actual replacements are written
    there (preserving the relative directory structure from dump_dir).

    When modules is set (list of dotted module paths like
    'hexm.common.actionline.nodes.logic_nodes'), only files under matching
    subdirectories are processed, and only matching decompiled sources are loaded.

    Returns (files_modified, total_replacements, merged_file_paths).
    """
    # Build name prefixes for filtering decompiled sources
    name_prefixes = None
    if modules:
        name_prefixes = [f'__DECOMPILE__{m.replace(".", "_")}' for m in modules]

    sources = load_decompiled_sources(decompiled_dir, name_prefixes)
    print(f'Loaded {len(sources)} decompiled sources')

    if not sources:
        print('Nothing to merge')
        return 0, 0, []

    # Build sub-paths to walk when filtering by module
    module_roots = None
    if modules:
        module_roots = []
        for m in modules:
            sub = Path(m.replace('.', '/'))
            mod_path = dump_dir / sub
            if mod_path.exists():
                module_roots.append(mod_path)
            else:
                print(f'WARNING: Module path not found: {mod_path}')
        if not module_roots:
            print('ERROR: No matching module directories found')
            return 0, 0, []
        print(f'  Filtering to {len(module_roots)} module(s): {", ".join(modules)}')

    skip_dirs = {'bytecodes', 'decompiled'}
    total_files = 0
    total_replacements = 0
    merged_files = []

    walk_roots = module_roots if module_roots else [dump_dir]
    for walk_root in walk_roots:
        for root, dirs, files in os.walk(walk_root):
            dirs[:] = [d for d in dirs if d not in skip_dirs]

            for fname in files:
                if not (fname.endswith('.lua') or fname.endswith('.json')):
                    continue

                filepath = Path(root) / fname
                content = filepath.read_text(encoding='utf-8', errors='replace')

                is_json = fname.endswith('.json')
                new_content, count = merge_content(content, sources, is_json)

                if count > 0:
                    if output_dir:
                        rel = filepath.relative_to(dump_dir)
                        out_path = output_dir / rel
                        out_path.parent.mkdir(parents=True, exist_ok=True)
                        out_path.write_text(new_content, encoding='utf-8')
                        merged_files.append(out_path)
                    else:
                        filepath.write_text(new_content, encoding='utf-8')
                        merged_files.append(filepath)

                total_files += 1
                total_replacements += count

    print(f'Merged {total_replacements} placeholders across {total_files} files')
    return total_files, total_replacements, merged_files


# ============================================================
# Phase 2c: Format merged Lua files with StyLua
# ============================================================

def _get_format_status(filepath: Path) -> str | None:
    """Read the -- Format: ... status from a file header. Returns None if absent."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as fh:
            # Only check the first 20 lines (header area)
            for _ in range(20):
                line = fh.readline()
                if not line:
                    break
                m = FORMAT_STATUS_PATTERN.match(line.rstrip())
                if m:
                    return m.group(1)
    except OSError:
        pass
    return None


def _set_format_status(filepath: Path, status: str) -> None:
    """Insert or update the -- Format: ... line in the file header.

    Places it right after the last -- ====... header separator line.
    If an existing Format line exists, it is replaced.
    """
    try:
        content = filepath.read_text(encoding='utf-8', errors='replace')
    except OSError:
        return

    # Remove any existing format status line
    content = FORMAT_STATUS_PATTERN.sub('', content)
    # Clean up blank line left behind
    content = re.sub(r'\n\n\n+', '\n\n', content)

    format_line = f'-- Format: {status}'

    # Insert after the last header separator (-- ======...)
    # Find the last occurrence within the first 10 lines
    lines = content.split('\n')
    insert_idx = None
    for i, line in enumerate(lines[:10]):
        if HEADER_END_PATTERN.match(line.rstrip()):
            insert_idx = i
    if insert_idx is not None:
        lines.insert(insert_idx + 1, format_line)
    else:
        # No header separator found — prepend after first line
        lines.insert(1, format_line)

    filepath.write_text('\n'.join(lines), encoding='utf-8')


def format_lua_files(files: list, max_size_kb: int) -> None:
    """Batch-format .lua files with StyLua.

    Skips files that:
    - Are over max_size_kb
    - Already have '-- Format: Success' in their header

    After formatting, stamps each file header with:
    - -- Format: Success   (if StyLua succeeded)
    - -- Format: Failed - <error>  (if StyLua failed)
    """
    max_bytes = max_size_kb * 1024
    lua_files = []
    skipped_size = 0
    skipped_already = 0

    for f in files:
        if f.suffix != '.lua':
            continue
        try:
            if f.stat().st_size > max_bytes:
                skipped_size += 1
                continue
        except OSError:
            continue

        # Skip files already formatted successfully
        status = _get_format_status(f)
        if status and status.strip() == 'Success':
            skipped_already += 1
            continue

        lua_files.append(f)

    if not lua_files:
        print('No eligible .lua files to format')
        if skipped_already:
            print(f'  ({skipped_already} file(s) already formatted)')
        return

    total = len(lua_files)
    print(f'Formatting {total} .lua file(s) with StyLua...')
    if skipped_size:
        print(f'  Skipped {skipped_size} file(s) exceeding {max_size_kb}KB')
    if skipped_already:
        print(f'  Skipped {skipped_already} file(s) already formatted')

    # Check if stylua is available
    try:
        subprocess.run(
            ['stylua', '--version'], capture_output=True, timeout=5,
            creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0,
        )
    except FileNotFoundError:
        print('WARNING: stylua not found in PATH, skipping formatting')
        return
    except Exception:
        print('WARNING: stylua check failed, skipping formatting')
        return

    def _format_batch(batch):
        """Returns (stderr_string_or_None, batch)."""
        result = subprocess.run(
            [
                "stylua",
                # "--space-after-function-names",
                # "Always",
                "--syntax",
                "Lua54",
                "--num-threads",
                str(STYLUA_MAX_THREADS),
                *[str(f) for f in batch],
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            return result.stderr, batch
        return None, batch

    batches = [lua_files[i:i + STYLUA_BATCH_SIZE]
               for i in range(0, total, STYLUA_BATCH_SIZE)]
    done = 0
    errors = []
    # Map resolved file path -> specific error message from StyLua
    failed_files: dict[Path, str] = {}

    with ThreadPoolExecutor(max_workers=STYLUA_MAX_WORKERS) as pool:
        futures = {pool.submit(_format_batch, b): b for b in batches}
        for future in as_completed(futures):
            err, batch = future.result()
            done += len(batch)
            pct = done * 100 // total
            print(f'\r  [{pct:3d}%] {done}/{total} files formatted',
                  end='', flush=True)
            if err:
                errors.append(err)
                # Parse per-file errors from StyLua stderr
                for line in err.splitlines():
                    m = STYLUA_ERROR_PATTERN.search(line)
                    if m:
                        err_path = Path(m.group(1).strip())
                        err_msg = m.group(2).strip()
                        # Resolve to match our file paths
                        try:
                            resolved = err_path.resolve()
                        except OSError:
                            resolved = err_path
                        failed_files[resolved] = err_msg

    print()

    # Stamp format status into each file header
    for f in lua_files:
        try:
            resolved = f.resolve()
        except OSError:
            resolved = f
        if resolved in failed_files:
            _set_format_status(f, f'Failed - {failed_files[resolved]}')
        else:
            _set_format_status(f, 'Success')

    if errors:
        print(f'  {len(failed_files)} file(s) had formatting errors:')
        for path, msg in failed_files.items():
            print(f'    {path.name}: {msg[:200]}')
    else:
        print('  All files formatted successfully')


# ============================================================
# Phase 3: Migrate non-merged files from dumped/ to source_decompiled/
# ============================================================

def migrate_non_merged(dump_dir: Path, output_dir: Path) -> tuple:
    """Copy files from dump_dir to output_dir that don't already exist there.

    Skips bytecodes/ and decompiled/ subdirectories.
    Returns (copied_count, skipped_count).
    """
    skip_dirs = {'bytecodes', 'decompiled'}
    copied = 0
    skipped = 0

    for root, dirs, files in os.walk(dump_dir):
        dirs[:] = [d for d in dirs if d not in skip_dirs]

        for fname in files:
            src = Path(root) / fname
            rel = src.relative_to(dump_dir)
            dst = output_dir / rel

            if dst.exists():
                skipped += 1
                continue

            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            copied += 1

    return copied, skipped


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description='Decompile bytecodes and merge into scaffold dump files'
    )
    parser.add_argument('dump_dir', help='Root dump directory (e.g. Scripts/dumped/)')
    parser.add_argument('--unluac', default=None,
                        help='Path to unluac.jar (default: auto-detect)')
    parser.add_argument('--output', default=None,
                        help='Write merged files to DIR (default: <dump_dir>/../source_decompiled/)')
    parser.add_argument('--in-place', action='store_true',
                        help='Merge in-place, overwriting original dump files')
    parser.add_argument('--decompile-only', action='store_true',
                        help='Only decompile bytecodes, skip merge')
    parser.add_argument('--merge-only', action='store_true',
                        help='Only merge (assumes decompiled/ exists)')
    parser.add_argument('--format-only', action='store_true',
                        help='Only format .lua files (skip decompile + merge)')
    parser.add_argument('--module', action='append', metavar='MODULE',
                        help='Only process specific module(s), e.g. hexm.common.actionline.nodes.logic_nodes '
                             '(can be repeated). Dot-separated path matching dump_dir subdirectories.')
    parser.add_argument('--migrate-only', action='store_true',
                        help='Only migrate non-merged files from dump_dir to output dir')
    parser.add_argument('--no-migrate', action='store_true',
                        help='Skip Phase 3 migration of non-merged files')
    parser.add_argument('--no-format', action='store_true',
                        help='Skip StyLua formatting after merge')
    parser.add_argument('--max-format-size', type=int, default=DEFAULT_MAX_FORMAT_SIZE_KB,
                        metavar='KB',
                        help=f'Max file size in KB for StyLua formatting (default: {DEFAULT_MAX_FORMAT_SIZE_KB})')
    args = parser.parse_args()

    dump_dir = Path(args.dump_dir)
    bytecode_dir = dump_dir / 'bytecodes'
    decompiled_dir = dump_dir / 'decompiled'

    # Auto-detect unluac.jar
    if args.unluac:
        unluac_jar = args.unluac
    else:
        script_dir = Path(__file__).parent
        candidates = [
            script_dir.parent / 'unluac' / 'unluac.jar',
            script_dir.parent / 'lib' / 'unluac.jar',
            Path('Scripts/lib/unluac.jar'),
        ]
        unluac_jar = None
        for c in candidates:
            if c.exists():
                unluac_jar = str(c)
                break
        if not unluac_jar and not args.merge_only and not args.format_only and not args.migrate_only:
            print('ERROR: Cannot find unluac.jar. Use --unluac to specify path.')
            sys.exit(1)

    # Resolve output directory for migrate/format-only modes
    def _resolve_output_dir():
        if args.output:
            return Path(args.output)
        return dump_dir.parent / 'source_decompiled'

    # --migrate-only: just copy non-merged files
    if args.migrate_only:
        migrate_dir = _resolve_output_dir()
        print(f'=== Phase 3: Migrate non-merged files ===')
        print(f'  From: {dump_dir}')
        print(f'  To:   {migrate_dir}')
        copied, skipped = migrate_non_merged(dump_dir, migrate_dir)
        print(f'  Copied {copied} file(s), skipped {skipped} already existing')
        print('\nDone!')
        return

    # --format-only: skip decompile + merge, just format .lua files in output dir
    if args.format_only:
        if args.output:
            format_dir = Path(args.output)
        else:
            format_dir = dump_dir.parent / 'source_decompiled'

        if not format_dir.exists():
            print(f'ERROR: Format directory not found: {format_dir}')
            sys.exit(1)

        lua_files = list(format_dir.rglob('*.lua'))
        print(f'=== Phase 2c: Format (StyLua) ===')
        print(f'  Directory: {format_dir}')
        print(f'  Found {len(lua_files)} .lua file(s)')
        if lua_files:
            format_lua_files(lua_files, args.max_format_size)

        print('\nDone!')
        return

    # Phase 2a: Decompile (single JVM batch call)
    if not args.merge_only:
        if not bytecode_dir.exists():
            print(f'ERROR: Bytecode directory not found: {bytecode_dir}')
            sys.exit(1)

        print(f'=== Phase 2a: Decompile (batch) ===')
        print(f'  Bytecodes: {bytecode_dir}')
        print(f'  Output:    {decompiled_dir}')
        print(f'  unluac:    {unluac_jar}')
        decompile_all(bytecode_dir, decompiled_dir, unluac_jar)

    # Phase 2b: Merge
    if not args.decompile_only:
        if not decompiled_dir.exists():
            print(f'ERROR: Decompiled directory not found: {decompiled_dir}')
            sys.exit(1)

        # Determine output directory
        if args.in_place:
            output_dir = None
        elif args.output:
            output_dir = Path(args.output)
        else:
            # Default: source_decompiled/ sibling to dump_dir
            output_dir = dump_dir.parent / 'source_decompiled'

        print(f'\n=== Phase 2b: Merge ===')
        if output_dir:
            print(f'  Output: {output_dir}')
        else:
            print(f'  Output: in-place')

        _, _, merged_files = merge_all(dump_dir, decompiled_dir, output_dir)

        # Phase 2c: Format with StyLua
        if not args.no_format and merged_files:
            print(f'\n=== Phase 2c: Format (StyLua) ===')
            format_lua_files(merged_files, args.max_format_size)

        # Phase 3: Migrate non-merged files
        if not args.no_migrate and output_dir:
            print(f'\n=== Phase 3: Migrate non-merged files ===')
            print(f'  From: {dump_dir}')
            print(f'  To:   {output_dir}')
            copied, skipped = migrate_non_merged(dump_dir, output_dir)
            print(f'  Copied {copied} file(s), skipped {skipped} already existing')

    print('\nDone!')


if __name__ == '__main__':
    main()
