#!/usr/bin/env python3
"""Tag the Opus fixture set for LMS issue #1555 verification.

Two name sets:
  --names=abstract  (default) unique numbered names: Art1, Art2, ...
  --names=realistic          real-world artist names for screenshots

Both produce identical tag *structures*; only the name strings differ.
"""
import sys
from mutagen.oggopus import OggOpus

base = sys.argv[1]
name_set = "abstract"
for arg in sys.argv[2:]:
    if arg.startswith("--names="):
        name_set = arg.split("=", 1)[1]

# ── MBIDs ──────────────────────────────────────────────────────────────
# Valid UUID format required; LMS's sanitizeTagValues rejects non-UUIDs.
# Numbered to match the abstract Art-N scheme for traceability.
MB = {
    1:  "10000001-0001-0001-0001-000000000001",
    2:  "10000002-0002-0002-0002-000000000002",
    3:  "10000003-0003-0003-0003-000000000003",
    4:  "10000004-0004-0004-0004-000000000004",
    5:  "10000005-0005-0005-0005-000000000005",
    6:  "10000006-0006-0006-0006-000000000006",
    7:  "10000007-0007-0007-0007-000000000007",
    8:  "10000008-0008-0008-0008-000000000008",
    9:  "10000009-0009-0009-0009-000000000009",
    10: "10000010-0010-0010-0010-000000000010",
    11: "10000011-0011-0011-0011-000000000011",
    12: "10000012-0012-0012-0012-000000000012",
    13: "10000013-0013-0013-0013-000000000013",
    14: "10000014-0014-0014-0014-000000000014",
    15: "10000015-0015-0015-0015-000000000015",
    16: "10000016-0016-0016-0016-000000000016",
    17: "10000017-0017-0017-0017-000000000017",
    18: "10000018-0018-0018-0018-000000000018",
    19: "10000019-0019-0019-0019-000000000019",
    20: "10000020-0020-0020-0020-000000000020",
    21: "10000021-0021-0021-0021-000000000021",
    22: "10000022-0022-0022-0022-000000000022",
    23: "10000023-0023-0023-0023-000000000023",
    24: "10000024-0024-0024-0024-000000000024",
    25: "10000025-0025-0025-0025-000000000025",
    26: "10000026-0026-0026-0026-000000000026",
    27: "10000027-0027-0027-0027-000000000027",
    28: "10000028-0028-0028-0028-000000000028",
    29: "10000029-0029-0029-0029-000000000029",
    30: "10000030-0030-0030-0030-000000000030",
    31: "10000031-0031-0031-0031-000000000031",
    32: "10000032-0032-0032-0032-000000000032",
    33: "10000033-0033-0033-0033-000000000033",
    34: "10000034-0034-0034-0034-000000000034",
    35: "10000035-0035-0035-0035-000000000035",
    36: "10000036-0036-0036-0036-000000000036",
    37: "10000037-0037-0037-0037-000000000037",
    38: "10000038-0038-0038-0038-000000000038",
    39: "10000039-0039-0039-0039-000000000039",
    40: "10000040-0040-0040-0040-000000000040",
    41: "10000041-0041-0041-0041-000000000041",
    42: "10000042-0042-0042-0042-000000000042",
    43: "10000043-0043-0043-0043-000000000043",
    44: "10000044-0044-0044-0044-000000000044",
    45: "10000045-0045-0045-0045-000000000045",
    46: "10000046-0046-0046-0046-000000000046",
    47: "10000047-0047-0047-0047-000000000047",
    48: "10000048-0048-0048-0048-000000000048",
    49: "10000049-0049-0049-0049-000000000049",
    50: "10000050-0050-0050-0050-000000000050",
    51: "10000051-0051-0051-0051-000000000051",
    52: "10000052-0052-0052-0052-000000000052",
    "drop": "44444444-4444-4444-4444-444444444444",  # placeholder for empty-slot
}

# ── Name sets ──────────────────────────────────────────────────────────
# Abstract: Art1..Art30, unique per fixture. No artist name appears twice.
# Realistic: recognizable real-world names matching the same patterns.

if name_set == "abstract":
    N = {i: f"Art{i}" for i in range(1, 60)}
    N["va"] = "Various Artists"
elif name_set == "realistic":
    N = {
        # Fixture 01: plural + aligned MBIDs
        1: "Armin van Buuren", 2: "KI/KI",
        # Fixture 02: plural without MBIDs
        3: "Hall", 4: "Oates",
        # Fixture 03: plural + 3 MBIDs
        5: "Crosby", 6: "Stills", 7: "Nash",
        # Fixture 04: singular only
        8: "Adele",
        # Fixture 05: joined singular, semicolon split
        9: "Lennon", 10: "McCartney",
        # Fixture 06: compilation
        11: "Beyonce", 12: "Jay-Z",
        # Fixture 07: ft. track-artist
        13: "Dr. Dre", 14: "Snoop Dogg",
        # Fixture 08: empty name slot
        15: "Jack White", 16: "Meg White",
        # Fixture 09: plural present, singular missing
        17: "Robert Plant", 18: "Jimmy Page",
        # Fixture 10: scalar plural
        19: "Angus Young", 20: "Malcolm Young",
        # Fixture 11: length mismatch
        21: "John Lennon", 22: "Yoko Ono",
        # Fixture 12: multi-value both identical
        23: "Paul Simon", 24: "Art Garfunkel",
        # Fixture 13: SongKong-style
        25: "David Gilmour", 26: "Roger Waters",
        # Fixture 14: multi-value singular only (group + member)
        27: "Bill Evans",
        # Fixture 15: multi-value singular, no plural
        29: "Herbie Hancock", 30: "Wayne Shorter",
        # Fixture 16: multi-value singular, fewer plural
        31: "Miles Davis",
        "va": "Various Artists",
    }
    # Sort names as MusicBrainz/Picard writes them
    S = {
        1: "Buuren, Armin van", 2: "KI/KI",
        3: "Hall, Daryl", 4: "Oates, John",
        5: "Crosby, David", 6: "Stills, Stephen", 7: "Nash, Graham",
        8: "Adele",
        9: "Lennon, John", 10: "McCartney, Paul",
        11: "Beyonce", 12: "JAY-Z",
        13: "Dre, Dr.", 14: "Snoop Dogg",
        15: "White, Jack", 16: "White, Meg",
        17: "Plant, Robert", 18: "Page, Jimmy",
        19: "Young, Angus", 20: "Young, Malcolm",
        21: "Lennon, John", 22: "Ono, Yoko",
        23: "Simon, Paul", 24: "Garfunkel, Art",
        25: "Gilmour, David", 26: "Waters, Roger",
        27: "Evans, Bill",
        29: "Hancock, Herbie", 30: "Shorter, Wayne",
        31: "Davis, Miles",
        33: "Vegas, Dimitri & Like Mike",
    }
    N[33] = "Dimitri Vegas & Like Mike"
    N[34] = "Axwell Λ Ingrosso"
    N[35] = "Dimitri Vegas"
    N[36] = "Like Mike"
    S[34] = "Axwell & Ingrosso"
    S[35] = "Vegas, Dimitri"
    S[36] = "Like Mike"
    # Fixture 19-22: Track artist display scenarios (mikes' 4 scenarios)
    # Each has album artists (A, B) + additional track artists (C, D)
    N[37] = "Chick Corea"
    N[38] = "Gary Burton"
    N[39] = "Dave Holland"
    N[40] = "Roy Haynes"
    S[37] = "Corea, Chick"
    S[38] = "Burton, Gary"
    S[39] = "Holland, Dave"
    S[40] = "Haynes, Roy"
    N[41] = "Pat Metheny"
    N[42] = "Charlie Haden"
    N[43] = "Jack DeJohnette"
    N[44] = "Billy Higgins"
    S[41] = "Metheny, Pat"
    S[42] = "Haden, Charlie"
    S[43] = "DeJohnette, Jack"
    S[44] = "Higgins, Billy"
    N[45] = "Sonny Rollins"
    N[46] = "Clifford Brown"
    N[47] = "Max Roach"
    N[48] = "Richie Powell"
    S[45] = "Rollins, Sonny"
    S[46] = "Brown, Clifford"
    S[47] = "Roach, Max"
    S[48] = "Powell, Richie"
    N[49] = "Oscar Peterson"
    N[50] = "Joe Pass"
    N[51] = "Ray Brown"
    N[52] = "Martin Drew"
    S[49] = "Peterson, Oscar"
    S[50] = "Pass, Joe"
    S[51] = "Brown, Ray"
    S[52] = "Drew, Martin"
    # Real MusicBrainz artist IDs
    MB[1]  = "477b8c0c-c5fc-4ad2-b5b2-191f0bf2a9df"  # Armin van Buuren
    MB[2]  = "eaf2a4cb-75eb-4e9c-989e-13be6b96a76a"  # KI/KI
    MB[3]  = "31a4c5ca-1899-4a44-a4b1-31e1921ddf17"  # Daryl Hall
    MB[4]  = "a064f504-2700-4815-8c29-6b9c5b38caab"  # John Oates
    MB[5]  = "e90f9815-221d-4e10-8675-e75c07988113"  # David Crosby
    MB[6]  = "5642774a-72c0-4099-8da4-7c1ab36378a8"  # Stephen Stills
    MB[7]  = "2ed8ecda-5bb9-4d9f-8c99-323e6ce46c2a"  # Graham Nash
    MB[11] = "859d0860-d480-4efd-970c-c05d5f1776b8"  # Beyonce
    MB[12] = "f82bcf78-5b69-4622-a5ef-73800768d9ac"  # Jay-Z
    MB[13] = "5f6ab597-f57a-40da-be9e-adad48708203"  # Dr. Dre
    MB[14] = "f90e8b26-9e52-4669-a5c9-e28529c47894"  # Snoop Dogg
    MB[15] = "3ae2fb37-8a23-429d-9920-bac811c4fc22"  # Jack White
    MB[16] = "e49683e5-61e8-4f82-9069-e5d622bbb342"  # Meg White
    MB[17] = "bd53f9a7-8be9-46b0-bf7d-1deea3cb57bc"  # Robert Plant
    MB[18] = "519774a4-3b18-4042-b8c0-927845a616c9"  # Jimmy Page
    MB[19] = "a0a54c69-b0d2-4d2a-bcf8-994b8846b0d8"  # Angus Young
    MB[20] = "ea719716-da05-46f8-bbd5-cc5803db3d0e"  # Malcolm Young
    MB[21] = "4d5447d7-c61c-4120-ba1b-d7f471d385b9"  # John Lennon
    MB[22] = "b0b33754-a664-43b7-ba00-be0dc4ec2396"  # Yoko Ono
    MB[23] = "05517043-ff78-4988-9c22-88c68588ebb9"  # Paul Simon
    MB[24] = "fc0a5289-4b77-4246-9c8d-857c8b617f5d"  # Art Garfunkel
    MB[25] = "1dce970e-34bc-48b2-ab51-48d87544a4c2"  # David Gilmour
    MB[26] = "0f50beab-d77d-4f0f-ac26-0b87d3e9b11b"  # Roger Waters
    MB[29] = "27613b78-1b9d-4ec3-9db5-fa0743465fdd"  # Herbie Hancock
    MB[30] = "2379937f-6e0d-46a2-b8ff-633fafd72002"  # Wayne Shorter
    MB[37] = "4643ee27-6e9e-4060-955e-4bfa0ae54023"  # Chick Corea
    MB[38] = "bcff4d38-5e03-4a8e-a3d0-1ba4f39efff1"  # Gary Burton
    MB[39] = "50da4cbe-19b7-4104-a5e7-fa5e47e0e94c"  # Dave Holland
    MB[40] = "59226f1d-da25-4a92-b0e3-f0e7f4ced702"  # Roy Haynes
    MB[41] = "e3e27f27-67e0-43fa-97ae-e36bfe7a3952"  # Pat Metheny
    MB[42] = "55bf2fd1-f0cd-47ce-a1c2-cc75be8b0a48"  # Charlie Haden
    MB[43] = "8efdbc0f-1e24-4cd0-b8b5-3e8d78e05582"  # Jack DeJohnette
    MB[44] = "b3ff2e64-9e63-4c0b-9c5c-bf3a0a1e8999"  # Billy Higgins
    MB[45] = "4d5ec626-2251-4bb1-b62a-f24b471e43c2"  # Sonny Rollins
    MB[46] = "9e487ced-dc83-4227-9c3c-ad25e2329d69"  # Clifford Brown
    MB[47] = "ddf70e5d-e40a-4a75-8267-39e2c5a1cb70"  # Max Roach
    MB[48] = "73afd25a-6635-4e5b-adb0-e7ef03bc4923"  # Richie Powell
    MB[49] = "0e0ef06b-378c-4e74-83be-63c1b9b6f5b3"  # Oscar Peterson
    MB[50] = "adfd4a96-4728-4155-897b-44af4c2c0027"  # Joe Pass
    MB[51] = "d0b0530e-f59b-4dfe-8e40-3befc1db64f5"  # Ray Brown
    MB[52] = "b3e34fa8-a670-48a9-b62a-5b5cc8c6c6b8"  # Martin Drew
    # Fixture 23: scalar plural
    N[53] = "Bill Evans"
    N[54] = "Jim Hall"
    S[53] = "Evans, Bill"
    S[54] = "Hall, Jim"
    # Fixture 24: semicolon singular + multi-value plural
    N[55] = "Thelonious Monk"
    N[56] = "John Coltrane"
    S[55] = "Monk, Thelonious"
    S[56] = "Coltrane, John"
    # Fixture 25: multi-value singular + different plural
    N[57] = "Ella Fitzgerald"
    N[58] = "Louis Armstrong"
    N[59] = "Duke Ellington"
    S[57] = "Fitzgerald, Ella"
    S[58] = "Armstrong, Louis"
    S[59] = "Ellington, Duke"
else:
    sys.exit(f"Unknown name set: {name_set}")

# Sort names: only set in realistic mode, absent in abstract
S = locals().get('S', {})


# ── Helpers ────────────────────────────────────────────────────────────
def sort_for(*keys):
    """Build ALBUMARTISTSORT value from sort-name dict, if available."""
    vals = [S[k] for k in keys if k in S]
    return vals if vals else None

def tag(n, **kv):
    f = OggOpus(f"{base}/fixture_{n:02d}.opus")
    for k, v in kv.items():
        if v is None:
            continue
        f[k] = v if isinstance(v, list) else [v]
    f["TITLE"] = [f"Fixture {n:02d}"]
    f["ALBUM"] = [f"Fixture {n:02d}"]
    f.save()

def join2(a, b, sep=" & "):
    return f"{a}{sep}{b}"

def join3(a, b, c):
    return f"{a}, {b} & {c}"

def ensemble(name):
    """Group-name variant: 'Art27' -> 'Art27 Ensemble', 'Bill Evans' -> 'Bill Evans Trio'."""
    if name_set == "realistic":
        if name == "Bill Evans":
            return "Bill Evans Trio"
        if name == "Miles Davis":
            return "Miles Davis Quintet"
    return f"{name} Ensemble"


# ══════════════════════════════════════════════════════════════════════
# GROUP A: Display artist / swap logic
# These test darrell's display_artist prototype: capturing the combined
# artist string and linking to individual contributors.
# ══════════════════════════════════════════════════════════════════════

# 01. Scalar singular + plural -> swap fires, display preserved
tag(1,
    ALBUMARTIST=join2(N[1], N[2]),
    ALBUMARTISTS=[N[1], N[2]],
    ALBUMARTISTSORT=sort_for(1, 2),
    MUSICBRAINZ_ALBUMARTISTID=[MB[1], MB[2]])

# 02. Same as 01 but without MBIDs
tag(2,
    ALBUMARTIST=join2(N[3], N[4]),
    ALBUMARTISTS=[N[3], N[4]],
    ALBUMARTISTSORT=sort_for(3, 4))

# 03. Three contributors with plural
tag(3,
    ALBUMARTIST=join3(N[5], N[6], N[7]),
    ALBUMARTISTS=[N[5], N[6], N[7]],
    ALBUMARTISTSORT=sort_for(5, 6, 7),
    MUSICBRAINZ_ALBUMARTISTID=[MB[5], MB[6], MB[7]])

# 04. Singular only, no plural -> no swap, regression guard
tag(4,
    ALBUMARTIST=N[8],
    ALBUMARTISTSORT=sort_for(8))

# 05. Joined singular via semicolon -> splitList path, no plural
tag(5,
    ALBUMARTIST=join2(N[9], N[10], sep="; "),
    ALBUMARTISTSORT=sort_for(9, 10))

# 12. Multi-value singular AND plural, both identical
#     Swap fires but ALBUMARTISTS becomes arrayref, not a display string.
tag(12,
    ALBUMARTIST=[N[23], N[24]],
    ALBUMARTISTS=[N[23], N[24]],
    ALBUMARTISTSORT=sort_for(23, 24),
    MUSICBRAINZ_ALBUMARTISTID=[MB[23], MB[24]])

# 13. SongKong-style: singular has display + individuals, plural has individuals
#     Best-case scenario for the swap: display preserved, individuals linked.
tag(13,
    ALBUMARTIST=[join2(N[25], N[26]), N[25], N[26]],
    ALBUMARTISTS=[N[25], N[26]],
    ALBUMARTISTSORT=sort_for(25, 26),
    MUSICBRAINZ_ALBUMARTISTID=[MB[25], MB[26]])

# 14. Multi-value singular only, no plural -> no swap
#     Group name + member in singular. Existing path handles this.
tag(14,
    ALBUMARTIST=[ensemble(N[27]), N[27]],
    ALBUMARTISTSORT=sort_for(27))

# 16. Multi-value singular, fewer values in plural -> swap fires
#     Group name becomes display, member becomes contributor.
tag(16,
    ALBUMARTIST=[ensemble(N[31]), N[31]],
    ALBUMARTISTS=[N[31]],
    ALBUMARTISTSORT=sort_for(31))

# 06. Compilation (VA albumartist, track-level plural artists)
tag(6,
    COMPILATION="1",
    ALBUMARTIST=N["va"],
    ARTIST=join2(N[11], N[12]),
    ARTISTS=[N[11], N[12]],
    ARTISTSORT=sort_for(11, 12),
    MUSICBRAINZ_ARTISTID=[MB[11], MB[12]])

# 07. ft. track-artist case (album artist singular, track artist plural)
tag(7,
    ALBUMARTIST=N[13],
    ALBUMARTISTSORT=sort_for(13),
    MUSICBRAINZ_ALBUMARTISTID=[MB[13]],
    ARTIST=f"{N[13]} ft. {N[14]}",
    ARTISTS=[N[13], N[14]],
    ARTISTSORT=sort_for(13, 14),
    MUSICBRAINZ_ARTISTID=[MB[13], MB[14]])

# ══════════════════════════════════════════════════════════════════════
# GROUP B: MBID handling and tagger edge cases
# These test MBID alignment, malformed tags, and missing fields.
# Not covered by darrell's display_artist prototype.
# ══════════════════════════════════════════════════════════════════════

# 08. Empty name slot in plural (tagger bug)
#     Expected: empty name + its MBID dropped, other slots preserved.
tag(8,
    ALBUMARTIST=f"{N[15]}, , {N[16]}",
    ALBUMARTISTS=[N[15], "", N[16]],
    ALBUMARTISTSORT=sort_for(15, 16),
    MUSICBRAINZ_ALBUMARTISTID=[MB[15], MB["drop"], MB[16]])

# 09. Plural present, singular missing
#     Edge case: ALBUMARTISTS exists but ALBUMARTIST is absent.
tag(9,
    ALBUMARTISTS=[N[17], N[18]],
    ALBUMARTISTSORT=sort_for(17, 18),
    MUSICBRAINZ_ALBUMARTISTID=[MB[17], MB[18]])

# 10. Scalar plural (buggy tagger wrote plural as semicolon-joined string)
tag(10,
    ALBUMARTIST=join2(N[19], N[20]),
    ALBUMARTISTS=join2(N[19], N[20], sep="; "),
    ALBUMARTISTSORT=sort_for(19, 20))

# 11. Plural length != MBID length (guard from PR #1556)
tag(11,
    ALBUMARTIST=join2(N[21], N[22]),
    ALBUMARTISTS=[N[21], N[22]],
    ALBUMARTISTSORT=sort_for(21, 22),
    MUSICBRAINZ_ALBUMARTISTID=[MB[21]])

# 15. Multi-value singular (display + individuals), no plural, with MBIDs
#     Without plural the swap can't fire. MBIDs need handling separately.
tag(15,
    ALBUMARTIST=[join2(N[29], N[30]), N[29], N[30]],
    ALBUMARTISTSORT=sort_for(29, 30),
    MUSICBRAINZ_ALBUMARTISTID=[MB[29], MB[30]])

# ══════════════════════════════════════════════════════════════════════
# GROUP C: Special cases
# ══════════════════════════════════════════════════════════════════════

# 17. Group with "&" in name but single MBID (Dimitri Vegas & Like Mike)
#     The name looks like two artists but is one group entity.
#     Tests that the scanner doesn't split a single-MBID group.
tag(17,
    ALBUMARTIST=N.get(33, "Dimitri Vegas & Like Mike"),
    ALBUMARTISTSORT=sort_for(33) if 33 in S else None,
    MUSICBRAINZ_ALBUMARTISTID=["c5931849-7c9d-465e-b717-29e2af974c6b"])

# 18. Group with unicode in name but single MBID (Axwell Λ Ingrosso)
#     Lambda character in name, "&" in sort name. Tests unicode handling
#     and that a single-MBID group isn't split by special characters.
tag(18,
    ALBUMARTIST=N.get(34, "Axwell Λ Ingrosso"),
    ALBUMARTISTSORT=sort_for(34) if 34 in S else None,
    MUSICBRAINZ_ALBUMARTISTID=["00323ee1-05b6-4cf6-98c4-94f0701645d3"])


# ══════════════════════════════════════════════════════════════════════
# GROUP D: Track artist display scenarios (mikes' 4 scenarios)
# These test how additional track artists (C, D) interact with album
# artists (A, B) under different ARTIST/ARTISTS tag combinations.
# Reproduces the scenarios from mikes' 2026-05-18 forum post.
# ══════════════════════════════════════════════════════════════════════

# 19. Scenario 1: ARTIST multi-value = ARTISTS multi-value (all individuals)
#     ALBUMARTIST="A & B", ALBUMARTISTS=[A,B]
#     ARTIST=[A,B,C,D], ARTISTS=[A,B,C,D]
#     Expected: C and D should appear as track artist links.
tag(19,
    ALBUMARTIST=join2(N[37], N[38]),
    ALBUMARTISTS=[N[37], N[38]],
    ALBUMARTISTSORT=sort_for(37, 38),
    MUSICBRAINZ_ALBUMARTISTID=[MB[37], MB[38]],
    ARTIST=[N[37], N[38], N[39], N[40]],
    ARTISTS=[N[37], N[38], N[39], N[40]],
    ARTISTSORT=sort_for(37, 38, 39, 40),
    MUSICBRAINZ_ARTISTID=[MB[37], MB[38], MB[39], MB[40]])

# 20. Scenario 2: ARTIST has display string + extras, ARTISTS has all individuals
#     ALBUMARTIST="A & B", ALBUMARTISTS=[A,B]
#     ARTIST=["A & B",C,D], ARTISTS=[A,B,C,D]
#     Expected: C and D should appear as track artist links.
tag(20,
    ALBUMARTIST=join2(N[41], N[42]),
    ALBUMARTISTS=[N[41], N[42]],
    ALBUMARTISTSORT=sort_for(41, 42),
    MUSICBRAINZ_ALBUMARTISTID=[MB[41], MB[42]],
    ARTIST=[join2(N[41], N[42]), N[43], N[44]],
    ARTISTS=[N[41], N[42], N[43], N[44]],
    ARTISTSORT=sort_for(41, 42, 43, 44),
    MUSICBRAINZ_ARTISTID=[MB[41], MB[42], MB[43], MB[44]])

# 21. Scenario 3: ARTIST has display string + extras, ARTISTS has fewer (only A,B)
#     ALBUMARTIST="A & B", ALBUMARTISTS=[A,B]
#     ARTIST=["A & B",C,D], ARTISTS=[A,B]
#     BUG: swap replaces ARTIST with ARTISTS, so C and D are lost.
tag(21,
    ALBUMARTIST=join2(N[45], N[46]),
    ALBUMARTISTS=[N[45], N[46]],
    ALBUMARTISTSORT=sort_for(45, 46),
    MUSICBRAINZ_ALBUMARTISTID=[MB[45], MB[46]],
    ARTIST=[join2(N[45], N[46]), N[47], N[48]],
    ARTISTS=[N[45], N[46]],
    ARTISTSORT=sort_for(45, 46),
    MUSICBRAINZ_ARTISTID=[MB[45], MB[46]])

# 22. Scenario 4: ARTIST multi-value, no ARTISTS tag
#     ALBUMARTIST="A & B", ALBUMARTISTS=[A,B]
#     ARTIST=[A,B,C,D], no ARTISTS
#     No swap fires for ARTIST. C and D should appear as track artist links.
tag(22,
    ALBUMARTIST=join2(N[49], N[50]),
    ALBUMARTISTS=[N[49], N[50]],
    ALBUMARTISTSORT=sort_for(49, 50),
    MUSICBRAINZ_ALBUMARTISTID=[MB[49], MB[50]],
    ARTIST=[N[49], N[50], N[51], N[52]],
    ARTISTSORT=sort_for(49, 50, 51, 52),
    MUSICBRAINZ_ARTISTID=[MB[49], MB[50], MB[51], MB[52]])


# 23. Scalar plural tags (semicolon-joined, not multi-value)
#     ALBUMARTIST="A & B", ALBUMARTISTS="A; B" (scalar, not array)
#     ARTIST="A & B", ARTISTS="A; B" (scalar, not array)
#     Tests that splitTag handles scalar plural tags from taggers that
#     write a single field with semicolons instead of separate entries.
N.setdefault(53, "Art53")
N.setdefault(54, "Art54")
S.setdefault(53, "Art53")
S.setdefault(54, "Art54")
MB[53] = "7bb195d0-2a1e-4cb3-8907-8580c7e2b3ad"
MB[54] = "56b6e048-0afe-4e24-8701-5765b7e9cb4a"
tag(23,
    ALBUMARTIST=join2(N[53], N[54]),
    ALBUMARTISTS=f"{N[53]}; {N[54]}",
    ALBUMARTISTSORT=f"{S[53]}; {S[54]}",
    MUSICBRAINZ_ALBUMARTISTID=[MB[53], MB[54]],
    ARTIST=join2(N[53], N[54]),
    ARTISTS=f"{N[53]}; {N[54]}",
    ARTISTSORT=f"{S[53]}; {S[54]}",
    MUSICBRAINZ_ARTISTID=[MB[53], MB[54]])

# 24. Semicolon-separated singular + multi-value plural (darrell equivalence case)
#     ALBUMARTIST="A; B" (scalar, semicolon-joined)
#     ALBUMARTISTS=[A, B] (arrayref, two separate fields)
#     Tests whether semicolon-joined singular and multi-value plural produce
#     the same result as two separate ALBUMARTIST fields (fixture 12).
N.setdefault(55, "Art55")
N.setdefault(56, "Art56")
S.setdefault(55, "Art55")
S.setdefault(56, "Art56")
MB[55] = "4d54b391-3218-47d5-ac78-d68e36e73e63"
MB[56] = "b625448e-bf4a-41c1-a6e4-d3a98afd0229"
tag(24,
    ALBUMARTIST=join2(N[55], N[56], sep="; "),
    ALBUMARTISTS=[N[55], N[56]],
    ALBUMARTISTSORT=sort_for(55, 56),
    MUSICBRAINZ_ALBUMARTISTID=[MB[55], MB[56]])

# 25. Two ALBUMARTIST fields + plural with different content (data loss concern)
#     ALBUMARTIST=[A, B] (two separate fields)
#     ALBUMARTISTS=[A, C] (plural differs from singular)
#     Tests the scenario mikes/darrell worry about: user manually set
#     ALBUMARTIST to [A, B] but tagger wrote ALBUMARTISTS=[A, C].
#     With pref ON, B disappears from contributors, replaced by C.
N.setdefault(57, "Art57")
N.setdefault(58, "Art58")
N.setdefault(59, "Art59")
S.setdefault(57, "Art57")
S.setdefault(58, "Art58")
S.setdefault(59, "Art59")
MB[57] = "b032abf8-1043-4fac-9428-a677bf81898e"
MB[58] = "19f80738-4f80-4f08-9ded-4deebc305808"
MB[59] = "01fba0b8-638f-4127-8e85-33e49be11d80"
tag(25,
    ALBUMARTIST=[N[57], N[58]],
    ALBUMARTISTS=[N[57], N[59]],
    ALBUMARTISTSORT=sort_for(57, 59),
    MUSICBRAINZ_ALBUMARTISTID=[MB[57], MB[59]])

FIXTURE_COUNT = 25
print(f"Tagged {FIXTURE_COUNT} fixtures under {base} (names={name_set})")
