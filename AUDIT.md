# Review of actual exported project — 2026-11-06

This is a **static source review** of the attached `.rbxl` file, not a runtime verification. Game functionality previously reported in chat may work but is not independently validated by reading a file. The current backup has **27 scripts**: 16 active (including 3 ModuleScripts) and 11 disabled legacy crystal Scripts. Roblox's binary place format includes more than scripts; this repository preserves source snapshots, not the entire map.

## What is verified in the uploaded file

- One `MarketplaceService.ProcessReceipt` assignment appears in `PurchaseService` and 3 developer-product IDs are recognized.
- The current scripts define the correct 1 game pass and 3 developer-product IDs and the assignment's prices in the shop UI.
- `DataService` persists Coins, BackpackLevel, CaveUnlocked, SellVouchers, BoostExpiresAt; `DataController` initializes carried count/value to 0 on join.
- `CrystalController` invokes `CrystalService.Start()` for six blue, four purple and one rare crystal spawn. The 11 original `CrystalPicku` Scripts are marked disabled in this export.
- `ShopClient` contains both the SHOP and SELL NOW button creation code.
- `FunnelService` has definitions for all 13 required funnel steps across 3 funnels.

## Issues to resolve before calling the assignment finished

### P0 — Must fix or prove safe

1. **Analytics are inferred from changing attributes rather than emitting events at each validated gameplay action.** `AnalyticsController` tries to detect a purple pickup whenever count increases by one and carried value increases by exactly 15. Simultaneous updates can be coalesced, mixed crystal sales can be misclassified, and `Purple Crystal Sold` cannot be proven simply from previous increments. Instrument `CrystalService` and the sale/voucher functions with validated crystal-type inventory tracking and direct server event logging. The assignment requires accurate funnel sequence/order.
2. **FirstTimeExperience is not recorded as first eligible only.** `FunnelService` only remembers onboarding steps in memory, so a returning player is logged as newly joined again. Persist onboarding completion, or use the analytics onboarding API's intended semantics with durable eligibility controls.
3. **Purchase and voucher state needs adverse-case testing, not just normal-play tests.** `ApplyReceipt` uses `UpdateAsync` and records receipt IDs, but correctness after uncertain writes, overlapping autosaves, and server session conflicts has not been verified. There must be no duplicate grants, no lost grants, and no stale session data overwriting newer records. In particular, the external `newlyGranted` flag is modified inside the `UpdateAsync` transform and should be treated carefully during callback retries.
4. **`DataService` runs on the development data store `TinyGem_Development_v1`.** Before live release choose an intentional data separation strategy, avoiding accidental reset or reuse of test progress. Do not change an existing store name casually when investigating load errors.

### P1 — Validate/fix

5. **Shop UI should not depend on analytics availability to render.** `ShopClient` waits for `ShopAnalyticsAction` before creating the button. If analytics fails the shop disappears; this was already observed during development. Make telemetry fail-soft and never block the shop UI on optional tracking.
6. **SELL NOW similarly waits for `RedeemVoucher` before constructing its button.** Verify `PurchaseService` runs and creates it; ideally decouple button rendering from delayed server RemoteEvent creation.
7. **Funnel session step progression is not sufficiently robust.** ShopOpened creates a GUID, but the server allows client-triggered `open` and `view` analytics; ensure that steps correspond to real UI actions and do not log confirmations out of order. Multiple product interactions within the same shop visit are currently aggregated as the first view and request.
8. **Multiple UI countdowns appear to be created.** Both `ShopClient` and `FeedbackController` create a 2× coins countdown, potentially overlapping. Consolidate them.
9. **The boost/voucher/purchase notification paths require testing.** Regular sale announcements go through `SaleAnnouncement`; voucher code updates coins/vouchers but does not emit that same popup attribute. Check the assignment's feedback criteria for all sale methods.
10. **Mobile experience and security acceptance tests are unverified.** Especially two-player pickup contention, invalid remotes, repeat receipts, game-pass rejoin, 2× extension, and real published funnel submissions.

## Recommended completion order

1. Make a fresh Studio backup and confirm `CrystalService` works with the legacy crystal Scripts disabled.
2. Fix the source-level analytics event correctness and onboarding eligibility; make shop analytics fail-soft.
3. Audit and test session locking, receipt retries, voucher redemption, pass ownership, and all Roblox DataStore failure paths.
4. Check mobile layout, sound assets, duplicate boost countdown, all feedback, and rare crystal effects.
5. Run every acceptance test, capture evidence, publish, then complete GitHub submission and the technical report.

## Scope of this audit

No DataStore records, Roblox Creator Dashboard data, purchase transactions, or published analytics were accessed by inspecting this local place file. No multiplayer sessions were run here. **Do not treat the presence of a script as evidence that its feature passed runtime tests.**
