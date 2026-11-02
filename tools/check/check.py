#!/usr/bin/env python3
"""Checks West of Nod for the world-position problems and writes a report.

    python3 tools/check/check.py --godot /path/to/Godot_v4.4.1-stable

Two parts:
- the audit: every line of code that uses a world position, a height,
  a biome lookup or the camera's position, by file and line (a few seconds);
- the still-camera run: the game is started, the player stands still at the
  spawn, and the view is turned through eight directions, with frames grabbed
  a few apart at each. Frames of an unchanged view should match; the places
  where they differ are the jitter (diff_v*.png shows where, brightest where
  the frames differ). Wind moves grass, leaves and water on purpose, so those
  will differ too: look for changes on the bark, the ground and the stumps.

Needs Godot 4.4 (the project's version), numpy and Pillow:
    pip install numpy pillow

Writes into --out (default westofnod_check): report.txt, frames/, diff_v*.png.
Send report.txt and the diff_v*.png files back.
--audit-only skips the game run.
"""
import argparse
import re
import subprocess
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PATTERN = re.compile(
    r"global_position|global_transform|height_at\(|biome_index_at\(|water_at\(|normal_at\(|"
    r"deck_at\(|push_out\(|prop_at\(|walk_near\(|MODEL_MATRIX|CAMERA_POSITION_WORLD|"
    r"world_pos|view_pos|camera\.position"
)
SUFFIXES = {".gd", ".gdshader", ".gdshaderinc"}
VIEWS = 8  # (must match jitter_probe.gd)
GRABS = 4
THRESHOLD = 6  # summed colour change (0..765) that counts as a changed pixel


def audit(report):
    files = {}
    for path in sorted((REPO / "scripts").rglob("*")) + sorted((REPO / "shaders").rglob("*")):
        if path.suffix not in SUFFIXES:
            continue
        hits = []
        text = path.read_text(encoding="utf-8", errors="replace")
        for no, line in enumerate(text.splitlines(), 1):
            if PATTERN.search(line):
                hits.append((no, line.strip()))
        if hits:
            files[path.relative_to(REPO)] = hits
    report.append("== Audit: code that uses world positions, heights or the camera ==")
    for path, hits in files.items():
        report.append(f"{path}  ({len(hits)})")
        for no, text in hits:
            report.append(f"  {no}: {text[:160]}")
    report.append(f"total: {sum(len(h) for h in files.values())} lines in {len(files)} files")
    report.append("")


def run_game(godot, out, minutes, report):
    frames = out / "frames"
    frames.mkdir(parents=True, exist_ok=True)
    cmd = [godot, "--path", str(REPO), "--script", "res://tools/check/jitter_probe.gd", "--", str(frames)]
    print(f"Running the game with a still camera (up to {minutes} minutes; the world takes a while to load)...")
    try:
        done = subprocess.run(cmd, capture_output=True, text=True, timeout=minutes * 60)
        text = (done.stdout or "") + (done.stderr or "")
        report.append(f"game exit code: {done.returncode}")
    except subprocess.TimeoutExpired as e:
        raw = (e.stdout or b"") + (e.stderr or b"")
        text = raw.decode(errors="replace") if isinstance(raw, bytes) else raw
        report.append(f"game stopped: no finish within {minutes} minutes")
    probe = [line for line in text.splitlines() if "PROBE" in line]
    errors = [line for line in text.splitlines()
              if ("ERROR" in line or "Parse Error" in line) and "ALSA" not in line and "status < 0" not in line]
    report.append("== Still camera: log ==")
    report.extend(probe or ["(no PROBE lines: the game did not reach the probe)"])
    report.append("")
    report.append("== Errors from the game ==")
    report.extend(errors[:60] or ["(none)"])
    report.append("")
    if not (frames / f"v{VIEWS - 1}_{GRABS - 1}.png").exists():
        report.append("No frames were saved, so no change figures.")
        report.append("")
        return
    analyse(frames, out, report)


def analyse(frames, out, report):
    import numpy as np
    from PIL import Image

    report.append("== Still camera: changes between frames (% of pixels that changed) ==")
    report.append("Consecutive frames of one view, same camera and player. Expect small")
    report.append("numbers from wind on grass and leaves; the jitter is changes elsewhere.")
    for v in range(VIEWS):
        paths = [frames / f"v{v}_{g}.png" for g in range(GRABS)]
        imgs = [np.asarray(Image.open(p).convert("RGB"), dtype=np.int16) for p in paths]
        changes = []
        for i, (a, b) in enumerate(zip(imgs, imgs[1:])):
            d = np.abs(a - b).sum(axis=2)
            changes.append(float((d > THRESHOLD).mean()) * 100.0)
            if i == 0:
                diff = np.clip(d * 8, 0, 255).astype(np.uint8)
                Image.fromarray(diff).save(out / f"diff_v{v}.png")
        report.append(f"view {v}: " + "  ".join(f"{c:.3f}%" for c in changes))
    report.append("")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--godot", default="godot", help="the Godot 4.4 executable")
    ap.add_argument("--out", default="westofnod_check", help="where to write the report")
    ap.add_argument("--minutes", type=int, default=40, help="give up on the game run after this long")
    ap.add_argument("--audit-only", action="store_true", help="only the code search")
    args = ap.parse_args()

    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    report = [f"West of Nod check, {time.strftime('%Y-%m-%d %H:%M')}", f"repo: {REPO}", ""]
    audit(report)
    if not args.audit_only:
        run_game(args.godot, out, args.minutes, report)
    text = "\n".join(report) + "\n"
    (out / "report.txt").write_text(text, encoding="utf-8")
    print(text)
    print(f"Report: {out / 'report.txt'}")


if __name__ == "__main__":
    main()
