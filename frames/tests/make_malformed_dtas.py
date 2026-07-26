from __future__ import annotations

import sys
import tempfile
import zipfile
from pathlib import Path


def write_zip_from_tree(src_dir: Path, dst_zip: Path, skip_name: str | None = None) -> None:
    with zipfile.ZipFile(dst_zip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(src_dir.rglob("*")):
            if not path.is_file():
                continue
            rel = path.relative_to(src_dir).as_posix()
            if rel == skip_name:
                continue
            zf.write(path, rel)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: make_malformed_dtas.py SOURCE_DTAS OUTPUT_DIR")
        return 2

    src = Path(sys.argv[1]).resolve()
    out_dir = Path(sys.argv[2]).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    (out_dir / "not_a_zip.dtas").write_text("not a zip\n", encoding="ascii")

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        with zipfile.ZipFile(src, "r") as zf:
            zf.extractall(tmp_path)

        frameinfo = tmp_path / ".frameinfo"
        dta_files = sorted(tmp_path.glob("*.dta"))
        if not frameinfo.exists() or not dta_files:
            raise RuntimeError("valid source .dtas did not contain .frameinfo and embedded .dta files")

        write_zip_from_tree(tmp_path, out_dir / "missing_frameinfo.dtas", skip_name=".frameinfo")
        write_zip_from_tree(tmp_path, out_dir / "missing_member.dtas", skip_name=dta_files[0].name)

        broken_dir = tmp_path / "_broken_frameinfo"
        broken_dir.mkdir()
        for path in tmp_path.iterdir():
            if path.name == broken_dir.name:
                continue
            if path.is_file():
                (broken_dir / path.name).write_bytes(path.read_bytes())

        lines = frameinfo.read_text(encoding="utf-8").splitlines()
        lines.append("this_manifest_line_is_invalid")
        (broken_dir / ".frameinfo").write_text("\n".join(lines) + "\n", encoding="utf-8")
        write_zip_from_tree(broken_dir, out_dir / "bad_frameinfo.dtas")

    print("created malformed fixtures in", out_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

