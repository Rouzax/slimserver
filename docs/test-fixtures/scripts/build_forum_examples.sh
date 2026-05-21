#!/usr/bin/env bash
# Fixtures matching the examples raised by commenters on the forum thread.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/../forum}"
mkdir -p "$OUT"
for n in bill obscure peterpaul prince charlesll; do
    ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=48000:cl=stereo -t 1 \
        -c:a libopus -b:a 64k "$OUT/${n}.opus" </dev/null
done
python3 - "$OUT" <<'PY'
import sys
from mutagen.oggopus import OggOpus
OUT = sys.argv[1]

# Real-looking UUIDs so sanitizeTagValues keeps them
MB_BET   = "9a0b28a9-4e6f-4a4c-9d79-111111111111"  # Bill Evans Trio placeholder
MB_SCOTT = "11111111-2222-3333-4444-555555555555"  # Scott LaFaro placeholder
MB_PAUL  = "22222222-3333-4444-5555-666666666666"  # Paul Motian placeholder
MB_ANART = "33333333-4444-5555-6666-777777777777"  # Known artist (Obscure has none)
MB_PRINCE= "44444444-5555-6666-7777-888888888888"  # Prince placeholder
MB_CHARLE= "55555555-6666-7777-8888-999999999999"  # Charles Lloyd
MB_MARVELS="66666666-7777-8888-9999-aaaaaaaaaaaa"  # & The Marvels

def write(stem, **kv):
    f = OggOpus(f"{OUT}/{stem}.opus")
    for k, v in kv.items():
        f[k] = v if isinstance(v, list) else [v]
    f["ALBUM"] = [f"Forum Example {stem}"]
    f["TITLE"] = [f"Example {stem}"]
    f.save()

# mikeysas's flagship example: Bill Evans Trio with Scott LaFaro & Paul Motian
write("bill",
    ALBUMARTIST="Bill Evans Trio with Scott LaFaro & Paul Motian",
    ALBUMARTISTS=["Bill Evans Trio", "Scott LaFaro", "Paul Motian"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_BET, MB_SCOTT, MB_PAUL])

# darrell's residual-poisoning example: feat. with only one MBID
write("obscure",
    ARTIST="An Artist feat. An Obscure Artist",
    ALBUMARTIST="An Artist",
    MUSICBRAINZ_ARTISTID=[MB_ANART],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ANART])

# darrell's non-split comma-space example
write("peterpaul",
    ALBUMARTIST="Peter, Paul and Mary",
    ALBUMARTISTS=["Peter, Paul and Mary"])

# mikeysas's divergent display/group-by: Prince
write("prince",
    ALBUMARTIST="Prince and the Revolution",
    ALBUMARTISTS=["Prince"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_PRINCE])

# d6jg's Charles Lloyd divergent-variant case
write("charlesll",
    ALBUMARTIST="Charles Lloyd & The Marvels",
    ALBUMARTISTS=["Charles Lloyd", "The Marvels"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_CHARLE, MB_MARVELS])

print("Wrote 5 forum-example fixtures")
PY
ls -la "$OUT"
