#!/usr/bin/env bash
set -uo pipefail

# Test: Rescan, pref toggle, API contract for 3NF schema

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SLIMSERVER="${SLIMSERVER:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
FIXTURES="${FIXTURES:-$SCRIPT_DIR}"
PREFS="${PREFS:-/tmp/1555-prefs}"
RESULTS=/tmp/test_results/3nf_rescan
DB="$PREFS/library.db"
PORT=9000
PASS=0
FAIL=0

mkdir -p "$RESULTS"

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1 -- $2"; FAIL=$((FAIL+1)); echo "$1: $2" >> "$RESULTS/failures.txt"; }

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

rescan() {
    api '{"method":"slim.request","params":["",["rescan","full"]]}' > /dev/null
    sleep 15
}

wipe_rescan() {
    api '{"method":"slim.request","params":["",["wipecache"]]}' > /dev/null
    sleep 20
}

set_pref() {
    if grep -q 'usePluralArtistTags' "$PREFS/server.prefs" 2>/dev/null; then
        perl -i -pe "s/usePluralArtistTags:\s*\d/usePluralArtistTags: $1/" "$PREFS/server.prefs"
    else
        echo "usePluralArtistTags: $1" >> "$PREFS/server.prefs"
    fi
}

python3 "$FIXTURES/scripts/build_tags.py" "$FIXTURES/core" --names=realistic > /dev/null
rm -f "$RESULTS/failures.txt"

# -- Pref toggle tests --------------------------------------------------------
echo "=== Pref Toggle Tests ==="

# P1: Scan with pref OFF
echo "P1: Scan pref OFF"
rm -f "$DB"
set_pref 0
start_server

P1_JOINED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 01%'")
if [ "$P1_JOINED" -gt 0 ]; then pass "P1 joined-string present (pref OFF)"; else fail "P1" "no joined strings"; fi

P1_CD=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_display")
if [ "$P1_CD" -gt 0 ]; then pass "P1 contributor_display populated even with pref OFF"; else fail "P1" "contributor_display empty"; fi

stop_server

# P2: Toggle ON, fresh DB
echo "P2: Toggle pref ON, fresh scan"
set_pref 1
rm -f "$DB"
start_server

P2_JOINED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 01%'")
if [ "$P2_JOINED" -eq 0 ]; then pass "P2 no joined strings (pref ON)"; else fail "P2" "found $P2_JOINED joined-string contributors"; fi

P2_INDIV=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 01%'")
if [ "$P2_INDIV" -eq 2 ]; then pass "P2 two individual contributors for fixture 01"; else fail "P2" "found $P2_INDIV contributors"; fi

# P3: Toggle OFF, fresh DB
echo "P3: Toggle pref OFF, fresh scan"
stop_server
set_pref 0
rm -f "$DB"
start_server

P3_JOINED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 01%'")
if [ "$P3_JOINED" -gt 0 ]; then pass "P3 joined strings returned (pref OFF again)"; else fail "P3" "joined strings not restored"; fi

# -- Rescan tests (keep server running, pref ON) ------------------------------
echo ""
echo "=== Rescan Tests (pref ON) ==="
stop_server
set_pref 1
rm -f "$DB"
start_server

# Save baseline
sqlite3 -separator $'\t' "$DB" "SELECT t.title, ct.role, c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title LIKE 'Fixture 19%' OR t.title LIKE 'Fixture 20%' ORDER BY t.title, ct.role, c.name" > "$RESULTS/baseline.txt"

# R1: Regular rescan (no changes)
echo "R1: Regular rescan (no changes)"
rescan
sqlite3 -separator $'\t' "$DB" "SELECT t.title, ct.role, c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title LIKE 'Fixture 19%' OR t.title LIKE 'Fixture 20%' ORDER BY t.title, ct.role, c.name" > "$RESULTS/after_rescan.txt"
if diff -q "$RESULTS/baseline.txt" "$RESULTS/after_rescan.txt" > /dev/null 2>&1; then pass "R1 no changes after regular rescan"; else fail "R1" "data changed"; fi

# R2: contributor_display stable across rescan
R2_CD_BEFORE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_display")
rescan
R2_CD_AFTER=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_display")
if [ "$R2_CD_BEFORE" -eq "$R2_CD_AFTER" ]; then pass "R2 contributor_display stable ($R2_CD_BEFORE rows)"; else fail "R2" "before=$R2_CD_BEFORE after=$R2_CD_AFTER"; fi

# R3-R4: Retag and rescan
echo "R3-R4: Retag + rescan"
python3 "$FIXTURES/scripts/retag_rescan_test.py" > /dev/null 2>&1
touch "$FIXTURES/core/fixture_19.opus" "$FIXTURES/core/fixture_20.opus"
sleep 1
rescan

R3_NEW=$(sqlite3 "$DB" "SELECT c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title = 'Fixture 19' AND ct.role = 6 AND c.name = 'Eddie Gomez'")
if [ "$R3_NEW" = "Eddie Gomez" ]; then pass "R3 new track artist after rescan: Eddie Gomez"; else fail "R3" "Eddie Gomez not found after rescan"; fi

R4_DA=$(sqlite3 "$DB" "SELECT cd.name FROM contributor_display cd JOIN albums a ON a.display_contributor = cd.id WHERE a.title LIKE 'Fixture 19%'")
if [ "$R4_DA" = "Chick Corea & Gary Burton" ]; then pass "R4 album display_artist unchanged after retag: $R4_DA"; else fail "R4" "display_artist = '$R4_DA'"; fi

# R5: Restore and wipe & rescan
echo "R5: Restore + wipe & rescan"
python3 "$FIXTURES/scripts/retag_rescan_test.py" --restore > /dev/null 2>&1
wipe_rescan
sqlite3 -separator $'\t' "$DB" "SELECT t.title, ct.role, c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title LIKE 'Fixture 19%' OR t.title LIKE 'Fixture 20%' ORDER BY t.title, ct.role, c.name" > "$RESULTS/after_restore.txt"
if diff -q "$RESULTS/baseline.txt" "$RESULTS/after_restore.txt" > /dev/null 2>&1; then pass "R5 restored to baseline"; else fail "R5" "not matching baseline"; fi

# -- API contract tests -------------------------------------------------------
echo ""
echo "=== API Contract Tests ==="

# A1: Album artist field is string, display_artist is separate
A1=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Fixture 19"]]}')
A1_ARTIST=$(echo "$A1" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]; print('string' if isinstance(a.get('artist',''),str) else 'other')")
A1_DA=$(echo "$A1" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]; print('string' if isinstance(a.get('display_artist',''),str) else 'other')")
if [ "$A1_ARTIST" = "string" ]; then pass "A1 artist field is string"; else fail "A1" "artist is $A1_ARTIST"; fi
if [ "$A1_DA" = "string" ]; then pass "A1 display_artist is string"; else fail "A1" "display_artist is $A1_DA"; fi

# A2: artists/artist_ids are comma-separated strings
A2=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:aaSS","search:Fixture 19"]]}')
A2_ARTISTS=$(echo "$A2" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]['artists']; print('string' if isinstance(a,str) else type(a).__name__)")
A2_IDS=$(echo "$A2" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]['artist_ids']; print('string' if isinstance(a,str) else type(a).__name__)")
if [ "$A2_ARTISTS" = "string" ]; then pass "A2 artists is string"; else fail "A2" "artists is $A2_ARTISTS"; fi
if [ "$A2_IDS" = "string" ]; then pass "A2 artist_ids is string"; else fail "A2" "artist_ids is $A2_IDS"; fi

# A3: Track query fields are strings
A3=$(api '{"method":"slim.request","params":["",["titles","0","5","tags:aAS","search:Fixture 19"]]}')
A3_DA=$(echo "$A3" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print('string' if isinstance(t.get('display_artist',''),str) else 'other')")
if [ "$A3_DA" = "string" ]; then pass "A3 track display_artist is string"; else fail "A3" "display_artist is $A3_DA"; fi

# A4: display_artist is additive (existing fields still present)
A4=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:aaSS","search:Fixture 19"]]}')
A4_FIELDS=$(echo "$A4" | python3 -c "import json,sys; d=json.load(sys.stdin); a=d['result']['albums_loop'][0]; missing=[f for f in ['artist','artist_id','artists','artist_ids'] if f not in a]; print(','.join(missing) if missing else 'all_present')")
if [ "$A4_FIELDS" = "all_present" ]; then pass "A4 all existing fields present"; else fail "A4" "missing: $A4_FIELDS"; fi

# A5: Single-artist album
A5=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Fixture 04"]]}')
A5_ARTIST=$(echo "$A5" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('artist','MISSING'))")
if [ "$A5_ARTIST" = "Adele" ]; then pass "A5 single-artist: $A5_ARTIST"; else fail "A5" "artist = '$A5_ARTIST'"; fi

stop_server

echo ""
echo "=== 3NF Rescan/Pref/API Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "FAILURES - see $RESULTS/failures.txt"
exit $FAIL
