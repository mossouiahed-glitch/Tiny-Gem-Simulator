# Tiny Gem Simulator — Luau source repository

This repository is a **snapshot of the actual Roblox Studio place exported as `TinyGemSimulator.rbxl`**. It was extracted without changing the original experience. It is **not a new game template** and **not an automatically deployable Rojo project**; the 3D place, terrain, GUI instances, and prompt objects are stored in the original `.rbxl` project. The source code lives here for review and version control.

## Game and assignment

Tiny Gem Simulator includes three crystal types, a sell station, backpack upgrades, a paid Crystal Cave unlock, data persistence, a game pass, three developer products, UI effects and analytics funnels. The assignment prioritizes secure server validation, persistent data, and verified funnel events over decorative polish.

## Source layout

- `src/active/ServerScriptService`: DataController, DataService, PurchaseService, FunnelService, AnalyticsController, CrystalController, and CrystalService.
- `src/active/StarterGui`: backpack HUD, coin counter, upgrade UI, and shop UI LocalScripts.
- `src/active/StarterPlayer`: visual effects, sound and feedback.
- `src/active/Workspace`: sell station, upgrade station, cave gate, return portal scripts.
- `src/legacy_disabled/Workspace`: 11 old `CrystalPicku` scripts, confirmed **disabled** in the exported place after conversion to the shared `CrystalService` module. Do not enable them alongside CrystalController or crystals may be awarded twice.

`*.server.luau` denotes a regular Script, `*.client.luau` a LocalScript, and `*.module.luau` a ModuleScript. These suffixes organize the GitHub source; the actual hierarchy is in the `.rbxl` file.

## Main gameplay flow

1. The player joins. `DataController` calls `DataService.Load`, restores server-owned attributes, resets carried crystals, and spawns the character.
2. `CrystalController` starts `CrystalService`, registering six blue spawns, four purple spawns, and one 10% golden/90% purple rare spawn. All 11 obsolete per-crystal Scripts remain disabled.
3. Collecting a crystal adds to `CarriedCount` and `CarriedValue`, not directly to `Coins`. The server checks the character, distance, pickup availability, cave access, and capacity.
4. The sell station turns carried value into coins; an unexpired Double Coins boost doubles proceeds. UpgradeStation charges 100 or 350 coins for the next capacity level.
5. The cave gate requires Level 2 and 250 coins for the permanent unlock. The ReturnPortal sends the player back to Start.
6. The shop uses Roblox purchase prompts. The server's `PurchaseService` handles Game Pass ownership and a single `ProcessReceipt` callback. `DataService.ApplyReceipt` records developer-product receipt IDs with their reward using `UpdateAsync`.
7. `FunnelService` and `AnalyticsController` implement the named funnels. However, see `AUDIT.md` for remaining correctness and validation work.

## Monetization IDs (from the current scripts)

| Item | ID | Price (Robux) | Reward |
|---|---:|---:|---|
| Bigger Backpack pass | 2062003376 | 79 | Permanent +10 slots |
| Coin Pack | 3724904088 | 19 | 250 coins |
| Double Coins | 3724905418 | 29 | 2x sale income for 10 minutes |
| Sell Vouchers | 3724907700 | 15 | 3 instant sell vouchers |

## Persistence

`DataService` uses the data store `TinyGem_Development_v1`, with coins, backpack level, cave unlock, vouchers and boost-expiration timestamp. Carried crystals are deliberately reset on rejoin. Session-lock, saving and receipt-retry paths need final failure testing before release; see audit.

## How to use these files

For GitHub: create an empty repository, upload the **contents of this folder** including README, audit, documentation and `src`. For editing the actual game, continue to use the original Roblox Studio `.rbxl` place. These exported source files are snapshots; they are **not** automatically synchronized back into Roblox Studio.

**Safety:** Do not purchase with real Robux or publish as a finished game until the critical issues in `AUDIT.md` and the assignment acceptance tests are resolved. Studio cannot verify real analytics reporting.

## Submission checklist

See `ASSIGNMENT_CHECKLIST.md` and `TECHNICAL_REPORT_DRAFT.md`. Add the published experience URL, GitHub repository URL, screenshots, analytics evidence and test results before submission.
