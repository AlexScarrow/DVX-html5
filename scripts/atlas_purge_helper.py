#!/usr/bin/env python3
import argparse
import os
import re
from pathlib import Path


IMAGE_PATTERN = re.compile(r'image:\s*"/assets/images/([^"]+)\.png"')
VISUAL_TILE_PATTERN = re.compile(r'visualTile(?:Computer|Boardgame)?\s*=\s*"([^"]+)"')

TEXT_FILE_EXTS = {
    ".script",
    ".lua",
    ".go",
    ".collection",
    ".gui",
    ".gui_script",
    ".particlefx",
    ".sprite",
    ".project",
    ".json",
    ".md",
}

SKIP_DIRS = {
    ".git",
    "build",
    ".internal",
    "node_modules",
    ".cursor",
}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def collect_text_files(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for filename in filenames:
            p = Path(dirpath) / filename
            if p.suffix.lower() in TEXT_FILE_EXTS:
                yield p


def extract_atlas_ids(atlas_path: Path):
    content = read_text(atlas_path)
    image_names = IMAGE_PATTERN.findall(content)
    ids = []
    for image_name in image_names:
        ids.append(Path(image_name).name)
    return sorted(set(ids))


def build_dynamic_allowlist(root: Path):
    dynamic_ids = {}
    all_file_text = {}

    for p in collect_text_files(root):
        rel = p.relative_to(root).as_posix()
        all_file_text[rel] = read_text(p)

    tile_defs_rel = "main/tile_defs.lua"
    tile_defs_path = root / tile_defs_rel
    if tile_defs_path.exists():
        tile_defs = read_text(tile_defs_path)
        for match in VISUAL_TILE_PATTERN.findall(tile_defs):
            anim_id = f"tile_{match}"
            dynamic_ids.setdefault(anim_id, set()).add(
                'derived from visualTile* in "main/tile_defs.lua"'
            )

    for rel, text in all_file_text.items():
        if 'hash("score_" ..' in text:
            for digit in range(10):
                dynamic_ids.setdefault(f"score_{digit}", set()).add(
                    f'derived from hash("score_" ..) in "{rel}"'
                )
            dynamic_ids.setdefault("score_percent", set()).add(
                f'derived from score HUD family in "{rel}"'
            )
            dynamic_ids.setdefault("score_period", set()).add(
                f'derived from score HUD family in "{rel}"'
            )
        if 'hash("letter_" ..' in text:
            for ch in "abcdefghijklmnopqrstuvwxyz":
                dynamic_ids.setdefault(f"letter_{ch}", set()).add(
                    f'derived from hash("letter_" ..) in "{rel}"'
                )
        if 'hash("wiregap_" ..' in text:
            for key in ("straight", "corner"):
                for state in ("on", "off"):
                    dynamic_ids.setdefault(f"wiregap_{key}_{state}", set()).add(
                        f'derived from hash("wiregap_" ..) in "{rel}"'
                    )

    return dynamic_ids, all_file_text


def collect_literal_evidence(root: Path, atlas_ids, all_file_text):
    evidence = {atlas_id: set() for atlas_id in atlas_ids}
    for rel, text in all_file_text.items():
        if rel == "assets/tiles.atlas":
            continue
        for atlas_id in atlas_ids:
            if atlas_id in text:
                evidence[atlas_id].add(rel)
    return evidence


def write_markdown_report(
    report_path: Path,
    atlas_ids,
    literal_evidence,
    dynamic_ids,
    unmatched_ids,
    dynamic_only_ids,
):
    lines = []
    lines.append("# Atlas Purge Helper Report")
    lines.append("")
    lines.append(f"- Atlas IDs scanned: **{len(atlas_ids)}**")
    lines.append(
        f"- Literal matches outside atlas: **{sum(1 for aid in atlas_ids if literal_evidence.get(aid))}**"
    )
    lines.append(f"- Dynamic allowlist matches: **{len(dynamic_only_ids)}**")
    lines.append(f"- Strict unmatched candidates: **{len(unmatched_ids)}**")
    lines.append("")
    lines.append("## Strict Unmatched Candidates")
    lines.append("")
    if not unmatched_ids:
        lines.append("No strict unmatched IDs found.")
    else:
        for atlas_id in unmatched_ids:
            lines.append(f"- `{atlas_id}`")
    lines.append("")
    lines.append("## Dynamic-Only (No Literal Match)")
    lines.append("")
    if not dynamic_only_ids:
        lines.append("None.")
    else:
        for atlas_id in dynamic_only_ids:
            reasons = sorted(dynamic_ids.get(atlas_id, set()))
            reason_preview = reasons[0] if reasons else "dynamic pattern"
            lines.append(f"- `{atlas_id}` - {reason_preview}")
    lines.append("")
    lines.append("## Literal Evidence Snapshot")
    lines.append("")
    for atlas_id in atlas_ids:
        hits = sorted(literal_evidence.get(atlas_id, set()))
        if not hits:
            continue
        preview = ", ".join(hits[:3])
        if len(hits) > 3:
            preview += ", ..."
        lines.append(f"- `{atlas_id}` ({len(hits)}): {preview}")

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(
        description="Strict helper to find likely-unused animation IDs in assets/tiles.atlas."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Project root directory (default: current directory)",
    )
    parser.add_argument(
        "--atlas",
        default="assets/tiles.atlas",
        help="Path to atlas relative to root (default: assets/tiles.atlas)",
    )
    parser.add_argument(
        "--report",
        default="Docs/ATLAS_PURGE_HELPER_REPORT.md",
        help="Path to markdown report relative to root",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    atlas_path = root / args.atlas
    report_path = root / args.report

    if not atlas_path.exists():
        raise SystemExit(f"Atlas file not found: {atlas_path}")

    atlas_ids = extract_atlas_ids(atlas_path)
    dynamic_ids, all_file_text = build_dynamic_allowlist(root)
    literal_evidence = collect_literal_evidence(root, atlas_ids, all_file_text)

    unmatched_ids = []
    dynamic_only_ids = []
    for atlas_id in atlas_ids:
        has_literal = len(literal_evidence.get(atlas_id, set())) > 0
        has_dynamic = atlas_id in dynamic_ids
        if has_literal:
            continue
        if has_dynamic:
            dynamic_only_ids.append(atlas_id)
        else:
            unmatched_ids.append(atlas_id)

    report_path.parent.mkdir(parents=True, exist_ok=True)
    write_markdown_report(
        report_path,
        atlas_ids,
        literal_evidence,
        dynamic_ids,
        sorted(unmatched_ids),
        sorted(dynamic_only_ids),
    )

    print(f"Atlas IDs scanned: {len(atlas_ids)}")
    print(f"Dynamic-only IDs: {len(dynamic_only_ids)}")
    print(f"Strict unmatched candidates: {len(unmatched_ids)}")
    print(f"Report written: {report_path}")


if __name__ == "__main__":
    main()
