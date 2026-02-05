#!/usr/bin/env python3
"""
Generate TBCA_BIS_AtlasLoot_Classic/data.lua from BiS_w_Phase.csv.

Usage:
  python TBCA_BIS_AtlasLoot_Classic/tools/csv_to_atlasloot.py "TBCA_BIS/BiS_w_Phase.csv" "TBCA_BIS_AtlasLoot_Classic/data.lua"
"""

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path


SPEC_MAP = {
    "Aff": ("Warlock", "Affliction"),
    "Dest": ("Warlock", "Destruction"),
    "Arc": ("Mage", "Arcane"),
    "Fire": ("Mage", "Fire"),
    "BM": ("Hunter", "BM"),
    "SV": ("Hunter", "SV"),
    "Bear": ("Druid", "Bear"),
    "Cat": ("Druid", "Cat"),
    "Owl": ("Druid", "Balance"),
    "Tree": ("Druid", "Restoration"),
    "Resto": ("Druid", "Restoration"),
    "Ele": ("Shaman", "Elemental"),
    "Enh": ("Shaman", "Enhancement"),
    "Shad": ("Priest", "Shadow"),
    "Holy": ("Priest", "Holy"),
    "Rog": ("Rogue", "DPS"),
    "Arms": ("Warrior", "Arms"),
    "Fury": ("Warrior", "Fury"),
    "Prot": ("Warrior", "Prot"),
    "Ret": ("Paladin", "Ret"),
    "Heal": ("Paladin", "Heal"),
    "Tank": ("Paladin", "Tank"),
}

SLOT_ORDER = [
    "Head",
    "Neck",
    "Shoulders",
    "Back",
    "Chest",
    "Wrist",
    "Hands",
    "Waist",
    "Legs",
    "Feet",
    "Ring",
    "Trinket",
    "Main Hand",
    "Off Hand",
    "One Hand",
    "Two Hand",
    "Ranged",
]

SLOT_AL_KEY = {
    "Head": "Head",
    "Neck": "Neck",
    "Shoulders": "Shoulders",
    "Back": "Back",
    "Chest": "Chest",
    "Wrist": "Wrist",
    "Hands": "Hands",
    "Waist": "Waist",
    "Legs": "Legs",
    "Feet": "Feet",
    "Ring": "Ring",
    "Trinket": "Trinket",
    "Main Hand": "Main Hand",
    "Off Hand": "Off Hand",
    "One Hand": "One Hand",
    "Two Hand": "Two Hand",
    "Ranged": "Ranged",
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("lua_path", type=Path)
    args = parser.parse_args()

    if not args.csv_path.exists():
        raise SystemExit(f"CSV not found: {args.csv_path}")

    # data[class_spec][slot][phase] = list of (rank, itemid)
    data = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))

    with args.csv_path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                item_id = int(row["ItemID"])
                phase = int(row["GamePhase"])
                rank = int(row["Rank"])
            except (KeyError, ValueError):
                continue

            spec_code = row.get("Spec", "").strip()
            slot = row.get("Slot", "").strip()
            if slot not in SLOT_AL_KEY:
                continue

            spec_info = SPEC_MAP.get(spec_code)
            if not spec_info:
                continue

            cls, spec = spec_info
            key = f"{cls}{spec}".replace(" ", "")

            data[key][slot][phase].append((rank, item_id))

    args.lua_path.parent.mkdir(parents=True, exist_ok=True)
    with args.lua_path.open("w", encoding="utf-8", newline="\n") as out:
        out.write("-----------------------------------------------------------------------\n")
        out.write("-- Auto-generated. Do not edit by hand.\n")
        out.write("-----------------------------------------------------------------------\n\n")
        out.write("local _G = getfenv(0)\n")
        out.write("local select = _G.select\n")
        out.write("local string = _G.string\n")
        out.write("local format = string.format\n\n")
        out.write("local addonname = ...\n")
        out.write("local AtlasLoot = _G.AtlasLoot\n")
        out.write("local data = AtlasLoot.ItemDB:Add(addonname, 1)\n\n")
        out.write("local AL = AtlasLoot.Locales\n")
        out.write("local ALIL = AtlasLoot.IngameLocales\n\n")
        out.write("local GetForVersion = AtlasLoot.ReturnForGameVersion\n\n")
        out.write("local P1_DIFF = data:AddDifficulty(\"Phase 1\", \"p1\", 1, nil, true)\n")
        out.write("local P2_DIFF = data:AddDifficulty(\"Phase 2\", \"p2\", 2, nil, true)\n")
        out.write("local P3_DIFF = data:AddDifficulty(\"Phase 3\", \"p3\", 3, nil, true)\n")
        out.write("local P4_DIFF = data:AddDifficulty(\"Phase 4\", \"p4\", 4, nil, true)\n")
        out.write("local P5_DIFF = data:AddDifficulty(\"Phase 5\", \"p5\", 5, nil, true)\n\n")
        out.write("local NORMAL_ITTYPE = data:AddItemTableType(\"Item\", \"Item\")\n")
        out.write("local SET_ITTYPE = data:AddItemTableType(\"Set\", \"Item\")\n\n")
        out.write("local QUEST_EXTRA_ITTYPE = data:AddExtraItemTableType(\"Quest\")\n")
        out.write("local PRICE_EXTRA_ITTYPE = data:AddExtraItemTableType(\"Price\")\n")
        out.write("local SET_EXTRA_ITTYPE = data:AddExtraItemTableType(\"Set\")\n\n")
        out.write("local VENDOR_CONTENT = data:AddContentType(AL[\"Vendor\"], ATLASLOOT_DUNGEON_COLOR)\n")
        out.write("local SET_CONTENT = data:AddContentType(AL[\"Sets\"], ATLASLOOT_PVP_COLOR)\n")
        out.write("local COLLECTIONS_CONTENT = data:AddContentType(AL[\"Collections\"], ATLASLOOT_COLLECTIONS_COLOR)\n")
        out.write("local WORLD_EVENT_CONTENT = data:AddContentType(AL[\"World Events\"], ATLASLOOT_SEASONALEVENTS_COLOR)\n\n")

        for class_spec in sorted(data.keys()):
            cls = None
            spec = None
            for _, (c, s) in SPEC_MAP.items():
                if (c + s).replace(" ", "") == class_spec:
                    cls = c
                    spec = s
                    break
            if not cls or not spec:
                cls = class_spec
                spec = ""
            display_name = f"{cls} {spec} BiS".strip()

            out.write(f"data[\"{class_spec}\"] = {{\n")
            out.write(f"\tname = \"{display_name}\",\n")
            out.write("\tContentType = SET_CONTENT,\n")
            out.write("\titems = {\n")

            for slot in SLOT_ORDER:
                if slot not in data[class_spec]:
                    continue
                out.write(f"\t\t{{ -- {slot}\n")
                al_key = SLOT_AL_KEY.get(slot, slot)
                out.write(f"\t\t\tname = AL[\"{al_key}\"],\n")

                for phase, diff_name in [(1, "P1_DIFF"), (2, "P2_DIFF"), (3, "P3_DIFF"), (4, "P4_DIFF"), (5, "P5_DIFF")]:
                    items = data[class_spec][slot].get(phase, [])
                    if not items:
                        continue
                    items.sort(key=lambda x: x[0])
                    out.write(f"\t\t\t[{diff_name}] = {{\n")
                    idx = 1
                    for _, item_id in items:
                        out.write(f"\t\t\t\t{{ {idx}, {item_id} }},\n")
                        idx += 1
                    out.write("\t\t\t},\n")

                out.write("\t\t},\n")

            out.write("\t},\n")
            out.write("}\n\n")


if __name__ == "__main__":
    main()
