#!/usr/bin/env bash
set -uo pipefail

# Test Section B: Schema upgrade from existing DB

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SLIMSERVER="${SLIMSERVER:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
FIXTURES="${FIXTURES:-$SCRIPT_DIR}"
PREFS="${PREFS:-/tmp/1555-prefs}"
RESULTS=/tmp/test_results/b_upgrade
DB="$PREFS/library.db"
PORT=9000
PASS=0
FAIL=0

mkdir -p "$RESULTS"

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1 -- $2"; FAIL=$((FAIL+1)); echo "$1: $2" >> "$RESULTS/failures.txt"; }

stop_server() {
    kill $SERVER_PID 2>/dev/null; wait $SERVER_PID 2>/dev/null || true; sleep 2
}

echo "=== Section B: Schema upgrade tests ==="

# Create old DB using upstream worktree
echo "Creating baseline DB on upstream public/9.2..."
git worktree add /tmp/lms-upstream-test public/9.2 2>/dev/null || (git worktree remove /tmp/lms-upstream-test 2>/dev/null && git worktree add /tmp/lms-upstream-test public/9.2)
rm -f "$DB"

cd /tmp/lms-upstream-test
perl slimserver.pl --logfile=/tmp/live-old.log --prefsdir="$PREFS" --cachedir="$PREFS" --httpport=$PORT &
SERVER_PID=$!
sleep 15

# Save baseline state
BASELINE_VERSION=$(sqlite3 "$DB" "SELECT version FROM dbix_migration" 2>/dev/null || echo "unknown")
BASELINE_DA_EXISTS=$(sqlite3 "$DB" "PRAGMA table_info(albums)" | grep -c display_artist || true)
sqlite3 -separator $'\t' "$DB" "SELECT c.name, ca.role FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 01%' ORDER BY c.name" > "$RESULTS/baseline_contributors.txt"

stop_server
git worktree remove /tmp/lms-upstream-test 2>/dev/null || true

echo "Baseline: schema $BASELINE_VERSION, display_artist columns: $BASELINE_DA_EXISTS"

# B1: Start server with our code against old DB
echo "Starting server with our code against old DB..."
cd "$SLIMSERVER"
perl slimserver.pl --logfile=/tmp/live.log --prefsdir="$PREFS" --cachedir="$PREFS" --httpport=$PORT &
SERVER_PID=$!
sleep 15

echo "B1: Schema migration"
sleep 2
NEW_VERSION=$(sqlite3 "$DB" "SELECT version FROM dbix_migration" 2>/dev/null || echo "")
if [ "$NEW_VERSION" = "27" ]; then pass "B1 schema at version 27"; else fail "B1" "schema version is $NEW_VERSION, expected 27"; fi

# B2: display_artist columns exist
echo "B2: Columns exist after migration"
DA_ALBUMS=$(sqlite3 "$DB" "PRAGMA table_info(albums)" | grep -c display_artist || true)
DA_TRACKS=$(sqlite3 "$DB" "PRAGMA table_info(tracks)" | grep -c display_artist || true)
if [ "$DA_ALBUMS" -gt 0 ] && [ "$DA_TRACKS" -gt 0 ]; then pass "B2 display_artist columns exist on both tables"; else fail "B2" "albums=$DA_ALBUMS tracks=$DA_TRACKS"; fi

# B4: display_artist populated (schema change triggers scan)
echo "B4: display_artist populated after auto-scan"
DA_POP=$(sqlite3 "$DB" "SELECT COUNT(*) FROM albums WHERE display_artist IS NOT NULL")
if [ "$DA_POP" -gt 0 ]; then pass "B4 display_artist populated ($DA_POP albums)"; else fail "B4" "display_artist still NULL everywhere"; fi

F01_DA=$(sqlite3 "$DB" "SELECT display_artist FROM albums WHERE title LIKE 'Fixture 01%'")
if [ "$F01_DA" = "Armin van Buuren & KI/KI" ]; then pass "B4 fixture 01 display_artist = '$F01_DA'"; else fail "B4" "fixture 01 display_artist = '$F01_DA'"; fi

# B5: Contributors - check fixture 04 (single artist, no plural) is unchanged
echo "B5: Contributor data for non-plural fixtures preserved"
F04_NAME=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 04%'")
if [ "$F04_NAME" = "Adele" ]; then pass "B5 fixture 04 contributor preserved: $F04_NAME"; else fail "B5" "fixture 04 contributor = '$F04_NAME'"; fi
F17_NAME=$(sqlite3 "$DB" "SELECT c.name FROM contributor_album ca JOIN contributors c ON c.id = ca.contributor JOIN albums a ON a.id = ca.album WHERE a.title LIKE 'Fixture 17%'")
if [ "$F17_NAME" = "Dimitri Vegas & Like Mike" ]; then pass "B5 fixture 17 group name preserved: $F17_NAME"; else fail "B5" "fixture 17 = '$F17_NAME'"; fi

# B6: API works
echo "B6: API after upgrade"
API_RESULT=$(curl -s "http://localhost:$PORT/jsonrpc.js" -d '{"method":"slim.request","params":["",["albums","0","5","tags:a","search:Fixture 01"]]}')
API_DA=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('display_artist','MISSING'))" 2>/dev/null)
API_ARTIST=$(echo "$API_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['albums_loop'][0].get('artist','MISSING'))" 2>/dev/null)
if [ "$API_DA" != "MISSING" ]; then pass "B6 API display_artist present: $API_DA"; else fail "B6" "display_artist missing from API"; fi
if [ "$API_ARTIST" = "Armin van Buuren & KI/KI" ]; then pass "B6 API artist = display string"; else fail "B6" "artist = '$API_ARTIST'"; fi

stop_server

echo ""
echo "=== Section B Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && echo "ALL TESTS PASSED" || echo "FAILURES - see $RESULTS/failures.txt"
exit $FAIL
