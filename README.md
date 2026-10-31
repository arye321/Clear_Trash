# Clear Trash to Chest

A Factorio **1.1** mod. Open a chest and click **Move trash to chest** below its inventory to transfer items from your **character logistic trash slots**.

- Supports ordinary chests, logistic chests, infinity chests and linked chests, including modded entities of those types.
- Transfers as much as fits, respecting the chest's red inventory limit and slot filters. Overflow stays in the trash slots.
- Preserves item metadata, including blueprints, equipment, tags and partially used items.
- Only uses character logistic trash slots; the main inventory and vehicle trash slots are untouched.
- Works in existing saves and multiplayer. Each click uses that player's currently open chest and character.

## Installation

Keep this folder named `Clear_Trash` in Factorio's `mods` directory. Restart Factorio, enable **Clear Trash to Chest** in **Mods**, and load your save. No research or configuration is required by the mod; your character must have logistic trash slots available to use it.

Factorio exposes the native chest window through relative GUI anchors, so the button appears in an attached panel immediately below the chest window.

## Verification

`python tests/run.py --factorio "path/to/factorio.exe"` runs inventory integration checks in Factorio itself. Add `--save "path/to/a/1.1-save.zip"` to also check the real player GUI handlers. The runner uses `.test-runtime` as its isolated data directory and does not save changes to the supplied map.
