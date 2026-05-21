#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/../cross}"
mkdir -p "$OUT"
MB_ARMIN=a9337eec-a9cd-4393-abbd-a35a43ab8e95
MB_KIKI=7b1b1a5a-4f0f-4fcb-9f5a-49e1a4a1a1a1

# FLAC
ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=48000:cl=stereo -t 1 \
    -c:a flac "$OUT/cross.flac" </dev/null
python3 - "$OUT" "$MB_ARMIN" "$MB_KIKI" <<'PY'
import sys
from mutagen.flac import FLAC
out, armin, kiki = sys.argv[1:]
f = FLAC(f"{out}/cross.flac")
f["ALBUMARTIST"]  = ["Armin van Buuren & KI/KI"]
f["ALBUMARTISTS"] = ["Armin van Buuren", "KI/KI"]
f["MUSICBRAINZ_ALBUMARTISTID"] = [armin, kiki]
f["ALBUM"] = ["Issue 1555 Fixture FLAC"]
f["TITLE"] = ["Fixture FLAC"]
f.save()
PY

# MP3 ID3v2.4 (TXXX frames, null-separated multi-value)
ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 \
    -c:a libmp3lame -b:a 128k "$OUT/cross_v24.mp3" </dev/null
python3 - "$OUT" "$MB_ARMIN" "$MB_KIKI" <<'PY'
import sys
from mutagen.id3 import ID3, TXXX, TPE2, TALB, TIT2
out, armin, kiki = sys.argv[1:]
id3 = ID3()
id3.add(TPE2(encoding=3, text=["Armin van Buuren & KI/KI"]))
id3.add(TALB(encoding=3, text=["Issue 1555 Fixture MP3 v2.4"]))
id3.add(TIT2(encoding=3, text=["Fixture MP3 v2.4"]))
id3.add(TXXX(encoding=3, desc="ALBUMARTISTS",
             text=["Armin van Buuren", "KI/KI"]))
id3.add(TXXX(encoding=3, desc="MusicBrainz Album Artist Id",
             text=[armin, kiki]))
id3.save(f"{out}/cross_v24.mp3", v2_version=4)
PY

# MP3 ID3v2.3 (TXXX frames, slash-joined multi-value)
ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 \
    -c:a libmp3lame -b:a 128k "$OUT/cross_v23.mp3" </dev/null
python3 - "$OUT" "$MB_ARMIN" "$MB_KIKI" <<'PY'
import sys
from mutagen.id3 import ID3, TXXX, TPE2, TALB, TIT2
out, armin, kiki = sys.argv[1:]
id3 = ID3()
id3.add(TPE2(encoding=3, text=["Armin van Buuren & KI/KI"]))
id3.add(TALB(encoding=3, text=["Issue 1555 Fixture MP3 v2.3"]))
id3.add(TIT2(encoding=3, text=["Fixture MP3 v2.3"]))
id3.add(TXXX(encoding=3, desc="ALBUMARTISTS",
             text=["Armin van Buuren", "KI/KI"]))
id3.add(TXXX(encoding=3, desc="MusicBrainz Album Artist Id",
             text=[armin, kiki]))
id3.save(f"{out}/cross_v23.mp3", v2_version=3)
PY

# MP4 / M4A
ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=stereo -t 1 \
    -c:a aac -b:a 128k "$OUT/cross.m4a" </dev/null
python3 - "$OUT" "$MB_ARMIN" "$MB_KIKI" <<'PY'
import sys
from mutagen.mp4 import MP4, MP4FreeForm
out, armin, kiki = sys.argv[1:]
f = MP4(f"{out}/cross.m4a")
f["aART"] = ["Armin van Buuren & KI/KI"]
f["\xa9alb"] = ["Issue 1555 Fixture MP4"]
f["\xa9nam"] = ["Fixture MP4"]
f["----:com.apple.iTunes:ALBUMARTISTS"] = [
    MP4FreeForm(b"Armin van Buuren"),
    MP4FreeForm(b"KI/KI")]
f["----:com.apple.iTunes:MusicBrainz Album Artist Id"] = [
    MP4FreeForm(armin.encode()),
    MP4FreeForm(kiki.encode())]
f.save()
PY

echo "Cross-format fixtures ready in $OUT"
ls -la "$OUT"
