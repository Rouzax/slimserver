#!/usr/bin/env bash
# Dump contributor relationships for the 1555 fixtures.
DB="${1:-library.db}"
sqlite3 -separator $'\t' "$DB" <<'SQL'
SELECT '=== contributors ===';
SELECT id, name, COALESCE(musicbrainz_id,'') FROM contributors ORDER BY id;

SELECT '=== albums (primary contributor) ===';
SELECT a.title, c.name, a.compilation
FROM albums a LEFT JOIN contributors c ON c.id = a.contributor
ORDER BY a.title;

SELECT '=== contributor_album (role 1=ARTIST 5=ALBUMARTIST 6=TRACKARTIST) ===';
SELECT a.title, ca.role, c.name, COALESCE(c.musicbrainz_id,'')
FROM contributor_album ca
JOIN albums a ON a.id = ca.album
JOIN contributors c ON c.id = ca.contributor
ORDER BY a.title, ca.role, c.name;

SELECT '=== contributor_track (role 1=ARTIST 5=ALBUMARTIST 6=TRACKARTIST) ===';
SELECT t.title, ct.role, c.name, COALESCE(c.musicbrainz_id,'')
FROM contributor_track ct
JOIN tracks t ON t.id = ct.track
JOIN contributors c ON c.id = ct.contributor
ORDER BY t.title, ct.role, c.name;
SQL
