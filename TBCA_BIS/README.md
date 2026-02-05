# FatExoLink_BIS

Tooltip extension for BiS data (TBC Classic Anniversary build), driven by a precomputed CSV export converted to a Lua table.

## Features
- O(1) lookup by `ItemID`
- Phase-aware display (filters to selected `maxPhase`)
- Hit-capped toggle
- Percentage toggle
- Minimap button + small config window
- Slash commands for fast changes

## Files
- `Data/BiSData.lua`: generated from CSV (do not edit by hand)
- `tools/csv_to_lua.py`: offline converter
- `BiS_w_Phase.csv`: source CSV (values-only)

## Build
```bash
python "TBCA_BIS/tools/csv_to_lua.py" "TBCA_BIS/BiS_w_Phase.csv" "TBCA_BIS/Data/BiSData.lua"
```

## Settings
- Config window: `/bis`
- Minimap button: `/bis on` (show), `/bis off` (hide)
- Max Phase: dropdown in the window or `/bisphase 1` to `/bisphase 5`
- HitCapped: checkbox or `/bishitcap` (`on|off`)
- Show Percent: checkbox or `/bispercent` (`on|off`)
- Status: `/bisstatus`

## Slash Commands
- `/bis` toggle config window
- `/bis on` show minimap button
- `/bis off` hide minimap button
- `/bisphase 1` to `/bisphase 5`
- `/bishitcap` or `/bishitcap on|off`
- `/bispercent` or `/bispercent on|off`
- `/bisstatus`

## Notes
- WoW cannot read CSV at runtime; the Lua data file must be generated offline.
- The displayed rows are filtered to `GamePhase == maxPhase`.
