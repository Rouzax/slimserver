#!/usr/bin/env python3
"""Retag fixtures 19-22 to test album rescan vs fresh scan.

Usage:
  1. Tag initial state:   python3 build_tags.py /path --names=realistic
  2. Full scan in LMS (wipe & rescan). Record DB state.
  3. Retag for rescan:    python3 retag_rescan_test.py
  4. Album rescan in LMS. Record DB state. Compare with step 2.
  5. Restore originals:   python3 retag_rescan_test.py --restore

Each fixture swaps one track artist (D) for a replacement, keeping
the tag structure identical. This isolates whether the rescan update
path correctly rebuilds contributor associations.

Replacements:
  19: Roy Haynes       -> Eddie Gomez
  20: Billy Higgins    -> Larry Grenadier
  21: Richie Powell    -> Harold Land
  22: Martin Drew      -> Niels-Henning Orsted Pedersen
"""
import os
import sys
from mutagen.oggopus import OggOpus

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.join(SCRIPT_DIR, "..", "core")
RESTORE = "--restore" in sys.argv

# Original D artists and their replacements
SWAPS = {
    19: {
        "old": "Roy Haynes",
        "new": "Eddie Gomez",
        "old_sort": "Haynes, Roy",
        "new_sort": "Gomez, Eddie",
        "old_mbid": "59226f1d-da25-4a92-b0e3-f0e7f4ced702",
        "new_mbid": "1b9a94a2-b52b-4073-84d8-db4c85691e0a",
    },
    20: {
        "old": "Billy Higgins",
        "new": "Larry Grenadier",
        "old_sort": "Higgins, Billy",
        "new_sort": "Grenadier, Larry",
        "old_mbid": "b3ff2e64-9e63-4c0b-9c5c-bf3a0a1e8999",
        "new_mbid": "6c072f73-e4de-4aaa-8b65-7c44e7e0a886",
    },
    21: {
        "old": "Richie Powell",
        "new": "Harold Land",
        "old_sort": "Powell, Richie",
        "new_sort": "Land, Harold",
        "old_mbid": "73afd25a-6635-4e5b-adb0-e7ef03bc4923",
        "new_mbid": "a87a5c68-1c58-4aba-9c05-9e4fc0ded05a",
    },
    22: {
        "old": "Martin Drew",
        "new": "Niels-Henning Orsted Pedersen",
        "old_sort": "Drew, Martin",
        "new_sort": "Pedersen, Niels-Henning Orsted",
        "old_mbid": "b3e34fa8-a670-48a9-b62a-5b5cc8c6c6b8",
        "new_mbid": "7f2d0b1a-3a4e-4f5c-8b6d-9e0f1a2b3c4d",
    },
}


def swap_in_list(tag_values, old, new):
    """Replace old with new in a tag value list."""
    return [new if v == old else v for v in tag_values]


def retag(fixture_num, swap):
    path = f"{BASE}/fixture_{fixture_num:02d}.opus"
    f = OggOpus(path)

    if RESTORE:
        src, dst = "new", "old"
    else:
        src, dst = "old", "new"

    from_name = swap[src]
    to_name = swap[dst]
    from_sort = swap[f"{src}_sort"]
    to_sort = swap[f"{dst}_sort"]
    from_mbid = swap[f"{src}_mbid"]
    to_mbid = swap[f"{dst}_mbid"]

    if "artist" in f:
        f["artist"] = swap_in_list(f["artist"], from_name, to_name)

    if "artists" in f:
        f["artists"] = swap_in_list(f["artists"], from_name, to_name)

    if "artistsort" in f:
        f["artistsort"] = swap_in_list(f["artistsort"], from_sort, to_sort)

    if "musicbrainz_artistid" in f:
        f["musicbrainz_artistid"] = swap_in_list(
            f["musicbrainz_artistid"], from_mbid, to_mbid
        )

    f.save()

    action = "Restored" if RESTORE else "Retagged"
    print(f"  {action} fixture {fixture_num}: {from_name} -> {to_name}")


print(f"{'Restoring' if RESTORE else 'Retagging'} fixtures 19-22 for rescan test...")
for num, swap in SWAPS.items():
    retag(num, swap)

print("Done. Now run album rescan in LMS and compare DB state.")
