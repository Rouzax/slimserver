# Test fixtures for display_artist / plural artist tags

Test fixtures for verifying how LMS handles different ALBUMARTIST / ALBUMARTISTS tag combinations.

These fixtures are used to verify the scan behavior documented in [scan-behavior-matrix.md](../scan-behavior-matrix.md).

The "Separator for Multiple Items in Tags" preference is set to the default: `;`

## Directory layout

```
test-fixtures/
├── README.md
├── core/              25 core Opus fixtures (Art1, Art2, ... abstract names)
├── cross/             Same album across FLAC, M4A, MP3 v2.3, MP3 v2.4
├── forum/             Real-world tagging examples from the forum thread
├── multitrack/        Three tracks on one album, different track artists
├── multidisc/         Two-disc album + album name collision
├── va/                Various Artists compilation
├── variant/           Same MBID, different ALBUMARTIST strings
├── scripts/           Build, dump, and retag scripts
└── tests/             Automated scan test scripts
```

## How to use

1. Point LMS at a directory containing fixture files (e.g. `core/` or `multitrack/`)
2. Run a full scan (wipe + rescan)
3. Query the database or API to check contributor rows and display_artist values
4. Toggle the `usePluralArtistTags` preference and rescan to compare

## Tag notation

- `ALBUMARTIST="Art1 & Art2"` = one tag field with that value (scalar)
- `ALBUMARTIST=Art1 | Art2` = two separate tag fields (Vorbis comments), Audio::Scan returns an arrayref
- `ALBUMARTISTS="Art1; Art2"` = one tag field with semicolon (scalar, split by splitList pref)

## Core fixtures (`core/`)

Each file is one track, one album, tagged with abstract names (Art1, Art2, etc.).

### Group A: Display artist scenarios

**Fixture 01** - Typical MusicBrainz tagging
```
ALBUMARTIST  = "Art1 & Art2"
ALBUMARTISTS = Art1 | Art2
MBIDs        = yes (2)
```
Tests: scalar display string preserved, plural creates individual contributors.

**Fixture 02** - Same as 01, no MBIDs
```
ALBUMARTIST  = "Art3 & Art4"
ALBUMARTISTS = Art3 | Art4
MBIDs        = no
```
Tests: plural tag processing works without MBIDs.

**Fixture 03** - Three artists with MBIDs
```
ALBUMARTIST  = "Art5, Art6 & Art7"
ALBUMARTISTS = Art5 | Art6 | Art7
MBIDs        = yes (3)
```
Tests: three-way split with aligned MBIDs.

**Fixture 04** - Single artist, no plural tags
```
ALBUMARTIST  = "Art8"
```
Tests: regression guard. No plural tags, nothing should change.

**Fixture 05** - Semicolon-separated singular, no plural
```
ALBUMARTIST  = "Art9; Art10"
```
Tests: splitList separator (`;`) splits into two contributors. No plural tags involved.

**Fixture 06** - Compilation with track-level plural
```
COMPILATION  = 1
ALBUMARTIST  = "Various Artists"
ARTIST       = "Art11 & Art12"
ARTISTS      = Art11 | Art12
MBIDs        = yes (ARTISTID only)
```
Tests: track-level ARTISTS override on a compilation album.

**Fixture 07** - ft. track-artist case
```
ALBUMARTIST  = "Art13"
ARTIST       = "Art13 ft. Art14"
ARTISTS      = Art13 | Art14
MBIDs        = yes (both levels)
```
Tests: TRACKARTIST transform + ARTISTS plural override at track level.

**Fixture 12** - Multi-field singular = multi-field plural (identical)
```
ALBUMARTIST  = Art23 | Art24  (two fields)
ALBUMARTISTS = Art23 | Art24  (two fields)
MBIDs        = yes (2)
```
Tests: multi-field singular with matching plural. display_artist = first field only.

**Fixture 13** - SongKong-style (display + individuals in singular)
```
ALBUMARTIST  = "Art25 & Art26" | Art25 | Art26  (three fields)
ALBUMARTISTS = Art25 | Art26
MBIDs        = yes (2)
```
Tests: first field used as display, plural replaces all three for contributors.

**Fixture 16** - Multi-field singular, fewer values in plural
```
ALBUMARTIST  = "Art31 Ensemble" | Art31  (two fields)
ALBUMARTISTS = Art31  (one field)
```
Tests: plural has fewer entries than singular. Group name in display, member as contributor.

### Group B: MBID handling and edge cases

**Fixture 08** - Empty name slot in plural (tagger bug)
```
ALBUMARTIST  = "Art15, , Art16"
ALBUMARTISTS = Art15 | "" | Art16
MBIDs        = yes (3, middle is placeholder)
```
Tests: empty plural value filtered out, contributor created for Art15 and Art16 only.

**Fixture 09** - Plural present, singular missing
```
ALBUMARTISTS = Art17 | Art18
MBIDs        = yes (2)
```
Tests: no ALBUMARTIST tag at all. display_artist falls back to joining plural values.

**Fixture 10** - Scalar plural (buggy tagger)
```
ALBUMARTIST  = "Art19 & Art20"
ALBUMARTISTS = "Art19; Art20"  (one field, semicolon-joined)
```
Tests: splitTag splits the scalar plural by `;` separator.

**Fixture 11** - MBID count mismatch
```
ALBUMARTIST  = "Art21 & Art22"
ALBUMARTISTS = Art21 | Art22
MBIDs        = 1 (but 2 artists)
```
Tests: MBID guard drops ambiguous MBIDs when count differs from name count.

**Fixture 14** - Multi-field singular, no plural (group + member)
```
ALBUMARTIST  = "Art27 Ensemble" | Art27  (two fields)
```
Tests: no plural tags. Both group name and member kept as contributors.

**Fixture 15** - Multi-field singular, no plural, with MBIDs
```
ALBUMARTIST  = "Art29 & Art30" | Art29 | Art30  (three fields)
MBIDs        = yes (2)
```
Tests: no plural tags. Display + individuals all kept as contributors.

### Group C: Special cases

**Fixture 17** - Group name with "&", single MBID
```
ALBUMARTIST  = "Art33"
MBIDs        = 1
```
Tests: single entity that looks like two artists. Should not be split.

**Fixture 18** - Unicode in name, single MBID
```
ALBUMARTIST  = "Art34"
MBIDs        = 1
```
Tests: unicode handling, single entity not split.

**Fixture 23** - Scalar singular + scalar plural (semicolon-joined)
```
ALBUMARTIST  = "Art53 & Art54"
ALBUMARTISTS = "Art53; Art54"  (one field, semicolon)
ARTIST       = "Art53 & Art54"
ARTISTS      = "Art53; Art54"  (one field, semicolon)
MBIDs        = yes (2)
```
Tests: both singular and plural are scalars. splitTag handles plural semicolon.

**Fixture 24** - Semicolon singular + multi-field plural (equivalence test)
```
ALBUMARTIST  = "Art55; Art56"  (one field, semicolon)
ALBUMARTISTS = Art55 | Art56   (two fields)
MBIDs        = yes (2)
```
Tests: darrell's equivalence case. Compare with fixture 12 (two ALBUMARTIST fields). Should these produce the same display_artist?

**Fixture 25** - Multi-field singular + plural with different content
```
ALBUMARTIST  = Art57 | Art58   (two fields)
ALBUMARTISTS = Art57 | Art59   (two fields, Art58 replaced by Art59)
MBIDs        = yes (2)
```
Tests: data loss scenario. With pref ON, Art58 disappears, Art59 takes its place.

### Group D: Track artist display scenarios

**Fixture 19** - ARTIST multi-field = ARTISTS multi-field
```
ALBUMARTIST  = "Art37 & Art38"     ALBUMARTISTS = Art37 | Art38
ARTIST       = Art37 | Art38 | Art39 | Art40  (four fields)
ARTISTS      = Art37 | Art38 | Art39 | Art40  (four fields)
MBIDs        = yes (all)
```
Tests: all track artists present in both singular and plural.

**Fixture 20** - ARTIST has display + extras, ARTISTS has all individuals
```
ALBUMARTIST  = "Art41 & Art42"     ALBUMARTISTS = Art41 | Art42
ARTIST       = "Art41 & Art42" | Art43 | Art44  (display + extras)
ARTISTS      = Art41 | Art42 | Art43 | Art44    (all individuals)
MBIDs        = yes (all)
```
Tests: ARTISTS replaces ARTIST including the display string, all four individuals created.

**Fixture 21** - ARTISTS has fewer entries than ARTIST
```
ALBUMARTIST  = "Art45 & Art46"     ALBUMARTISTS = Art45 | Art46
ARTIST       = "Art45 & Art46" | Art47 | Art48  (display + extras)
ARTISTS      = Art45 | Art46                     (only two)
MBIDs        = yes (ARTISTS only)
```
Tests: Art47 and Art48 lost when pref ON. ARTISTS is authoritative.

**Fixture 22** - ARTIST multi-field, no ARTISTS tag
```
ALBUMARTIST  = "Art49 & Art50"     ALBUMARTISTS = Art49 | Art50
ARTIST       = Art49 | Art50 | Art51 | Art52  (four fields)
(no ARTISTS tag)
MBIDs        = yes (all)
```
Tests: no ARTISTS tag means no track-level override. Art51, Art52 preserved.

---

## Supplementary fixture sets

These use real artist names and MBIDs rather than abstract Art1/Art2 names. They cover scenarios that need multiple tracks per album or multiple audio formats.

### cross/ - Cross-format comparison

Four files containing the same album tagged identically across formats. Tests that FLAC, M4A, MP3 v2.3, and MP3 v2.4 all produce the same scan result.

| File | Format | ALBUMARTIST | ALBUMARTISTS | MBIDs |
|------|--------|-------------|--------------|-------|
| cross.flac | FLAC (Vorbis) | "Armin van Buuren & KI/KI" | Armin van Buuren \| KI/KI | yes (2) |
| cross.m4a | MP4/AAC | "Armin van Buuren & KI/KI" | Armin van Buuren \| KI/KI | yes (2) |
| cross_v23.mp3 | MP3 ID3v2.3 | "Armin van Buuren & KI/KI" | Armin van Buuren \| KI/KI | yes (2) |
| cross_v24.mp3 | MP3 ID3v2.4 | "Armin van Buuren & KI/KI" | Armin van Buuren \| KI/KI | yes (2) |

Note: MP3 TXXX frames store multi-value via null separators. Audio::Scan may truncate to the first value (see Audio::Scan PR #11).

### forum/ - Real-world examples from forum discussion

Five files reproducing tagging patterns that users posted in the Lyrion forum thread.

| File | ALBUMARTIST | ALBUMARTISTS | Notes |
|------|-------------|--------------|-------|
| bill.opus | "Bill Evans Trio with Scott LaFaro & Paul Motian" | Bill Evans Trio \| Scott LaFaro \| Paul Motian | Group + members, 3 MBIDs |
| charlesll.opus | "Charles Lloyd & The Marvels" | Charles Lloyd \| The Marvels | Artist + group, 2 MBIDs |
| obscure.opus | "An Artist" | (none) | Track-level "feat." in ARTIST, no plural tags |
| peterpaul.opus | "Peter, Paul and Mary" | Peter, Paul and Mary | Singular plural (same value), no MBIDs |
| prince.opus | "Prince and the Revolution" | Prince | Display is group, plural is individual member only |

### multitrack/ - Multiple tracks, same album

Three tracks on one album. Same ALBUMARTIST/ALBUMARTISTS, different track artists.

| File | ARTIST | ARTISTS | Notes |
|------|--------|---------|-------|
| track01.opus | Armin van Buuren | Armin van Buuren | Solo track |
| track02.opus | KI/KI | KI/KI | Solo track, other album artist |
| track03.opus | "Armin van Buuren ft. KI/KI" | Armin van Buuren \| KI/KI | ft. display + plural override |

All tracks share: ALBUMARTIST = "Armin van Buuren & KI/KI", ALBUMARTISTS = Armin van Buuren | KI/KI, 2 album artist MBIDs.

### multidisc/ - Multi-disc album + album name collision

Five tracks across two releases that share the album name "Greatest Hits".

| File | ALBUMARTIST | Disc | Track | Notes |
|------|-------------|------|-------|-------|
| d1t1.opus | "Armin van Buuren & KI/KI" | 1 of 2 | 1 | Standard multi-disc |
| d1t2.opus | "Armin van Buuren & KI/KI" | 1 of 2 | 2 | Standard multi-disc |
| d2t1.opus | "Armin van Buuren & KI/KI" | 2 of 2 | 1 | Standard multi-disc |
| d2t2.opus | "Armin van Buuren & KI/KI" | 2 of 2 | 2 | Standard multi-disc |
| other_d1t1.opus | "Hall & Oates" | 1 | 1 | Different artist, same album name |

Tests: album grouping by ALBUMARTIST + album name. The "Hall & Oates" track must not merge with the Armin van Buuren discs.

### va/ - Various Artists compilation

Three tracks on a compilation album (COMPILATION=1, ALBUMARTIST="Various Artists").

| File | ARTIST | ARTISTS | Track artist MBIDs |
|------|--------|---------|--------------------|
| va01.opus | Norah Jones | Norah Jones | yes (1) |
| va02.opus | "Armin van Buuren & KI/KI" | Armin van Buuren \| KI/KI | yes (2) |
| va03.opus | Diana Krall | Diana Krall | yes (1) |

Tests: track-level ARTISTS plural override on a VA compilation. Album-level tags are "Various Artists" with the VA MBID.

### variant/ - Same MBID, different ALBUMARTIST strings

Two files with the same MUSICBRAINZ_ALBUMARTISTID but different ALBUMARTIST text.

| File | ALBUMARTIST | MBID |
|------|-------------|------|
| solo.opus | "Bill Evans" | aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee |
| trio.opus | "Bill Evans Trio" | aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee |

Tests: how LMS handles contributor deduplication when the MBID matches but the display name differs.

### tests/ - Automated scan test scripts

Shell scripts that run scanner.pl against fixture directories and verify database state.

| Script | What it tests |
|--------|---------------|
| test_3nf_fresh.sh | Fresh scan with display_artist schema (3NF) |
| test_3nf_rescan.sh | Rescan after initial 3NF scan (idempotency) |
| test_a_fresh.sh | Group A fixtures, fresh scan |
| test_b_upgrade.sh | Group B fixtures, upgrade path from old schema |
| test_cdeh.sh | Groups C/D edge cases and MBID handling |

---

## Scripts (`scripts/`)

The fixture files are built by `build_tags.py` using mutagen. Supporting shell scripts call it with different configurations.

| Script | Purpose |
|--------|---------|
| build_tags.py | Main tagger. Creates silent audio and applies tags for all fixture sets. |
| build.sh | Builds the 25 core fixtures (fixture_01 through fixture_25). |
| build_cross.sh | Builds the cross-format set (FLAC, M4A, MP3 v2.3, MP3 v2.4). |
| build_forum_examples.sh | Builds the forum example set. |
| build_multitrack.sh | Builds the multi-track album set. |
| build_multidisc.sh | Builds the multi-disc album set. |
| build_va.sh | Builds the Various Artists compilation set. |
| build_variant.sh | Builds the variant name set. |
| dump.sh | Dumps tags from all fixtures using opusinfo/mutagen. |
| dump_3nf.sh | Dumps 3NF-related database tables after a scan. |
| dump_darrell.sh | Dumps contributor data matching darrell's schema. |
| retag_rescan_test.py | Retags core fixtures 19-22 for rescan change detection tests. |
| retag_supplementary.py | Retags supplementary fixtures with realistic names. |
