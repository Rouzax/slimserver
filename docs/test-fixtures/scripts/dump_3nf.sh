#!/usr/bin/env bash
# Dump 3NF display_artist tables from LMS library DB
DB="${1:-library.db}"

echo "=== contributor_display ==="
sqlite3 -header -separator $'\t' "$DB" "SELECT id, name FROM contributor_display ORDER BY id"

echo ""
echo "=== albums.display_contributor ==="
sqlite3 -header -separator $'\t' "$DB" \
  "SELECT a.title, a.display_contributor, cd.name AS display_name
   FROM albums a
   LEFT JOIN contributor_display cd ON cd.id = a.display_contributor
   ORDER BY a.title"

echo ""
echo "=== tracks.display_contributor ==="
sqlite3 -header -separator $'\t' "$DB" \
  "SELECT t.title, t.display_contributor, cd.name AS display_name
   FROM tracks t
   LEFT JOIN contributor_display cd ON cd.id = t.display_contributor
   WHERE t.audio = 1
   ORDER BY t.title"

echo ""
echo "=== contributor_album_display ==="
sqlite3 -header -separator $'\t' "$DB" \
  "SELECT cd.name AS display_name, c.name AS contributor, a.title AS album
   FROM contributor_album_display cad
   JOIN contributor_display cd ON cd.id = cad.contributor_display
   JOIN contributors c ON c.id = cad.contributor
   JOIN albums a ON a.id = cad.album
   ORDER BY a.title, c.name"

echo ""
echo "=== contributor_track_display ==="
sqlite3 -header -separator $'\t' "$DB" \
  "SELECT cd.name AS display_name, c.name AS contributor, t.title AS track
   FROM contributor_track_display ctd
   JOIN contributor_display cd ON cd.id = ctd.contributor_display
   JOIN contributors c ON c.id = ctd.contributor
   JOIN tracks t ON t.id = ctd.track
   ORDER BY t.title, c.name"
