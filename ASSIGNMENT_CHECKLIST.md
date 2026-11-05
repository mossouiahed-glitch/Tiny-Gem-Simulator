# Assignment acceptance and submission checklist

Test **in Roblox Studio and a published experience**, not by reading source alone. Record results and screenshots.

## Acceptance tests

- [ ] Collect 10 blue crystals with Level 1 backpack => 10/10
- [ ] Try 11th crystal => server rejects pickup
- [ ] Sell 10 blue crystals => +50 coins, 0/10 backpack
- [ ] Upgrade Level 1 → 2 => 100 coins deducted, capacity 20
- [ ] Rejoin => saved coins, backpack level and cave unlock restored, carried count 0
- [ ] Unlock Crystal Cave => cost 250, requires Level 2, persisted on rejoin
- [ ] Acquire Bigger Backpack pass => +10 capacity, including after rejoin
- [ ] Buy Coin Pack twice => +250 for each distinct receipt
- [ ] Buy Double Coins twice => +20 minutes added total, offline time counted
- [ ] Use one Sell Voucher => only one consumed, whole backpack sold, boost applied when active
- [ ] Rejoin with boost remaining => correct real-world countdown
- [ ] Retry same receipt => no duplicate grant
- [ ] Two clients claim same crystal => one wins, other rejected
- [ ] Invalid RemoteEvent/ProximityPrompt requests => no unearned reward
- [ ] Test phone/tablet sizes => HUD, shop, upgrade menu, interactions work
- [ ] Published experience => analytics for all three funnels validated when reporting available

## 3 funnels

- [ ] FirstTimeExperience: Player Joined → First Crystal Collected → First Backpack Sold → First Upgrade Purchased → Second Area Unlocked
- [ ] ShopCheckout: Shop Opened → Product Viewed → Purchase Requested → Purchase Confirmed (receipt verified or pass ownership verified)
- [ ] CrystalProgression: Starting Area Entered → Crystal Cave Unlocked → First Purple Crystal Collected → First Purple Crystal Sold
- [ ] Find the largest measured funnel drop-off; explain a plausible cause and proposed improvement

## Submission

- [ ] Publicly accessible/playable Roblox experience link
- [ ] GitHub repository with source code and README
- [ ] Screenshots of gameplay, upgrade UI, shop, verified analytics instrumentation/results
- [ ] Short technical report answering all seven questions in own words
- [ ] Confirm no whole-game templates or unknown scripts from third-party free models were used
