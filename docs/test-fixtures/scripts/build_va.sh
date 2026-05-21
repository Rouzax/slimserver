#!/usr/bin/env bash
# Various Artists compilation fixture for LMS #1555 verification.
# Album "VA Compilation Test" is a multi-artist compilation:
#   - ALBUMARTIST="Various Artists" with canonical MB VA MBID (89ad4ac3...)
#   - COMPILATION=1
#   - Each track has its own ARTIST + ARTISTS plural + MBID
#   - Track 2 has two collaborating artists (plural ARTISTS)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/../va}"
mkdir -p "$OUT"
for n in 01 02 03; do
    ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=48000:cl=stereo -t 1 \
        -c:a libopus -b:a 64k "$OUT/va${n}.opus" </dev/null
done
python3 - "$OUT" <<'PY'
import sys
from mutagen.oggopus import OggOpus
OUT = sys.argv[1]
MB_VA    = "89ad4ac3-39f7-470e-963a-56509c546377"  # canonical Various Artists
MB_ARMIN = "a9337eec-a9cd-4393-abbd-a35a43ab8e95"
MB_KIKI  = "7b1b1a5a-4f0f-4fcb-9f5a-49e1a4a1a1a1"
MB_A     = "11111111-1111-1111-1111-111111111111"
MB_B     = "22222222-2222-2222-2222-222222222222"
MB_C     = "33333333-3333-3333-3333-333333333333"

def write(n, **kv):
    f = OggOpus(f"{OUT}/va{n}.opus")
    for k, v in kv.items():
        f[k] = v if isinstance(v, list) else [v]
    f["ALBUM"] = ["Issue 1555 VA Compilation Test"]
    f["TITLE"] = [f"VA Track {n}"]
    f["TRACKNUMBER"] = [str(int(n))]
    f["DATE"] = ["2026"]
    f["ALBUMARTIST"] = ["Various Artists"]
    f["ALBUMARTISTS"] = ["Various Artists"]
    f["MUSICBRAINZ_ALBUMARTISTID"] = [MB_VA]
    f["COMPILATION"] = ["1"]
    f.save()

# Track 1: single ARTIST "A"
write("01",
    ARTIST="A",
    ARTISTS=["A"],
    MUSICBRAINZ_ARTISTID=[MB_A])

# Track 2: two ARTISTS (collab on a compilation)
write("02",
    ARTIST="Armin van Buuren & KI/KI",
    ARTISTS=["Armin van Buuren", "KI/KI"],
    MUSICBRAINZ_ARTISTID=[MB_ARMIN, MB_KIKI])

# Track 3: single ARTIST "C"
write("03",
    ARTIST="C",
    ARTISTS=["C"],
    MUSICBRAINZ_ARTISTID=[MB_C])

print(f"Wrote 3 VA compilation fixtures in {OUT}")
PY
ls -la "$OUT"
