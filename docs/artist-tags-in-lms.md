# Artist tags in LMS

## Chapter 1: How artist tags work today (LMS 9.1)

### How it works

LMS reads two artist tags from each music file:

- **Album Artist**: who released the album. Shown on album cards and used for browsing.
- **Artist**: who performed the track. Shown in track listings and now-playing views.

LMS uses the text it finds in these tags as artist names in your library. If the Album Artist tag says "Adele", you get one artist entry called "Adele".

If a tag contains a combined name like "Shakira feat. Wyclef Jean" as a single value, that entire string becomes one artist entry. You cannot browse to "Shakira" or "Wyclef Jean" separately.

**Semicolon splitting.** LMS splits tag values on semicolons by default. If your Album Artist tag contains "Shakira; Wyclef Jean" as a single value, LMS creates two separate artist entries. The separator character can be changed under Settings > Behavior > "Split artist/genre tags on".

**Multiple values.** Some file formats support writing multiple values in the same tag (see the format reference below). In practice, most taggers write a single Album Artist value, even for collaborations. Semicolon splitting is the primary way to get separate artist entries from a single tag field in LMS 9.1.

**MusicBrainz IDs.** LMS pairs each ID with the corresponding artist name by position. If the number of IDs does not match the number of names, all IDs are dropped to avoid incorrect pairings.

**Tags that LMS ignores:** ALBUMARTISTS, ARTISTS, and any other plural artist tags have no effect in LMS 9.1. Even if your files contain them, LMS does not read them.

#### MP3 note

In MP3 files, the TPE2 frame is used as Album Artist by default. This can be changed to "Band" under Settings > Behavior > "Use TPE2 as Album Artist".

### What to check

**You see a combined name like "Shakira feat. Wyclef Jean" as a single artist:**
Your tag contains one value with that full string, and it does not contain a semicolon or other configured separator character. If you want separate artist entries, either use semicolons (e.g. "Shakira; Wyclef Jean") or have your tagger write them as separate values (see format reference).

**You see names split that should stay together (e.g. "Simon" and "Garfunkel" instead of "Simon & Garfunkel"):**
Your tag probably contains a semicolon. Check the separator setting under Settings > Behavior, or remove the semicolon from the tag value.

**You see unexpected artist names after a rescan:**
Check what your tagger actually wrote to the file. LMS displays exactly what it reads. Tools like Mp3tag, Picard, or Kid3 can show you the raw tag values.

**MusicBrainz IDs seem wrong or missing:**
If you have two artist names but three MusicBrainz IDs (or vice versa), LMS drops all IDs for that tag. The count must match exactly.


## Chapter 2: Plural artist tags (new)

### How it works

A new preference, **"Use plural artist tags for contributor creation"**, is available under Settings > Behavior. It is off by default.

When enabled, LMS reads two additional tags from each file:

- **ALBUMARTISTS**: individual album artists, one per value
- **ARTISTS**: individual track artists, one per value

These plural tags change how LMS creates artist entries in your library:

| Tag | Purpose |
|-----|---------|
| Album Artist / Artist (singular) | Display name. What you see on album cards and track listings. |
| ALBUMARTISTS / ARTISTS (plural) | Individual contributors. What you can browse and click through to. |

**Example.** A FLAC file tagged with:
- ALBUMARTIST = `Shakira feat. Wyclef Jean`
- ALBUMARTISTS = `Shakira`, `Wyclef Jean`

With the preference on: the album card shows "Shakira feat. Wyclef Jean" as the display name, and you get two separate, browsable artist entries for Shakira and Wyclef Jean.

With the preference off (or in LMS 9.1): only the singular tag is used. You get one artist entry called "Shakira feat. Wyclef Jean". The plural tags are ignored.

**What if I only have singular tags?**
Nothing changes. The preference only has an effect when plural tags are present. If your files have no ALBUMARTISTS or ARTISTS tags, behavior is identical to LMS 9.1.

**What if I only have plural tags (no singular)?**
LMS constructs a display name by joining the plural tag values with commas. Artists are created individually.

**What if the plural tag has fewer artists than the singular tag?**
The plural tag is authoritative. Artists listed only in the singular tag are not added as separate contributors.

**What if my singular tag has multiple values?**
If your Album Artist tag contains multiple values (e.g. two separate ALBUMARTIST fields in a FLAC file), only the first value is used as the display name. This can look incomplete on album cards. To control the display text, use a single Album Artist value with the full name you want shown (e.g. "Shakira feat. Wyclef Jean") and put the individual names in ALBUMARTISTS.

### What to check

**You enabled the preference but nothing changed:**
Your files probably do not contain ALBUMARTISTS or ARTISTS tags. Check with your tagger. Picard, SongKong, and Mp3tag can all write these tags, but each needs to be configured to do so.

**You see unexpected artists after enabling:**
Some taggers leave stale or incomplete plural tags in files. Check what your files actually contain. If the plural tags have values you do not want as contributors, either fix them or leave the preference off.

**Toggling the preference:**
Changing this setting triggers a full library rescan. This is expected. LMS needs to re-read all files to apply the new tag interpretation.


## Format reference

The table below shows how artist tags are named in each file format. Your tagger may show friendlier names, but these are what LMS reads.

| Purpose | FLAC / Ogg / Opus | MP3 (ID3v2) | MP4 / AAC |
|---------|-------------------|-------------|-----------|
| Album Artist (display) | ALBUMARTIST | TPE2 (*) | aART |
| Track Artist (display) | ARTIST | TPE1 | \xa9ART |
| Album Artists (individual) | ALBUMARTISTS | TXXX: ALBUMARTISTS | freeform: ALBUMARTISTS |
| Track Artists (individual) | ARTISTS | TXXX: ARTISTS | freeform: ARTISTS |

(*) TPE2 is treated as Album Artist by default. This can be changed under Settings > Behavior.

### How multiple values work

The plural tags need to hold one value per artist. How that works depends on the format:

**FLAC, Ogg Vorbis, Opus** (Vorbis comments): add one field per value. Most taggers show this as a list where you can add entries. This is the most straightforward format for multi-value tags.

**MP3** (ID3v2): plural tags use TXXX (user-defined text) frames. Multiple values are stored in a single frame separated by null bytes, which your tagger handles transparently.

**MP4 / AAC**: plural tags use freeform atoms. Multiple values can be stored per atom.

If your tagger does not support writing multiple values in a single tag, you can also write them as a semicolon-separated string (e.g. "Shakira; Wyclef Jean"). LMS will split on semicolons.

### MP3 limitation (temporary)

There is a known issue where TXXX frames in MP3 files currently return only the first value when multiple values are stored in a single frame. A fix is pending review. This affects ALBUMARTISTS and ARTISTS tags in MP3 files specifically.

Workaround: use semicolons within a single value (e.g. "Shakira; Wyclef Jean"). LMS will split these correctly. FLAC, Ogg, Opus, and MP4 files are not affected.
