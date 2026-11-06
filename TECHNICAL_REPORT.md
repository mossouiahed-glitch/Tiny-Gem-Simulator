# Tiny Gem Simulator — Technical Report

## 1. What was the hardest system to build, and why?

The hardest system was secure monetization and persistent data saving. Unlike the basic crystal collection system, Developer Product purchases involve asynchronous transactions, DataStore operations, and possible retries. I needed to ensure rewards are controlled by the server, saved reliably, and not granted twice.

## 2. How are Game Passes different from Developer Products?

A Game Pass provides a permanent benefit that the player purchases once. My Bigger Backpack Game Pass costs 79 Robux and adds 10 backpack slots.

Developer Products are repeatable purchases. My game includes Coin Pack (250 coins), Double Coins (10 minutes of double selling income), and Sell Vouchers (three instant sells).

## 3. Why must purchase rewards be granted by the server?

The client cannot be trusted to determine rewards because players can modify client-side behavior. The server verifies purchases, checks transaction information, and updates player data. The interface only sends requests and displays the results.

## 4. What happens when a player disconnects during a purchase?

If a Developer Product receipt cannot be processed and safely saved, the server returns `NotProcessedYet`. Roblox can retry processing that receipt later. The system should not confirm the purchase until its reward and receipt identifier have been saved.

## 5. How does your code handle a retried receipt?

The `DataService.ApplyReceipt` function uses `UpdateAsync()` and a `ProcessedReceipts` table. Before granting a reward, it checks whether the purchase ID has already been recorded. If it has, the reward should not be granted again. Otherwise, the reward and receipt identifier are written together in the saved record.

This design is intended to prevent duplicate rewards and requires verification through retry testing.

## 6. What can the three funnels tell you about player behavior?

**FirstTimeExperience** measures how many players progress from joining to collecting, selling, upgrading, and unlocking the cave.

**ShopCheckout** measures how many players open the shop, view products, request purchases, and complete verified transactions.

**CrystalProgression** measures whether players unlock the cave, collect purple crystals, and successfully sell them.

These funnels can identify where players abandon progression or purchases. Actual drop-off rates must be obtained from the published game's analytics dashboard.

## 7. What is one specific change you would make to improve retention?

I would introduce a guided objective immediately after the player's first sale, showing their progress toward the 100 coins needed for Backpack Level 2. This would give beginners a clear goal and explain what to do next.

I would evaluate this improvement by comparing conversion from the first sale to the first backpack upgrade using the FirstTimeExperience funnel.
