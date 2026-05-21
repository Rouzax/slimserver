#!/usr/bin/env bash
# Multi-track album fixture for LMS #1555 verification.
# Album "Multi Track Test" has 3 tracks:
#   track01: ALBUMARTIST=Armin & KI/KI, ARTIST=Armin only (single)
#   track02: ALBUMARTIST=Armin & KI/KI, ARTIST=KI/KI only (single)
#   track03: ALBUMARTIST=Armin & KI/KI, ARTIST=Armin ft. KI/KI (plural, triggers TRACKARTIST transform)
# All share the same plural ALBUMARTISTS so album-level contributors should
# always resolve to the two individuals with MBIDs.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/../multitrack}"
mkdir -p "$OUT"
for n in 01 02 03; do
    ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=48000:cl=stereo -t 1 \
        -c:a libopus -b:a 64k "$OUT/track${n}.opus" </dev/null
done
python3 - "$OUT" <<'PY'
import sys
from mutagen.oggopus import OggOpus
OUT = sys.argv[1]
MB_ARMIN = "a9337eec-a9cd-4393-abbd-a35a43ab8e95"
MB_KIKI  = "7b1b1a5a-4f0f-4fcb-9f5a-49e1a4a1a1a1"

def write(n, **kv):
    f = OggOpus(f"{OUT}/track{n}.opus")
    for k, v in kv.items():
        f[k] = v if isinstance(v, list) else [v]
    f["ALBUM"] = ["Issue 1555 Multi Track Test"]
    f["TITLE"] = [f"Multi Track {n}"]
    f["TRACKNUMBER"] = [str(int(n))]
    f["DATE"] = ["2026"]
    f.save()

# Track 1: single ARTIST (one contributor). Uses DaveBackley-style
# aligned multi-value ALBUMARTISTSORT / ARTISTSORT so LMS can bind
# positional per-individual sort names (van Buuren, Armin rather than
# Armin van Buuren).
write("01",
    ALBUMARTIST="Armin van Buuren & KI/KI",
    ALBUMARTISTS=["Armin van Buuren", "KI/KI"],
    ALBUMARTISTSORT=["van Buuren, Armin", "KI/KI"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ARMIN, MB_KIKI],
    ARTIST="Armin van Buuren",
    ARTISTS=["Armin van Buuren"],
    ARTISTSORT=["van Buuren, Armin"],
    MUSICBRAINZ_ARTISTID=[MB_ARMIN])

# Track 2: single ARTIST (the other one)
write("02",
    ALBUMARTIST="Armin van Buuren & KI/KI",
    ALBUMARTISTS=["Armin van Buuren", "KI/KI"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ARMIN, MB_KIKI],
    ARTIST="KI/KI",
    ARTISTS=["KI/KI"],
    MUSICBRAINZ_ARTISTID=[MB_KIKI])

# Track 3: plural ARTIST (ft. pattern, both on one track) with aligned
# plural ARTISTSORT.
write("03",
    ALBUMARTIST="Armin van Buuren & KI/KI",
    ALBUMARTISTS=["Armin van Buuren", "KI/KI"],
    ALBUMARTISTSORT=["van Buuren, Armin", "KI/KI"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ARMIN, MB_KIKI],
    ARTIST="Armin van Buuren ft. KI/KI",
    ARTISTS=["Armin van Buuren", "KI/KI"],
    ARTISTSORT=["van Buuren, Armin", "KI/KI"],
    MUSICBRAINZ_ARTISTID=[MB_ARMIN, MB_KIKI])

print(f"Wrote 3 multi-track fixtures in {OUT}")
PY
ls -la "$OUT"
