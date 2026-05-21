#!/usr/bin/env bash
set -uo pipefail

# Test: Fresh install with 3NF contributor_display schema
# Runs fresh scan with pref OFF then pref ON, verifies DB + API

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SLIMSERVER="${SLIMSERVER:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
FIXTURES="${FIXTURES:-$SCRIPT_DIR}"
PREFS="${PREFS:-/tmp/1555-prefs}"
RESULTS=/tmp/test_results/3nf_fresh
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
    kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null || true
    sleep 2
}

api() {
    curl -s "http://localhost:$PORT/jsonrpc.js" -d "$1"
}

set_pref() {
    if grep -q 'usePluralArtistTags' "$PREFS/server.prefs" 2>/dev/null; then
        perl -i -pe "s/usePluralArtistTags:\s*\d/usePluralArtistTags: $1/" "$PREFS/server.prefs"
    else
        echo "usePluralArtistTags: $1" >> "$PREFS/server.prefs"
    fi
}

# Tag fixtures
python3 "$FIXTURES/scripts/build_tags.py" "$FIXTURES/core" --names=realistic > /dev/null

rm -f "$RESULTS/failures.txt"

echo "=== 3NF Fresh Install Tests ==="
echo ""

# -- F1-F5: Pref OFF ----------------------------------------------------------
echo "--- F1-F5: Fresh scan, pref OFF ---"
rm -f "$DB"
set_pref 0

start_server

# F1: contributor_display table populated
echo "F1: contributor_display populated"
CD_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_display")
if [ "$CD_COUNT" -gt 0 ]; then pass "F1 contributor_display has $CD_COUNT rows"; else fail "F1" "contributor_display empty"; fi

# F2: albums.display_contributor set (FK, not NULL)
echo "F2: albums.display_contributor FK set"
ADC_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM albums WHERE display_contributor IS NOT NULL")
if [ "$ADC_COUNT" -gt 0 ]; then pass "F2 albums.display_contributor set ($ADC_COUNT)"; else fail "F2" "all albums.display_contributor NULL"; fi

# F3: tracks.display_contributor set
echo "F3: tracks.display_contributor FK set"
TDC_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tracks WHERE display_contributor IS NOT NULL AND audio = 1")
if [ "$TDC_COUNT" -gt 0 ]; then pass "F3 tracks.display_contributor set ($TDC_COUNT)"; else fail "F3" "all tracks.display_contributor NULL"; fi

# F4: contributor_album_display junction populated
echo "F4: contributor_album_display junction"
CAD_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album_display")
if [ "$CAD_COUNT" -gt 0 ]; then pass "F4 contributor_album_display has $CAD_COUNT rows"; else fail "F4" "junction empty"; fi

# F5: API returns display_artist as separate field
echo "F5: API display_artist field"
API_RESULT=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Fixture 01"]]}')
API_ARTIST=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('artist','MISSING'))")
API_DA=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('display_artist','MISSING'))")
if [ "$API_DA" != "MISSING" ] && [ -n "$API_DA" ]; then pass "F5 display_artist in API: $API_DA"; else fail "F5" "display_artist missing from API"; fi
# artist field = primary contributor name (not display string) in 3NF
if [ "$API_ARTIST" != "MISSING" ]; then pass "F5 artist field present: $API_ARTIST"; else fail "F5" "artist field missing"; fi

stop_server

# -- F6-F16: Pref ON ----------------------------------------------------------
echo ""
echo "--- F6-F16: Fresh scan, pref ON ---"
rm -f "$DB"
set_pref 1

start_server

# F6: No joined-string contributors for multi-artist fixtures
echo "F6: No joined-string contributors (pref ON)"
JOINED_19=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 19%'")
if [ "$JOINED_19" -eq 0 ]; then pass "F6 no joined strings for fixture 19"; else fail "F6" "found $JOINED_19 joined-string contributors"; fi

# F7: Fixtures 19-22 correct contributor counts
echo "F7: Fixture 19-22 contributor counts"
for fix_info in "19:4" "20:4" "21:2" "22:4"; do
    FIX="${fix_info%%:*}"
    EXPECTED="${fix_info##*:}"
    ACTUAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_track ct JOIN tracks t ON t.id = ct.track WHERE ct.role = 6 AND t.title = 'Fixture $FIX'")
    if [ "$ACTUAL" -eq "$EXPECTED" ]; then pass "F7 fixture $FIX: $ACTUAL trackartists"; else fail "F7" "fixture $FIX: got $ACTUAL trackartists, expected $EXPECTED"; fi
done

# F8: Fixture 21 scenario 3 - ARTISTS authoritative
echo "F8: Fixture 21 ARTISTS authoritative"
ROACH=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title = 'Fixture 21' AND c.name = 'Max Roach'")
if [ "$ROACH" -eq 0 ]; then pass "F8 Max Roach not in fixture 21"; else fail "F8" "Max Roach found in fixture 21"; fi

# F9: Album API (separate artist and display_artist)
echo "F9: Album API display_artist"
API_RESULT=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:aaSS","search:Fixture 19"]]}')
DA=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('display_artist','MISSING'))")
ARTISTS=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('artists','MISSING'))")
if [ "$DA" = "Chick Corea & Gary Burton" ]; then pass "F9 display_artist correct: $DA"; else fail "F9" "display_artist = '$DA'"; fi
if [ "$ARTISTS" = "Chick Corea,Gary Burton" ]; then pass "F9 artists = individuals"; else fail "F9" "artists = '$ARTISTS'"; fi

# F10: Track API display_artist
echo "F10: Track API display_artist"
TRACK_RESULT=$(api '{"method":"slim.request","params":["",["titles","0","5","tags:aAS","search:Fixture 19"]]}')
T_DA=$(echo "$TRACK_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print(t.get('display_artist','MISSING'))")
T_TA=$(echo "$TRACK_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print(t.get('trackartist','MISSING'))")
if [ "$T_DA" != "MISSING" ] && [ -n "$T_DA" ]; then pass "F10 track display_artist: $T_DA"; else fail "F10" "track display_artist missing"; fi
if echo "$T_TA" | grep -q "Dave Holland"; then pass "F10 trackartist includes Dave Holland"; else fail "F10" "trackartist = '$T_TA'"; fi

# F11: FTS search for display string
echo "F11: FTS for display string"
FTS_RESULT=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Chick Corea & Gary Burton"]]}')
FTS_COUNT=$(echo "$FTS_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['count'])")
if [ "$FTS_COUNT" -gt 0 ]; then pass "F11 FTS 'Chick Corea & Gary Burton' found $FTS_COUNT"; else fail "F11" "FTS returned 0 results"; fi

# F12: FTS search for individual contributor
echo "F12: FTS for individual"
FTS2_RESULT=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Chick Corea"]]}')
FTS2_COUNT=$(echo "$FTS2_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['count'])")
if [ "$FTS2_COUNT" -gt 0 ]; then pass "F12 FTS 'Chick Corea' found $FTS2_COUNT"; else fail "F12" "FTS returned 0 results"; fi

# F13: contributor_display name matches display string
echo "F13: contributor_display correctness"
CD_NAME=$(sqlite3 "$DB" "SELECT cd.name FROM contributor_display cd JOIN albums a ON a.display_contributor = cd.id WHERE a.title LIKE 'Fixture 19%'")
if [ "$CD_NAME" = "Chick Corea & Gary Burton" ]; then pass "F13 contributor_display name: $CD_NAME"; else fail "F13" "name = '$CD_NAME'"; fi

# F14: contributor_album_display junction maps contributors correctly
echo "F14: contributor_album_display junction"
CAD_NAMES=$(sqlite3 "$DB" "SELECT GROUP_CONCAT(c.name, ', ') FROM contributor_album_display cad JOIN contributors c ON c.id = cad.contributor JOIN albums a ON a.id = cad.album WHERE a.title LIKE 'Fixture 19%' ORDER BY c.name")
if echo "$CAD_NAMES" | grep -q "Chick Corea"; then pass "F14 junction has Chick Corea"; else fail "F14" "junction contributors = '$CAD_NAMES'"; fi
if echo "$CAD_NAMES" | grep -q "Gary Burton"; then pass "F14 junction has Gary Burton"; else fail "F14" "junction contributors = '$CAD_NAMES'"; fi

# F15: contributor_track_display junction populated
echo "F15: contributor_track_display junction"
CTD_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_track_display ctd JOIN tracks t ON t.id = ctd.track WHERE t.title = 'Fixture 19'")
if [ "$CTD_COUNT" -gt 0 ]; then pass "F15 contributor_track_display has $CTD_COUNT rows for fixture 19"; else fail "F15" "junction empty for fixture 19"; fi

# F16: Scalar plural tags (fixture 23)
echo "F16: Scalar plural tag handling"
F23_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 23%' AND ca.role = 5")
if [ "$F23_COUNT" -eq 2 ]; then pass "F16 fixture 23 scalar ALBUMARTISTS split to 2 contributors"; else fail "F16" "got $F23_COUNT contributors (expected 2)"; fi
F23_DA=$(sqlite3 "$DB" "SELECT cd.name FROM contributor_display cd JOIN albums a ON a.display_contributor = cd.id WHERE a.title LIKE 'Fixture 23%'")
if [ "$F23_DA" = "Bill Evans & Jim Hall" ]; then pass "F16 fixture 23 display_artist: $F23_DA"; else fail "F16" "display_artist = '$F23_DA'"; fi
F23_NAMES=$(sqlite3 "$DB" "SELECT GROUP_CONCAT(name, ', ') FROM (SELECT c.name AS name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 23%' AND ca.role = 5 ORDER BY c.name)")
if echo "$F23_NAMES" | grep -q "Bill Evans" && echo "$F23_NAMES" | grep -q "Jim Hall"; then pass "F16 fixture 23 individuals: $F23_NAMES"; else fail "F16" "individuals = '$F23_NAMES'"; fi

# F17: Regression fixtures
echo "F17: Regression checks"
# Fixture 04 (singular only)
E1_NAME=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 04%'")
if [ "$E1_NAME" = "Adele" ]; then pass "F17 fixture 04: $E1_NAME"; else fail "F17" "fixture 04 contributor: $E1_NAME"; fi
# Fixture 17 (group with & in name, should NOT be split)
E5_NAME=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 17%'")
if [ "$E5_NAME" = "Dimitri Vegas & Like Mike" ]; then pass "F17 fixture 17 not split: $E5_NAME"; else fail "F17" "fixture 17 name: $E5_NAME"; fi

stop_server

# Smoketest
echo ""
echo "F18: Smoketest"
cd "$SLIMSERVER"
if bash t/00_smoketest.sh > "$RESULTS/smoketest.log" 2>&1; then pass "F18 smoketest"; else fail "F18" "smoketest failed"; fi

echo ""
echo "=== 3NF Fresh Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "FAILURES - see $RESULTS/failures.txt"
exit $FAIL
