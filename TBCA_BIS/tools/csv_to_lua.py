#!/usr/bin/env python3
"""
Convert a values-only BiS CSV into a Lua data file.

Usage:
  python tools/csv_to_lua.py "Data/BiS V4 Values only - Sheet1.csv" "Data/BiSData.lua"
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


# Mapping can be set by header names or 1-based column indices.
# Update this map if your CSV column order changes.
# Prefer header names for the newer CSV, fall back to positional indices for older exports.
COLUMN_MAP = {
    "item_id": ["ItemID", 1],
    "spec": ["Spec", 12],
    # Use GamePhase for display/filtering (current phase list).
    "phase": ["GamePhase", "Phase", 13],
    "slot": ["Slot", 14],
    "rank": ["Rank", 15],
    "fepv": ["FEPV", 16],
    "fhcepv": ["FHCEVP", 17],
    "pmax": ["P1max", "P2max", "P3max", "P4max", "P5max", 18, 19, 20, 21, 22],
    "pmaxhc": ["P1maxHC", "P2maxHC", "P3maxHC", "P4maxHC", "P5maxHC", 23, 24, 25, 26, 27],
}


def parse_number(value: str):
    if value is None:
        return None
    value = value.strip()
    if value == "" or value.lower() in {"na", "n/a", "nan"}:
        return None
    try:
        num = float(value)
    except ValueError:
        return None
    if num.is_integer():
        return int(num)
    return num


def resolve_index(header: list[str], keys: list):
    # Prefer header names if present
    if header:
        for k in keys:
            if isinstance(k, str) and k in header:
                return header.index(k)
    # Fallback to positional indices
    for k in keys:
        if isinstance(k, int):
            return k - 1
    return None


def resolve_indices(header: list[str], keys: list):
    indices = []
    seen = set()
    # Prefer header names if present
    if header:
        for k in keys:
            if isinstance(k, str) and k in header:
                idx = header.index(k)
                if idx not in seen:
                    indices.append(idx)
                    seen.add(idx)
        if indices:
            return indices
    # Fallback to positional indices
    for k in keys:
        if isinstance(k, int):
            idx = k - 1
            if idx not in seen:
                indices.append(idx)
                seen.add(idx)
    return indices


def is_header(row: list[str]) -> bool:
    if not row:
        return False
    return "ItemID" in row or (row[0] and not row[0].isdigit())


def format_lua_value(val):
    if val is None:
        return "0"
    if isinstance(val, int):
        return str(val)
    if isinstance(val, float):
        return f"{val:.6f}".rstrip("0").rstrip(".")
    return f"\"{str(val).replace('\\\\', '\\\\\\\\').replace('\"', '\\\\\"')}\""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("lua_path", type=Path)
    args = parser.parse_args()

    if not args.csv_path.exists():
        raise SystemExit(f"CSV not found: {args.csv_path}")

    with args.csv_path.open(newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        first_row = next(reader, None)
        if first_row is None:
            raise SystemExit("CSV is empty.")

        if is_header(first_row):
            header = first_row
        else:
            header = []
            reader = csv.reader(args.csv_path.open(newline="", encoding="utf-8"))

        idx_item = resolve_index(header, COLUMN_MAP["item_id"])
        idx_spec = resolve_index(header, COLUMN_MAP["spec"])
        idx_phase = resolve_index(header, COLUMN_MAP["phase"])
        idx_slot = resolve_index(header, COLUMN_MAP["slot"])
        idx_rank = resolve_index(header, COLUMN_MAP["rank"])
        idx_fepv = resolve_index(header, COLUMN_MAP["fepv"])
        idx_fhcepv = resolve_index(header, COLUMN_MAP["fhcepv"])
        idx_pmax = resolve_indices(header, COLUMN_MAP["pmax"])
        idx_pmaxhc = resolve_indices(header, COLUMN_MAP["pmaxhc"])

        if idx_item is None or idx_spec is None or idx_phase is None or idx_slot is None or idx_rank is None:
            raise SystemExit("Required columns not found. Update COLUMN_MAP for your CSV.")

        items: dict[int, list[dict]] = {}

        for row in reader:
            if not row or len(row) <= idx_item:
                continue

            item_id = parse_number(row[idx_item])
            if not isinstance(item_id, int):
                continue

            spec = row[idx_spec].strip() if idx_spec is not None and idx_spec < len(row) else ""
            slot = row[idx_slot].strip() if idx_slot is not None and idx_slot < len(row) else ""

            phase = parse_number(row[idx_phase]) if idx_phase is not None and idx_phase < len(row) else None
            rank = parse_number(row[idx_rank]) if idx_rank is not None and idx_rank < len(row) else None
            fepv = parse_number(row[idx_fepv]) if idx_fepv is not None and idx_fepv < len(row) else None
            fhcepv = parse_number(row[idx_fhcepv]) if idx_fhcepv is not None and idx_fhcepv < len(row) else None

            pmax = []
            for i in idx_pmax:
                pmax.append(parse_number(row[i]) if i < len(row) else None)
            pmaxhc = []
            for i in idx_pmaxhc:
                pmaxhc.append(parse_number(row[i]) if i < len(row) else None)

            row_obj = {
                "s": spec,
                "p": int(phase) if isinstance(phase, (int, float)) else 0,
                "sl": slot,
                "r": int(rank) if isinstance(rank, (int, float)) else 0,
                "e": fepv if fepv is not None else 0,
                "h": fhcepv if fhcepv is not None else 0,
                "m": pmax,
                "mh": pmaxhc,
            }

            items.setdefault(item_id, []).append(row_obj)

    args.lua_path.parent.mkdir(parents=True, exist_ok=True)
    with args.lua_path.open("w", encoding="utf-8", newline="\n") as out:
        out.write("-- Auto-generated from CSV. Do not edit by hand.\n")
        out.write("ExoLink_BiSData = {\n")
        out.write("  byItem = {\n")
        for item_id in sorted(items.keys()):
            out.write(f"    [{item_id}] = {{\n")
            for row in items[item_id]:
                parts = []
                parts.append(f"s={format_lua_value(row['s'])}")
                parts.append(f"p={format_lua_value(row['p'])}")
                parts.append(f"sl={format_lua_value(row['sl'])}")
                parts.append(f"r={format_lua_value(row['r'])}")
                parts.append(f"e={format_lua_value(row['e'])}")
                parts.append(f"h={format_lua_value(row['h'])}")

                m = ", ".join(format_lua_value(v) for v in row["m"])
                mh = ", ".join(format_lua_value(v) for v in row["mh"])
                parts.append(f"m={{ {m} }}")
                parts.append(f"mh={{ {mh} }}")

                out.write("      {" + ", ".join(parts) + "},\n")
            out.write("    },\n")
        out.write("  },\n")
        out.write("}\n")


if __name__ == "__main__":
    main()
