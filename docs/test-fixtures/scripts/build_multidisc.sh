#!/usr/bin/env bash
# Multi-disc fixture for LMS #1555 — tests album dedup when contributor changes.
#
# Two scenarios:
# 1. Same album, 2 discs, same ALBUMARTIST/ALBUMARTISTS. Should stay ONE album.
# 2. Two different albums with same title, different ALBUMARTIST/ALBUMARTISTS.
#    Should stay TWO albums (dedup must not merge them).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/../multidisc}"
mkdir -p "$OUT"
for n in d1t1 d1t2 d2t1 d2t2 other_d1t1; do
    ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=48000:cl=stereo -t 1 \
        -c:a libopus -b:a 64k "$OUT/${n}.opus" </dev/null
done
python3 - "$OUT" <<'PY'
import sys
from mutagen.oggopus import OggOpus
OUT = sys.argv[1]
MB_ARMIN = "a9337eec-a9cd-4393-abbd-a35a43ab8e95"
MB_KIKI  = "7b1b1a5a-4f0f-4fcb-9f5a-49e1a4a1a1a1"
MB_A     = "11111111-1111-1111-1111-111111111111"
MB_B     = "22222222-2222-2222-2222-222222222222"

def write(name, **kv):
    f = OggOpus(f"{OUT}/{name}.opus")
    for k, v in kv.items():
        f[k] = v if isinstance(v, list) else [v]
    f.save()

# Scenario 1: "Greatest Hits" by Armin & KI/KI, 2 discs
# Should be ONE album with 2 discs, 2 tracks each
write("d1t1",
    ALBUM="Greatest Hits",
    TITLE="Disc 1 Track 1",
    TRACKNUMBER="1",
    DISCNUMBER="1",
    DISCTOTAL="2",
    DATE="2026",
    ALBUMARTIST="Armin van Buuren & KI/KI",
    ALBUMARTISTS=["Armin van Buuren", "KI/KI"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ARMIN, MB_KIKI])

write("d1t2",
    ALBUM="Greatest Hits",
    TITLE="Disc 1 Track 2",
    TRACKNUMBER="2",
    DISCNUMBER="1",
    DISCTOTAL="2",
    DATE="2026",
    ALBUMARTIST="Armin van Buuren & KI/KI",
    ALBUMARTISTS=["Armin van Buuren", "KI/KI"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ARMIN, MB_KIKI])

write("d2t1",
    ALBUM="Greatest Hits",
    TITLE="Disc 2 Track 1",
    TRACKNUMBER="1",
    DISCNUMBER="2",
    DISCTOTAL="2",
    DATE="2026",
    ALBUMARTIST="Armin van Buuren & KI/KI",
    ALBUMARTISTS=["Armin van Buuren", "KI/KI"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ARMIN, MB_KIKI])

write("d2t2",
    ALBUM="Greatest Hits",
    TITLE="Disc 2 Track 2",
    TRACKNUMBER="2",
    DISCNUMBER="2",
    DISCTOTAL="2",
    DATE="2026",
    ALBUMARTIST="Armin van Buuren & KI/KI",
    ALBUMARTISTS=["Armin van Buuren", "KI/KI"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_ARMIN, MB_KIKI])

# Scenario 2: DIFFERENT album also called "Greatest Hits" by A & B
# Should stay a SEPARATE album, not merge with Armin's
write("other_d1t1",
    ALBUM="Greatest Hits",
    TITLE="Other Album Track 1",
    TRACKNUMBER="1",
    DISCNUMBER="1",
    DATE="2026",
    ALBUMARTIST="A & B",
    ALBUMARTISTS=["A", "B"],
    MUSICBRAINZ_ALBUMARTISTID=[MB_A, MB_B])

print(f"Wrote 5 multi-disc fixtures in {OUT}")
PY
ls -la "$OUT"
