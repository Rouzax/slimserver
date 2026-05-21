#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/../core}"
mkdir -p "$OUT"
for n in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22; do
    ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=48000:cl=stereo -t 1 \
        -c:a libopus -b:a 64k "$OUT/fixture_${n}.opus" </dev/null
done
python3 "$SCRIPT_DIR/build_tags.py" "$OUT"
