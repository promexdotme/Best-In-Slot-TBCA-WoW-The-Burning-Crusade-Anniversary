# TBCA_BIS

TBCA_BIS adds BiS data to item tooltips using a precomputed EPV dataset. It supports Hit-Capped and non-Hit-Capped values, phase filtering (P1–P5), and percentage display relative to phase baselines.

## Features
- O(1) lookup by ItemID
- Phase-aware display (P1–P5)
- Hit-Capped vs non-Hit-Capped values
- Percent or phase/rank display
- Minimap button and settings window

## Folders
- `TBCA_BIS` (main tooltip addon)
- `TBCA_BIS_AtlasLoot_Classic` (AtlasLoot integration)

## Commands
- `/bis` toggle settings window
- `/bis on` show minimap button
- `/bis off` hide minimap button
- `/bisphase 1..5`
- `/bishitcap on|off`
- `/bispercent on|off`
- `/bisstatus`

## Data Pipeline
WoW cannot read CSV at runtime. The CSV is converted offline to a Lua table.

### Main addon
```bash
python "TBCA_BIS/tools/csv_to_lua.py" "TBCA_BIS/BiS_w_Phase.csv" "TBCA_BIS/Data/BiSData.lua"
```

### AtlasLoot module
```bash
python "TBCA_BIS_AtlasLoot_Classic/tools/csv_to_atlasloot.py" "TBCA_BIS/BiS_w_Phase.csv" "TBCA_BIS_AtlasLoot_Classic/data.lua"
```

## Notes
- Ensure folder names match `.toc` filenames.
- Remove older versions to avoid duplicate loading.
