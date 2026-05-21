#!/usr/bin/env bash
# d6jg variant-unification fixture:
# Two albums for the same MB artist but tagged with different ALBUMARTIST strings.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/../variant}"
mkdir -p "$OUT"
for n in solo trio; do
    ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=48000:cl=stereo -t 1 \
        -c:a libopus -b:a 64k "$OUT/${n}.opus" </dev/null
done
python3 - "$OUT" <<'PY'
import sys
from mutagen.oggopus import OggOpus
OUT = sys.argv[1]
MB_BILL = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"  # same MBID for both albums

def write(stem, albumartist, album):
    f = OggOpus(f"{OUT}/{stem}.opus")
    f["ALBUMARTIST"] = [albumartist]
    f["ALBUMARTISTS"] = [albumartist]  # single value, deliberately same as singular
    f["MUSICBRAINZ_ALBUMARTISTID"] = [MB_BILL]
    f["ALBUM"] = [album]
    f["TITLE"] = [f"Variant {stem}"]
    f.save()

# Album A: tagged with the short name
write("solo", "Bill Evans", "Variant Album Solo")
# Album B: same MBID, tagged with the band name
write("trio", "Bill Evans Trio", "Variant Album Trio")
print("Wrote 2 variant fixtures")
PY
ls -la "$OUT"
