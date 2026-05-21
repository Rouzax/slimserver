#!/usr/bin/env bash
set -uo pipefail

# Test Section A: Fresh install
# Runs fresh scan with pref OFF then pref ON, verifies DB + API

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SLIMSERVER="${SLIMSERVER:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
FIXTURES="${FIXTURES:-$SCRIPT_DIR}"
PREFS="${PREFS:-/tmp/1555-prefs}"
RESULTS=/tmp/test_results/a_fresh
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

# Tag fixtures
python3 "$FIXTURES/scripts/build_tags.py" "$FIXTURES/core" --names=realistic > /dev/null

echo "=== Section A: Fresh install tests ==="
echo ""

# ── A1-A4: Pref OFF ──────────────────────────────────────────────────
echo "--- A1-A4: Fresh scan, pref OFF ---"
rm -f "$DB"
# Ensure pref is OFF (default)
perl -i -pe 's/usePluralArtistTags:\s*\d/usePluralArtistTags: 0/' "$PREFS/server.prefs" 2>/dev/null || true

start_server

# A1: display_artist populated
echo "A1: display_artist populated in albums"
DA_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM albums WHERE display_artist IS NOT NULL")
if [ "$DA_COUNT" -gt 0 ]; then pass "A1 albums.display_artist populated ($DA_COUNT rows)"; else fail "A1" "display_artist NULL everywhere"; fi

DA_TRACK_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tracks WHERE display_artist IS NOT NULL")
if [ "$DA_TRACK_COUNT" -gt 0 ]; then pass "A1 tracks.display_artist populated ($DA_TRACK_COUNT rows)"; else fail "A1" "tracks.display_artist NULL everywhere"; fi

# A2: Joined strings present (pref OFF = old behavior)
echo "A2: Contributor rows have joined strings (pref OFF)"
JOINED=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 01%'")
if [ "$JOINED" -gt 0 ]; then pass "A2 joined-string contributors present"; else fail "A2" "no joined-string contributors found"; fi

# A3: API returns display_artist
echo "A3: API returns display_artist"
API_DA=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Fixture 01"]]}' | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('display_artist','MISSING'))")
if [ "$API_DA" != "MISSING" ] && [ -n "$API_DA" ]; then pass "A3 display_artist in API: $API_DA"; else fail "A3" "display_artist missing from API"; fi

# A4: Fixtures 1-18 contributor count matches expectations
echo "A4: Fixtures 1-18 regression"
F04_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 04%'")
if [ "$F04_COUNT" -eq 1 ]; then pass "A4 fixture 04 single contributor"; else fail "A4" "fixture 04 has $F04_COUNT contributors (expected 1)"; fi

stop_server

# ── A5-A14: Pref ON ──────────────────────────────────────────────────
echo ""
echo "--- A5-A14: Fresh scan, pref ON ---"
rm -f "$DB"
# Enable pref
if grep -q 'usePluralArtistTags' "$PREFS/server.prefs" 2>/dev/null; then
    perl -i -pe 's/usePluralArtistTags:\s*\d/usePluralArtistTags: 1/' "$PREFS/server.prefs"
else
    echo "usePluralArtistTags: 1" >> "$PREFS/server.prefs"
fi

start_server

# A5: No joined-string contributors for fixture 19
echo "A5: No joined-string contributors (pref ON)"
JOINED_19=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE c.name LIKE '%&%' AND a.title LIKE 'Fixture 19%'")
if [ "$JOINED_19" -eq 0 ]; then pass "A5 no joined strings for fixture 19"; else fail "A5" "found $JOINED_19 joined-string contributors"; fi

# A6: Fixtures 19-22 correct contributor counts
echo "A6: Fixture 19-22 contributor counts"
for fix_info in "19:4" "20:4" "21:2" "22:4"; do
    FIX="${fix_info%%:*}"
    EXPECTED="${fix_info##*:}"
    ACTUAL=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_track ct JOIN tracks t ON t.id = ct.track WHERE ct.role = 6 AND t.title = 'Fixture $FIX'")
    if [ "$ACTUAL" -eq "$EXPECTED" ]; then pass "A6 fixture $FIX: $ACTUAL trackartists"; else fail "A6" "fixture $FIX: got $ACTUAL trackartists, expected $EXPECTED"; fi
done

# A7: Fixture 21 scenario 3 - no Max Roach/Richie Powell
echo "A7: Fixture 21 ARTISTS authoritative"
ROACH=$(sqlite3 "$DB" "SELECT COUNT(*) FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title = 'Fixture 21' AND c.name = 'Max Roach'")
if [ "$ROACH" -eq 0 ]; then pass "A7 Max Roach not in fixture 21 (ARTISTS authoritative)"; else fail "A7" "Max Roach found in fixture 21"; fi

# A10: Album API
echo "A10: Album API display_artist"
API_RESULT=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:aaSS","search:Fixture 19"]]}')
ARTIST=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('artist',''))")
DA=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('display_artist',''))")
ARTISTS=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('artists',''))")
if [ "$ARTIST" = "Chick Corea & Gary Burton" ]; then pass "A10 artist field = display string"; else fail "A10" "artist = '$ARTIST'"; fi
if [ "$DA" = "Chick Corea & Gary Burton" ]; then pass "A10 display_artist correct"; else fail "A10" "display_artist = '$DA'"; fi
if [ "$ARTISTS" = "Chick Corea,Gary Burton" ]; then pass "A10 artists = individuals"; else fail "A10" "artists = '$ARTISTS'"; fi

# A11: Track API
echo "A11: Track API"
TRACK_RESULT=$(api '{"method":"slim.request","params":["",["titles","0","5","tags:aAS","search:Fixture 19"]]}')
T_DA=$(echo "$TRACK_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print(t.get('display_artist',''))")
T_TA=$(echo "$TRACK_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print(t.get('trackartist',''))")
T_TAIDS=$(echo "$TRACK_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); l=d['result']['titles_loop']; t=[x for x in l if x['title']=='Fixture 19'][0]; print(t.get('trackartist_ids',''))")
if [ -n "$T_DA" ]; then pass "A11 track display_artist present: $T_DA"; else fail "A11" "track display_artist missing"; fi
if echo "$T_TA" | grep -q "Dave Holland"; then pass "A11 trackartist includes Dave Holland"; else fail "A11" "trackartist = '$T_TA'"; fi
if echo "$T_TAIDS" | grep -q ","; then pass "A11 trackartist_ids has multiple IDs"; else fail "A11" "trackartist_ids = '$T_TAIDS'"; fi

# A12: Fulltext search for display string
echo "A12: Fulltext search for display string"
FTS_RESULT=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Chick Corea & Gary Burton"]]}')
FTS_COUNT=$(echo "$FTS_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['count'])")
if [ "$FTS_COUNT" -gt 0 ]; then pass "A12 search 'Chick Corea & Gary Burton' found $FTS_COUNT results"; else fail "A12" "search returned 0 results"; fi

# A13: Fulltext search for individual contributor
echo "A13: Fulltext search for individual"
FTS2_RESULT=$(api '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Chick Corea"]]}')
FTS2_COUNT=$(echo "$FTS2_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['count'])")
if [ "$FTS2_COUNT" -gt 0 ]; then pass "A13 search 'Chick Corea' found $FTS2_COUNT results"; else fail "A13" "search returned 0 results"; fi

# Save DB state for later comparison
sqlite3 -separator $'\t' "$DB" "SELECT t.title, ct.role, c.name FROM contributor_track ct JOIN tracks t ON t.id = ct.track JOIN contributors c ON c.id = ct.contributor WHERE t.title LIKE 'Fixture 1%' OR t.title LIKE 'Fixture 2%' ORDER BY t.title, ct.role, c.name" > "$RESULTS/a6_contributor_track.txt"

stop_server

# A14: Smoketest
echo "A14: Smoketest"
cd "$SLIMSERVER"
if bash t/00_smoketest.sh > "$RESULTS/smoketest.log" 2>&1; then pass "A14 smoketest"; else fail "A14" "smoketest failed"; fi

echo ""
echo "=== Section A Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "FAILURES - see $RESULTS/failures.txt"
exit $FAIL
