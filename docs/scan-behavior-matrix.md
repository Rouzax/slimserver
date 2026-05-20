# Verified scan results: old vs new code

All results from actual LMS scans against tagged Opus fixtures using abstract artist names (Art1, Art2, etc.).
Three configurations: old code (public/9.2), new code pref OFF, new code pref ON.

Separator pref: default `;`.

## Fixture tag summary

| # | ALBUMARTIST | ALBUMARTISTS | Description |
|---|---|---|---|
| 01 | `Art1 & Art2` (scalar) | `Art1`, `Art2` (two fields) | Typical MB: display + plural |
| 02 | `Art3 & Art4` (scalar) | `Art3`, `Art4` (two fields) | Same, no MBIDs |
| 03 | `Art5, Art6 & Art7` (scalar) | `Art5`, `Art6`, `Art7` (three fields) | Three artists |
| 04 | `Art8` (scalar) | (none) | Single artist, no plural |
| 05 | `Art9; Art10` (scalar, semicolon) | (none) | Semicolon-separated, no plural |
| 09 | (none) | `Art17`, `Art18` (two fields) | Plural only, no singular |
| 10 | `Art19 & Art20` (scalar) | `Art19; Art20` (scalar, semicolon) | Scalar plural (buggy tagger) |
| 12 | `Art23`, `Art24` (two fields) | `Art23`, `Art24` (two fields) | Multi-field singular = plural |
| 13 | `Art25 & Art26`, `Art25`, `Art26` (three fields) | `Art25`, `Art26` (two fields) | SongKong style: display + individuals |
| 14 | `Art27 Ensemble`, `Art27` (two fields) | (none) | Multi-field singular, no plural |
| 15 | `Art29 & Art30`, `Art29`, `Art30` (three fields) | (none) | Multi-field singular, no plural, with MBIDs |
| 16 | `Art31 Ensemble`, `Art31` (two fields) | `Art31` (one field) | Multi-field singular, fewer plural |
| 23 | `Art53 & Art54` (scalar) | `Art53; Art54` (scalar, semicolon) | Both scalar, tagger used semicolon in plural |
| 24 | `Art55; Art56` (scalar, semicolon) | `Art55`, `Art56` (two fields) | Darrell equivalence: semicolon singular + arrayref plural |
| 25 | `Art57`, `Art58` (two fields) | `Art57`, `Art59` (two fields, different!) | Data loss concern: plural differs from singular |

## Results comparison

### Column key
- **primary**: `albums.contributor` -> `contributors.name` (the FK used by the old `a` tag)
- **display_artist**: `contributor_display.name` (new column, shown by new `a` tag via COALESCE)
- **contributors**: all ALBUMARTIST role entries in `contributor_album`
- **display junction**: `contributor_album_display` linking display name to individual contributors

### Fixture 01: Scalar singular + multi-value plural (typical MusicBrainz)
Tags: `ALBUMARTIST="Art1 & Art2"`, `ALBUMARTISTS=Art1 | Art2`

| | primary | display_artist | contributors (role 5) |
|---|---|---|---|
| Old | Art1 & Art2 | (n/a) | Art1 & Art2 |
| New OFF | Art1 & Art2 | Art1 & Art2 | Art1 & Art2 |
| New ON | Art1 | Art1 & Art2 | Art1, Art2 |

### Fixture 04: Single artist, no plural tags
Tags: `ALBUMARTIST="Art8"`

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art8 | (n/a) | Art8 |
| New OFF | Art8 | Art8 | Art8 |
| New ON | Art8 | Art8 | Art8 |

No change across all three. Good.

### Fixture 05: Semicolon-separated singular, no plural tags
Tags: `ALBUMARTIST="Art9; Art10"`

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art9 | (n/a) | Art9, Art10 |
| New OFF | Art9 | Art9; Art10 | Art9, Art10 |
| New ON | Art9 | Art9; Art10 | Art9, Art10 |

Note: old code shows "Art9" on album card (primary FK). New code shows "Art9; Art10" (display_artist preserved the full string). Contributors identical.

### Fixture 09: Plural only, no singular tag
Tags: `ALBUMARTISTS=Art17 | Art18`

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | No Artist | (n/a) | No Artist |
| New OFF | No Artist | Art17, Art18 | No Artist |
| New ON | Art17 | Art17, Art18 | Art17, Art18 |

Note: display_artist fallback joins plural values with ", " when no singular tag exists.

### Fixture 10: Scalar plural (buggy tagger, semicolon-joined)
Tags: `ALBUMARTIST="Art19 & Art20"`, `ALBUMARTISTS="Art19; Art20"` (single field, semicolon)

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art19 & Art20 | (n/a) | Art19 & Art20 |
| New OFF | Art19 & Art20 | Art19 & Art20 | Art19 & Art20 |
| New ON | Art19 | Art19 & Art20 | Art19, Art20 |

splitTag correctly splits the scalar plural by `;`.

### Fixture 12: Multi-field singular = multi-field plural (identical)
Tags: `ALBUMARTIST=Art23 | Art24` (two fields), `ALBUMARTISTS=Art23 | Art24` (two fields)

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art23 | (n/a) | Art23, Art24 |
| New OFF | Art23 | Art23 | Art23, Art24 |
| New ON | Art23 | Art23 | Art23, Art24 |

display_artist = "Art23" (first element of arrayref). Contributors same in all three.

### Fixture 13: SongKong-style (display + individuals in singular, individuals in plural)
Tags: `ALBUMARTIST="Art25 & Art26" | Art25 | Art26` (three fields), `ALBUMARTISTS=Art25 | Art26`

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art25 & Art26 | (n/a) | Art25, Art25 & Art26, Art26 |
| New OFF | Art25 & Art26 | Art25 & Art26 | Art25, Art25 & Art26, Art26 |
| New ON | Art25 | Art25 & Art26 | Art25, Art26 |

Pref ON: "Art25 & Art26" contributor row gone (plural replaces singular). Display preserved.

### Fixture 14: Multi-field singular, no plural (group + member)
Tags: `ALBUMARTIST="Art27 Ensemble" | Art27` (two fields)

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art27 Ensemble | (n/a) | Art27, Art27 Ensemble |
| New OFF | Art27 Ensemble | Art27 Ensemble | Art27, Art27 Ensemble |
| New ON | Art27 Ensemble | Art27 Ensemble | Art27, Art27 Ensemble |

No plural tags, so pref ON has no effect. Same in all three.

### Fixture 15: Multi-field singular, no plural, with MBIDs
Tags: `ALBUMARTIST="Art29 & Art30" | Art29 | Art30` (three fields), MBIDs present

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art29 & Art30 | (n/a) | Art29, Art29 & Art30, Art30 |
| New OFF | Art29 & Art30 | Art29 & Art30 | Art29, Art29 & Art30, Art30 |
| New ON | Art29 & Art30 | Art29 & Art30 | Art29, Art29 & Art30, Art30 |

No plural tags, pref ON has no effect.

### Fixture 16: Multi-field singular, fewer values in plural
Tags: `ALBUMARTIST="Art31 Ensemble" | Art31` (two fields), `ALBUMARTISTS=Art31` (one field)

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art31 Ensemble | (n/a) | Art31, Art31 Ensemble |
| New OFF | Art31 Ensemble | Art31 Ensemble | Art31, Art31 Ensemble |
| New ON | Art31 | Art31 Ensemble | Art31 |

Pref ON: "Art31 Ensemble" contributor gone (plural has only Art31). Display preserved as "Art31 Ensemble".

### Fixture 23: Scalar singular + scalar plural (semicolon-joined)
Tags: `ALBUMARTIST="Art53 & Art54"`, `ALBUMARTISTS="Art53; Art54"` (single field)

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art53 & Art54 | (n/a) | Art53 & Art54 |
| New OFF | Art53 & Art54 | Art53 & Art54 | Art53 & Art54 |
| New ON | Art53 | Art53 & Art54 | Art53, Art54 |

splitTag splits the scalar plural by `;`. Display preserved.

### Fixture 24: Semicolon-separated singular + multi-value plural (darrell equivalence case)
Tags: `ALBUMARTIST="Art55; Art56"` (scalar), `ALBUMARTISTS=Art55 | Art56` (two fields)

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art55 | (n/a) | Art55, Art56 |
| New OFF | Art55 | Art55; Art56 | Art55, Art56 |
| New ON | Art55 | Art55; Art56 | Art55, Art56 |

Key observation: contributors identical in all three (splitTag splits the semicolon either way). display_artist preserves full "Art55; Art56" string.

Compare with fixture 12 (two ALBUMARTIST fields, same artists):
- Fixture 12 display_artist = "Art23" (first element of arrayref)
- Fixture 24 display_artist = "Art55; Art56" (full scalar string)

**This confirms darrell's point: semicolon-separated and multi-field are NOT equivalent for display_artist.**

### Fixture 25: Multi-field singular + plural with DIFFERENT content (data loss scenario)
Tags: `ALBUMARTIST=Art57 | Art58` (two fields), `ALBUMARTISTS=Art57 | Art59` (two fields, Art58 replaced by Art59)

| | primary | display_artist | contributors |
|---|---|---|---|
| Old | Art57 | (n/a) | Art57, Art58 |
| New OFF | Art57 | Art57 | Art57, Art58 |
| New ON | Art57 | Art57 | Art57, Art59 |

**Pref ON: Art58 gone, replaced by Art59.** This is the data loss scenario mikes/darrell warned about. The user had Art57 and Art58 as ALBUMARTIST fields. With pref ON, the plural tags (Art57, Art59) override, so Art58 disappears and Art59 appears.

## Summary of darrell's equivalence concern

| Tagging method | display_artist (new code) | contributors (pref ON) |
|---|---|---|
| `ALBUMARTIST="Art55; Art56"` (semicolon scalar) | `Art55; Art56` | Art55, Art56 |
| `ALBUMARTIST=Art23 | Art24` (two fields) | `Art23` | Art23, Art24 |

Same contributors, different display. Darrell says these should be equivalent. He's right that the display behavior differs.

## Open questions

1. Should multi-field ALBUMARTIST join elements for display (matching the semicolon scalar behavior)?
2. Should the splitList pref be hidden/disabled when usePluralArtistTags is ON?
3. Is the fixture 25 data loss (Art58 -> Art59) acceptable, or should multi-valued singular tags cause plural to be ignored?
