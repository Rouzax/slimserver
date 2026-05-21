#!/usr/bin/env bash
set -uo pipefail

# Test Sections C, D, E, H: Rescan, Pref toggle, Regression, API contract

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SLIMSERVER="${SLIMSERVER:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
FIXTURES="${FIXTURES:-$SCRIPT_DIR}"
PREFS="${PREFS:-/tmp/1555-prefs}"
RESULTS=/tmp/test_results/cdeh
DB="$PREFS/library.db"
PORT=9000
PASS=0
FAIL=0

mkdir -p "$RESULTS"

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1 -- $2"; FAIL=$((FAIL+1)); }

start_server() {
    cd "$SLIMSERVER"
    perl slimserver.pl --logfile=/tmp/live.log --prefsdir="$PREFS" --cachedir="$PREFS" --httpport=$PORT &
    SERVER_PID=$!
    sleep 15
}

stop_server() {
    kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null || true; sleep 3
}

api() {
    curl -s "http://localhost:$PORT/jsonrpc.js" -d "$1"
}

wipe_rescan() {
    api '{"method":"slim.request","params":["",["wipecache"]]}' > /dev/null
    sleep 20
}

rescan() {
    api '{"method":"slim.request","params":["",["rescan","full"]]}' > /dev/null
    sleep 15
}

set_pref() {
    perl -i -pe "s/usePluralArtistTags:\s*\d/usePluralArtistTags: $1/" "$PREFS/server.prefs" 2>/dev/null
}

python3 "$FIXTURES/scripts/build_tags.py" "$FIXTURES/core" --names=realistic > /dev/null

# ── Section D: Preference toggle ─────────────────────────────────────
echo "=== Section D: Preference toggle ==="

# D1: Scan with pref OFF
echo "D1: Scan pref OFF"
rm -f "$DB"
set_pref 0
start_server

D1_JOINED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 01%'")
if [ "$D1_JOINED" -gt 0 ]; then pass "D1 joined-string present (pref OFF)"; else fail "D1" "no joined strings"; fi

D1_DA=$(sqlite3 "$DB" "SELECT COUNT(*) FROM albums WHERE display_artist IS NOT NULL")
if [ "$D1_DA" -gt 0 ]; then pass "D4 display_artist populated even with pref OFF ($D1_DA)"; else fail "D4" "display_artist NULL with pref OFF"; fi

# D2: Toggle ON, fresh DB
echo "D2: Toggle pref ON, fresh scan"
stop_server
set_pref 1
rm -f "$DB"
start_server

D2_JOINED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 01%'")
if [ "$D2_JOINED" -eq 0 ]; then pass "D2 no joined strings (pref ON)"; else fail "D2" "found $D2_JOINED joined-string contributors"; fi

D2_INDIV=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 01%'")
if [ "$D2_INDIV" -eq 2 ]; then pass "D2 two individual contributors for fixture 01"; else fail "D2" "found $D2_INDIV contributors"; fi

# D3: Toggle OFF, fresh DB
echo "D3: Toggle pref OFF, fresh scan"
stop_server
set_pref 0
rm -f "$DB"
start_server

D3_JOINED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 01%'")
if [ "$D3_JOINED" -gt 0 ]; then pass "D3 joined strings returned (pref OFF again)"; else fail "D3" "joined strings not restored"; fi

stop_server

# ── Section E: Regression (pref ON) ──────────────────────────────────
echo ""
echo "=== Section E: Regression tests (pref ON) ==="

rm -f "$DB"
set_pref 1
start_server

# E1: Fixture 04 (singular only)
E1_NAME=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 04%'")
E1_DA=$(sqlite3 "$DB" "SELECT display_artist FROM albums WHERE title LIKE 'Fixture 04%'")
if [ "$E1_NAME" = "Adele" ]; then pass "E1 fixture 04 contributor: $E1_NAME"; else fail "E1" "contributor: $E1_NAME"; fi
if [ "$E1_DA" = "Adele" ]; then pass "E1 fixture 04 display_artist: $E1_DA"; else fail "E1" "display_artist: $E1_DA"; fi

# E2: Fixture 05 (semicolon joined)
E2_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 05%' AND ca.role = 5")
if [ "$E2_COUNT" -eq 2 ]; then pass "E2 fixture 05 split to 2 contributors"; else fail "E2" "got $E2_COUNT contributors"; fi

# E3: Fixture 06 (compilation)
E3_AA=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 06%' AND ca.role = 5")
E3_TA_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_track ct JOIN tracks t ON t.id = ct.track WHERE t.title = 'Fixture 06' AND ct.role = 1")
if echo "$E3_AA" | grep -q "Various Artists"; then pass "E3 fixture 06 VA albumartist"; else fail "E3" "albumartist: $E3_AA"; fi
if [ "$E3_TA_COUNT" -ge 2 ]; then pass "E3 fixture 06 track artists from ARTISTS ($E3_TA_COUNT)"; else fail "E3" "only $E3_TA_COUNT track artists"; fi

# E4: Fixture 07 (ft. case)
E4_DA=$(sqlite3 "$DB" "SELECT display_artist FROM tracks WHERE title = 'Fixture 07'")
E4_TA=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_track ct JOIN tracks t ON t.id = ct.track WHERE t.title = 'Fixture 07' AND ct.role = 6")
if [ "$E4_DA" = "Dr. Dre ft. Snoop Dogg" ]; then pass "E4 fixture 07 track display_artist: $E4_DA"; else fail "E4" "display_artist: $E4_DA"; fi
if [ "$E4_TA" -ge 2 ]; then pass "E4 fixture 07 trackartist contributors ($E4_TA)"; else fail "E4" "only $E4_TA trackartists"; fi

# E5: Fixture 17 (group with & in name)
E5_NAME=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 17%'")
if [ "$E5_NAME" = "Dimitri Vegas & Like Mike" ]; then pass "E5 fixture 17 not split: $E5_NAME"; else fail "E5" "name: $E5_NAME"; fi

# E6: Fixture 18 (unicode)
E6_NAME=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 18%'")
if echo "$E6_NAME" | grep -q "Axwell"; then pass "E6 fixture 18 unicode handled: $E6_NAME"; else fail "E6" "name: $E6_NAME"; fi

# ── Section C: Rescan scenarios ──────────────────────────────────────
echo ""
echo "=== Section C: Rescan scenarios (pref ON) ==="

# Save baseline
sqlite3 -separator $'\t' "$DB" "SELECT t.title, ct.role, c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title LIKE 'Fixture 19%' OR t.title LIKE 'Fixture 20%' ORDER BY t.title, ct.role, c.name" > "$RESULTS/c_baseline.txt"

# C1: Regular rescan (no changes)
echo "C1: Regular rescan (no changes)"
rescan
sqlite3 -separator $'\t' "$DB" "SELECT t.title, ct.role, c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title LIKE 'Fixture 19%' OR t.title LIKE 'Fixture 20%' ORDER BY t.title, ct.role, c.name" > "$RESULTS/c_after_rescan.txt"
if diff -q "$RESULTS/c_baseline.txt" "$RESULTS/c_after_rescan.txt" > /dev/null 2>&1; then pass "C1 no changes after regular rescan"; else fail "C1" "data changed"; fi

# C2-C4: Retag and rescan
echo "C2-C4: Retag + rescan"
python3 "$FIXTURES/scripts/retag_rescan_test.py" > /dev/null 2>&1
# Album rescan for fixtures 19-20 (touch files to trigger change detection)
touch "$FIXTURES/core/fixture_19.opus" "$FIXTURES/core/fixture_20.opus"
sleep 1
rescan

C3_NEW=$(sqlite3 "$DB" "SELECT c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title = 'Fixture 19' AND ct.role = 6 AND c.name = 'Eddie Gomez'")
if [ "$C3_NEW" = "Eddie Gomez" ]; then pass "C3 new track artist after rescan: Eddie Gomez"; else fail "C3" "Eddie Gomez not found after rescan"; fi

C4_DA=$(sqlite3 "$DB" "SELECT display_artist FROM albums WHERE title LIKE 'Fixture 19%'")
if [ "$C4_DA" = "Chick Corea & Gary Burton" ]; then pass "C4 album display_artist unchanged after retag"; else fail "C4" "display_artist = '$C4_DA'"; fi

# C6-C7: Restore and wipe & rescan
echo "C6-C7: Restore + wipe & rescan"
python3 "$FIXTURES/scripts/retag_rescan_test.py" --restore > /dev/null 2>&1
wipe_rescan
sqlite3 -separator $'\t' "$DB" "SELECT t.title, ct.role, c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title LIKE 'Fixture 19%' OR t.title LIKE 'Fixture 20%' ORDER BY t.title, ct.role, c.name" > "$RESULTS/c_after_restore.txt"
if diff -q "$RESULTS/c_baseline.txt" "$RESULTS/c_after_restore.txt" > /dev/null 2>&1; then pass "C7 restored to baseline after wipe & rescan"; else fail "C7" "not matching baseline"; fi

# ── Section H: API contract ──────────────────────────────────────────
echo ""
echo "=== Section H: API contract ==="

# H1: Album artist field is string
H1=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Fixture 19"]]}' | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]['artist']; print('string' if isinstance(a,str) else type(a).__name__)")
if [ "$H1" = "string" ]; then pass "H1 artist field is string"; else fail "H1" "artist is $H1"; fi

# H2: artists/artist_ids are comma-separated strings
H2=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:aaSS","search:Fixture 19"]]}')
H2_ARTISTS=$(echo "$H2" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]['artists']; print('string' if isinstance(a,str) else type(a).__name__)")
H2_IDS=$(echo "$H2" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]['artist_ids']; print('string' if isinstance(a,str) else type(a).__name__)")
if [ "$H2_ARTISTS" = "string" ]; then pass "H2 artists is comma-separated string"; else fail "H2" "artists is $H2_ARTISTS"; fi
if [ "$H2_IDS" = "string" ]; then pass "H2 artist_ids is comma-separated string"; else fail "H2" "artist_ids is $H2_IDS"; fi

# H3: Track query fields are strings
H3=$(api '{"method":"slim.request","params":["",["titles","0","5","tags:aAS","search:Fixture 19"]]}')
H3_AA=$(echo "$H3" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print('string' if isinstance(t.get('albumartist',''),str) else 'other')")
H3_TA=$(echo "$H3" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print('string' if isinstance(t.get('trackartist',''),str) else 'other')")
if [ "$H3_AA" = "string" ] && [ "$H3_TA" = "string" ]; then pass "H3 track fields are strings"; else fail "H3" "albumartist=$H3_AA trackartist=$H3_TA"; fi

# H4: display_artist is additive (existing fields still present)
H4=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:aaSS","search:Fixture 19"]]}')
H4_FIELDS=$(echo "$H4" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]; missing=[f for f in ['artist','artist_id','artists','artist_ids'] if f not in a]; print(','.join(missing) if missing else 'all_present')")
if [ "$H4_FIELDS" = "all_present" ]; then pass "H4 all existing fields present alongside display_artist"; else fail "H4" "missing: $H4_FIELDS"; fi

# H5: Single-artist album
H5=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Fixture 04"]]}')
H5_ARTIST=$(echo "$H5" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('artist',''))")
if [ "$H5_ARTIST" = "Adele" ]; then pass "H5 single-artist album: $H5_ARTIST"; else fail "H5" "artist = '$H5_ARTIST'"; fi

stop_server

echo ""
echo "=== Sections C/D/E/H Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "FAILURES detected"
exit $FAIL
