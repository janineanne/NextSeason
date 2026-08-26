# It's time to implement StoreKit.  What information do you

## User

It's time to implement StoreKit.  What information do you need from me to do this?

## Assistant

I'll look through the project docs and code so I can ask for the specific StoreKit details this app actually needs.

The project already has a monetization plan. I’ll read that and the related roadmap so the questions match what you’ve already decided.

The monetization strategy already covers most of the product model. I can implement StoreKit 2 natively (no RevenueCat) against that plan. What I still need from you falls into three buckets: **product decisions**, **App Store Connect / legal**, and **behavior when payment fails or lapses**.

I already assume:

- Free forever, **3-show** watchlist
- **NextSeason Plus** = unlimited tracking
- Preferred catalog: **annual subscription + lifetime purchase + optional tip jar**
- No ads, no 5/10/20-show tiers, no 7-day trial
- One purchasing system, native StoreKit 2 if it stays simple
- Review prompts are a separate follow-up, not part of the first StoreKit slice unless you want them in the same pass

---

### 1. Product catalog (need answers before coding)

These lock the StoreKit products, entitlement rules, and UI.

1. **Confirm v1 products.** Is this still the launch set?
   - Annual auto-renewing subscription (Plus)
   - Lifetime non-consumable (Plus)
   - Three consumable tips
   - No monthly plan yet
2. **Prices**, even if provisional. I can put them in a local StoreKit config file and change them later. Example we can start from if you want a proposal instead:
   - Annual, lifetime, and tip amounts
3. **Product IDs**, or I can propose them. Something like:
   - `com.TrialByFyre.NextSeason.plus.annual`
   - `com.TrialByFyre.NextSeason.plus.lifetime`
   - `com.TrialByFyre.NextSeason.tip.small` / `.medium` / `.large`
4. **Subscription extras.** Any of these for v1?
   - Free trial or intro offer on the annual plan (strategy currently says no)
   - Family Sharing for lifetime and/or the subscription
5. **Tip jar copy.** Labels and amounts (e.g. “Small Tip $1.99”), and whether they appear for **both** free and Plus users.

I can proceed with a local `.storekit` file even if App Store Connect products are not created yet. I should **not** invent live product IDs if you already created them.

---

### 2. App Store Connect and legal (only you can do these)

Code can be written and tested locally without all of this. Sandbox, TestFlight, and App Review cannot.

Please tell me the status of:

- **Paid Applications Agreement** (Active or not)
- **Tax and banking** for Trial by Fyre, LLC
- Whether the account is still **individual** or already converted to the **organization**
- Whether IAP / subscription products already exist in App Store Connect
- A **Privacy Policy URL** (required)
- A **Terms of Use URL** (Apple requires a functional EULA/terms link for auto-renewable subscriptions, even if you use Apple’s standard EULA)
- Whether you have a **sandbox Apple ID** for purchase testing

If products are not created yet, I can give you the exact App Store Connect fields (subscription group, localization, review screenshot notes, etc.) once the catalog is confirmed.

---

### 3. Entitlement and UI behavior (need these; they affect architecture)

These are the decisions StoreKit implementations usually get wrong if we guess.

1. **When the paywall appears.** My default: only when the user tries to add a **4th** show, plus a quiet “NextSeason Plus” / Restore entry in About. No launch nag, no repeated prompts. Confirm or change that.
2. **What happens if Plus lapses and they already have more than 3 shows.** This is the most important product rule. Options:
   - Keep tracking all existing shows, but block adding more until they re-subscribe or remove down to 3
   - Keep all shows visible, but stop refreshing / notifying on the extras
   - Ask them to pick 3 shows to keep active
3. **Restore Purchases.** About screen is the natural place. Anywhere else?
4. **Existing beta testers.** Should people who already have more than 3 shows on TestFlight be grandfathered, or should the 3-show cap apply as soon as this ships?
5. **Scope of this pass.** StoreKit purchasing + watchlist limit + tip jar only, or also:
   - `RequestReviewAction` after the first useful notification
   - “Rate NextSeason” link on About

---

### What I do **not** need yet

- Final worldwide prices (StoreKit can localize later)
- RevenueCat vs native — I recommend **native StoreKit 2** for this catalog
- Paywall visual design — I can follow existing About / sheet patterns unless you have mockups
- Monthly plan — we can leave a hook for it without shipping it

---

If you want the shortest reply that unblocks implementation, answer:

**catalog + prices (or “propose them”), product IDs if they exist, lapse behavior for >3 shows, paywall timing, beta grandfathering, and whether review prompts are in or out of this pass.** Account/legal status can come in parallel; it does not have to block the first code slice.

## User

I'll answer what appears to be the most important question first. Of these tasks:
Please tell me the status of:

Paid Applications Agreement (Active or not)
Tax and banking for Trial by Fyre, LLC
Whether the account is still individual or already converted to the organization
Whether IAP / subscription products already exist in App Store Connect
A Privacy Policy URL (required)
A Terms of Use URL (Apple requires a functional EULA/terms link for auto-renewable subscriptions, even if you use Apple’s standard EULA)
Whether you have a sandbox Apple ID for purchase testing

The only one that's completed is accepting the Paid Applications Agreement.

Am I right in thinking that we should not proceed with StoreKit until I've done most or all of these?

## Assistant

You should not wait on StoreKit code. The remaining App Store Connect items block **live purchases and App Review**, not the implementation itself.

Local development uses a StoreKit Configuration file in Xcode. That file mocks products, prices, subscriptions, and transactions on the simulator or a device. It does not need App Store Connect products, a sandbox Apple ID, a privacy policy, or tax/banking.

A practical split:

| Work | Wait for Apple setup? |
| --- | --- |
| Purchase service, Plus entitlement, 3-show cap, paywall, tip jar, restore, tests | No. Use a local `.storekit` file. |
| TestFlight / real sandbox purchases | Yes. Need products in App Store Connect, sandbox tester, and usually privacy/terms URLs on the subscription. |
| App Review and actually getting paid | Yes. Need tax, banking, legal URLs, and finished products. |

The one Apple-side item I would **not** rush is tax and banking. If the account is still individual and you still plan to convert it to Trial by Fyre, LLC, enter banking and tax **after** that conversion. Changing the legal entity later means redoing agreements and financial info.

Suggested order:

1. We implement StoreKit against a local config file (once the product/behavior questions are settled).
2. You convert the developer account to the organization, if that is still pending.
3. You finish tax and banking on the LLC account.
4. You publish privacy policy and terms URLs, create the IAP/subscription products, and add a sandbox tester.
5. We point the app at those real product IDs and test on TestFlight before submission.

So: keep going on the account and legal work in parallel, but do not treat it as a gate for writing StoreKit. The next blockers for code are the product and behavior questions (catalog/prices, lapse behavior, paywall timing, beta grandfathering), not the unfinished App Store Connect checklist.

## User

Ok, for the rest of your questions:
1.1 yes
1.2 Annual $10, Lifetime $20, tip amounts $1, $3 and $5 -all provisional for now
1.3 Your suggestions are fine
1.4 No for now.
1.5 Tip labels - “Trailer $1”, “Pilot $3”, “Hit Show $5”.  Show to all users

3.1 Confirm
3.2 Your first option
3.3 That sounds right
3.4 Grandfathered
3.5 leave review for later

## Assistant

Those answers are enough to start. I’ll read the Swift skills and how the app is composed so StoreKit can follow the same patterns.

I’ll add a native StoreKit 2 purchase service, a local `.storekit` catalog with your provisional prices, and a 3-show cap that opens Plus only when someone tries to add a fourth show. Existing testers with more than three shows stay unlimited.

StoreKit 2 is in place for the catalog we agreed on, using a local `.storekit` file so you can test without App Store Connect products.

**What shipped**
- Free watchlist: **3 shows**. A 4th add opens NextSeason Plus (annual **$10**, lifetime **$20**).
- Lapsed Plus users keep every show they already track; they just cannot add more until they re-subscribe or remove down below 3.
- Existing testers with more than 3 shows are **grandfathered** on first launch of this build.
- About is now a production screen: Plus status, Restore Purchases, and tips (**Trailer $1**, **Pilot $3**, **Hit Show $5**) for everyone.
- Review prompts were left for later.

**What to test in Xcode**
The NextSeason scheme is wired to `NextSeason/StoreKit/NextSeason.storekit`. Run on the simulator and:
1. Add 3 shows, then try a 4th — the Plus sheet should appear and the 4th show should not be saved.
2. Buy Annual or Lifetime from that sheet (Xcode’s StoreKit test purchase UI) and confirm you can add more shows.
3. Open **About NextSeason** on Search or Watchlist — Restore, Plus, and the three tips should all be there. Tips should thank you and not unlock Plus.
4. If this device already has more than 3 watched shows, they should stay unlimited without paying.

Unit tests covering the cap, grandfathering, and stubbed purchases all passed.

**Still on you before real money / App Review**
Convert the developer account to the LLC, then tax/banking, Privacy Policy URL, Terms (Apple’s standard EULA is already linked), App Store Connect products using these IDs, and a sandbox Apple ID:

- `com.TrialByFyre.NextSeason.plus.annual`
- `com.TrialByFyre.NextSeason.plus.lifetime`
- `com.TrialByFyre.NextSeason.tip.small` / `.medium` / `.large`

Prices in the local config are the provisional ones you gave; we can change them anytime.

## User

I merged your StoreKit changes with some other work and I think something got lost.  I got the sheet you were expecting when I tapped the star on the fourth show, but it says "Purchase Options Unavailable".  Can you look through the code and fix whatever got broken?  Your original work is in git in a stash called "StoreKit changes".

## Assistant

I'll compare the current StoreKit code with the stash and trace why the Plus sheet has no products.

The Plus sheet is showing up, but StoreKit isn’t loading products. Two merge issues stand out: the scheme points at a StoreKit file path that doesn’t exist, and About lost its Plus/tip sections. I’ll fix both.

The paywall sheet itself survived the merge. What broke was **product loading**, so StoreKit came back empty and the sheet fell through to “Purchase Options Unavailable.”

Two things were wrong:

1. **The scheme pointed at a StoreKit file that does not exist.** The path was `../../NextSeason/StoreKit/NextSeason.storekit`, which resolves inside the `.xcodeproj` bundle. The real file is `NextSeason/StoreKit/NextSeason.storekit`. Without that config, `Product.products` returns nothing and does not throw. That path was already wrong in the stash; it just showed up once you actually tried a purchase.
2. **About lost its Plus / Restore / tip-jar sections** in the merge with the toolbar ellipsis work. Those are restored, and the Plus sheet now gets `PurchaseService` injected explicitly so it cannot present with an empty store.

**What to test**
Stop the app, then run it again from Xcode (not an old TestFlight build).

In **Product → Scheme → Edit Scheme → Run → Options**, StoreKit Configuration should be **NextSeason.storekit**, not None and not red.

Add a fourth show. You should see **Annual** and **Lifetime** with the provisional prices, not the unavailable placeholder. About (ellipsis) should also show Plus, Restore, and the three tips.

## User

Ok, StoreKit Configuration was set to none, but I fixed it and it's working now.

## Assistant

Good — I’ll check that the scheme saved the StoreKit file so the next launch still uses it.

That setting is what local StoreKit testing needs. With **NextSeason.storekit** selected, Xcode serves the annual, lifetime, and tip products instead of asking the App Store, where they do not exist yet.

TestFlight and a release build will still show “Purchase Options Unavailable” until those products are created in App Store Connect. For simulator and Run-from-Xcode work, you are set.

