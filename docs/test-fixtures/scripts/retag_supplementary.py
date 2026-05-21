#!/usr/bin/env python3
"""Retag supplementary fixture sets with realistic names and clean album titles."""
import os
from mutagen.oggopus import OggOpus
from mutagen.flac import FLAC

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(SCRIPT_DIR, "..")

def retag_opus(path, **overrides):
    f = OggOpus(path)
    for k, v in overrides.items():
        f[k] = v if isinstance(v, list) else [v]
    f.save()

def retag_flac(path, **overrides):
    f = FLAC(path)
    for k, v in overrides.items():
        f[k] = v if isinstance(v, list) else [v]
    f.save()

# ── VA compilation ─────────────────────────────────────────────────────
# Replace "A" -> "Norah Jones", "C" -> "Diana Krall"
# Keep "Armin van Buuren & KI/KI" (already realistic)
# Clean album name

MB_NORAH = "985c709c-7771-4de3-9024-7bda29ebe3f9"
MB_DIANA = "35208d5b-4d57-4661-b7c2-aa3643a0e1f5"
MB_VA    = "89ad4ac3-39f7-470e-963a-56509c546377"
MB_ARMIN = "a9337eec-a9cd-4393-abbd-a35a43ab8e95"
MB_KIKI  = "7b1b1a5a-4f0f-4fcb-9f5a-49e1a4a1a1a1"

for f in ["va/va01.opus", "va/va02.opus", "va/va03.opus"]:
    retag_opus(f"{BASE}/{f}", album="VA Compilation Test")

retag_opus(f"{BASE}/va/va01.opus",
    artist="Norah Jones", artists=["Norah Jones"],
    musicbrainz_artistid=[MB_NORAH])

# va02 already has Armin van Buuren & KI/KI, just clean album
# va03: C -> Diana Krall
retag_opus(f"{BASE}/va/va03.opus",
    artist="Diana Krall", artists=["Diana Krall"],
    musicbrainz_artistid=[MB_DIANA])

print("VA compilation: done")

# ── Multitrack ─────────────────────────────────────────────────────────
# Already uses Armin van Buuren & KI/KI. Just clean album name.
for f in ["multitrack/track01.opus", "multitrack/track02.opus", "multitrack/track03.opus"]:
    retag_opus(f"{BASE}/{f}", album="Multi Track Test")
print("Multitrack: done")

# ── Multidisc ──────────────────────────────────────────────────────────
# Main discs already use AvB & KI/KI. Just need to fix other_d1t1.opus
# and clean all album names.
for f in ["multidisc/d1t1.opus", "multidisc/d1t2.opus",
          "multidisc/d2t1.opus", "multidisc/d2t2.opus"]:
    # Already fine, no changes needed (album="Greatest Hits" is already clean)
    pass

# Fix other_d1t1: A & B -> Hall & Oates (matches fixture 02 pattern)
retag_opus(f"{BASE}/multidisc/other_d1t1.opus",
    albumartist="Hall & Oates",
    albumartists=["Hall", "Oates"])
print("Multidisc: done")

# ── Cross-format ───────────────────────────────────────────────────────
# Already uses Armin van Buuren & KI/KI. Clean album name.
retag_flac(f"{BASE}/cross/cross.flac", album="Cross-Format Test")
print("Cross-format FLAC: done")

# MP3 and M4A need different mutagen classes
from mutagen.mp3 import MP3
from mutagen.id3 import TALB
from mutagen.mp4 import MP4

for mp3f in ["cross/cross_v23.mp3", "cross/cross_v24.mp3"]:
    try:
        t = MP3(f"{BASE}/{mp3f}")
        t.tags.delall("TALB")
        t.tags.add(TALB(encoding=3, text=["Cross-Format Test"]))
        t.save()
    except Exception as e:
        print(f"  {mp3f}: {e}")

try:
    t = MP4(f"{BASE}/cross/cross.m4a")
    t["\xa9alb"] = ["Cross-Format Test"]
    t.save()
except Exception as e:
    print(f"  cross.m4a: {e}")

print("Cross-format MP3/M4A: done")

# ── Variant ────────────────────────────────────────────────────────────
# Already uses Bill Evans / Bill Evans Trio. No changes needed.
print("Variant: already realistic")

# ── Forum examples ─────────────────────────────────────────────────────
# Already fully realistic. No changes needed.
print("Forum examples: already realistic")

print("\nAll supplementary fixtures updated.")
