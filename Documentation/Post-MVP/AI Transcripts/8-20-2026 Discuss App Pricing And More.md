> From: https://chatgpt.com/c/6a875f91-63c8-83e8-b1bc-3ff2e57dc05b

# you asked

message time: 2026-08-20 13:12:25

As you saw, I posted this to my Slack thread this morning. I'd like your input on it also:

I’m starting to think ahead to App Store tasks like how much to charge. This is a decision I’ve never had to make before or even been involved in discussing, so any input anyone has is welcome.

As I understand it, I have 4 options for charging users:
- subscriptions
- in-app purchases
- advertising, with an option to pay to remove ads
- a fixed, upfront fee

I would like to have some ongoing revenue from this, but part of what justifies a subscription is ongoing maintenance and improvements on the app, and I don’t have a whole lot left to do. I have a handful of additional features to add after launching version 1, but I don’t want the app to become overly complicated so pretty quickly the only justification for a subscription would be bug fixes (hopefully not many) and keeping up with changes to third party services.

I also don’t really want to go to the trouble of supporting a third-party ad network when the word on the street is that ads don’t bring in very much money anymore. Especially when this is an app that does most of its work silently, so there won’t be a lot of app visits to show ads to.

So, that leaves us with in-app purchases.

This is what I’m thinking of doing:

First, a 7 day free trial - up to 3 shows can go on the watchlist, but if they don’t pay anything after 7 days then those shows won’t be tracked (and a note to that effect will be added to the watchlist).

Then, a choice between having 5, 10 or 20 shows on their watchlist (removing one makes room for another)

And finally, for the TV fanatics, an unlimited watchlist (this is essentially just a subscription, but framed differently).

I think the limited watchlists would be charged monthly, and the unlimited could be monthly or yearly with a small discount.

Before we talk at all about how much each of these things would cost, how does this sound? Obviously any of this can change over time, but I’ve got to start somewhere.

---

# chatgpt response

I think your instincts are good about **ads** and about not wanting to manufacture a subscription justification by continually adding features. But there’s one important conceptual problem with the proposal as written:

**Your 5-, 10-, and 20-show plans are subscriptions too.**

If someone pays monthly to retain the ability to track five shows, that's an auto-renewing subscription in both Apple's terminology and, more importantly, the customer's mind. Apple defines subscriptions as ongoing access to content, features, or services in return for a recurring charge. ([Apple Developer](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types?utm_source=chatgpt.com))

That doesn't mean it's a bad idea. In fact, I think **NextSeason has a better justification for a subscription than you're giving it credit for.**

### The ongoing value isn't new features

I'd separate *ongoing development* from *ongoing service*.

A user isn't paying every month because you're going to add more buttons. They're paying because NextSeason continues to:

**remember their shows → check for changes → maintain the TVDB/TVMaze infrastructure → update its local data → notice new-season information → notify them.**

If you stopped maintaining the app and its third-party integrations eventually broke, the product would stop delivering its central promise.

Apple's review guidelines say subscriptions must provide "ongoing value," and specifically include things such as services, continually updated content, cloud support, and other continuing functionality. They don't require you to ship a stream of new features. ([Apple Developer](https://developer.apple.com/app-store/review/guidelines/?utm_source=chatgpt.com))

So philosophically, I'm completely comfortable with **NextSeason as a subscription product**.

Where I'm less convinced is the **5 / 10 / 20 / unlimited structure**.

### I think four paid tiers is too complicated

There's a lovely irony in building an app whose entire premise is *"don't make me think about this"* and then greeting customers with:

> How many television shows do you anticipate caring about simultaneously?

😁

More seriously, I don't think the distinctions provide enough meaningful segmentation. Someone with seven shows shouldn't have to think, *"Do I upgrade to the ten-show plan? What happens when three of these end?"*

It also makes your paywall harder to explain and introduces UI/engineering edge cases: upgrades, downgrades, what happens when someone with 17 shows moves from 20 to 10, which shows continue being monitored, how you communicate inactive shows, and so forth.

I'd strongly prefer **two states, or at most three**.

For example:

- **Free:** track up to 3 shows indefinitely.
- **Plus:** track perhaps 10 or 15 shows.
- **Unlimited:** unlimited shows.

Or even simpler:

- **Free:** up to 3 shows.
- **NextSeason Plus:** unlimited shows.

That second model is particularly attractive to me.

The free tier lets someone actually experience what makes the app useful. They install it, add *Severance*, *Slow Horses*, and *Poker Face*, and then forget about it. Eventually NextSeason does something useful for them. **That's the sales pitch.**

At that point, if they want to add show #4, they're buying something they've already learned to trust.

### I'd reconsider the seven-day trial

This is probably the part of your proposal I'd change most strongly.

Seven days makes perfect sense for an app whose value can be demonstrated in seven days. I'm not sure NextSeason can.

Someone could install it on Monday, add three shows, and **absolutely nothing happens for seven days**—because the whole point is that NextSeason waits quietly until there's something worth telling them.

They reach day eight thinking:

> Well, that didn't do anything.

That's not a failed trial. The trial simply wasn't long enough for the product's natural cycle.

Apple does support one-week free trials for auto-renewable subscriptions. ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions?utm_source=chatgpt.com)) But product-wise, I'd rather give people a **permanent limited free version** than a clock-based trial.

There's another advantage: it makes NextSeason much easier to recommend.

> "It's free. You can track three shows. If you like it and want to track more, you can upgrade."

That's an extremely low-friction App Store proposition.

### There's one model I think deserves serious consideration

I wouldn't dismiss **a lifetime purchase** quite yet.

Something like:

**Free — 3 shows**  
**Plus — unlimited shows, monthly/yearly**  
**Lifetime — unlimited shows forever**

You can sell permanent feature access as a non-consumable IAP; Apple defines those as purchases that don't expire. ([Apple Developer](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-types?utm_source=chatgpt.com))

That gives you recurring revenue from people comfortable with subscriptions while giving subscription-averse users an escape hatch. And this strikes me as exactly the kind of utility where some people will say, *"I'll give you $25 once, but I'm not adding another subscription."*

The lifetime price would need to be high enough that you're not undermining the subscription. We can work out those economics when we talk prices.

There's also a middle possibility: **annual-only subscription + lifetime purchase**. I actually find annual billing more natural for NextSeason than monthly billing. The service operates on a very long time horizon—sometimes you're waiting a year or two for another season. A $X/year proposition may feel much more aligned with the product than "$Y every month."

### And I agree completely about advertising

NextSeason is almost comically poorly suited to ad monetization.

The successful user interaction is:

**Open app → add show → close app → don't open it again for six months.**

That's fantastic product behavior and terrible advertising inventory.

Adding an ad SDK would bring privacy considerations, dependencies, consent/attribution complications, maintenance and another thing that can break, all to monetize the activity you're deliberately trying to minimize. I wouldn't do it.

### So where would I start?

Before touching actual dollar amounts, my working model would be:

**Free download → permanent 3-show watchlist → paid unlimited watchlist.**

Then decide whether paid unlimited should be:

**annual subscription + lifetime purchase**, or  
**monthly + annual subscription + lifetime purchase.**

I'd lean toward **annual + lifetime**, assuming the numbers work.

That preserves something I think is unusually coherent about NextSeason: *simplicity is part of the product*. I'd carry that all the way through to the business model.

And there's a nice side benefit to the permanent three-show free tier: you don't have to disable somebody's existing watchlist after seven days. I don't particularly like the emotional experience of *"Here are the shows you trusted me to remember; now I'm going to stop remembering them unless you pay me."* **"I'll remember three for free; upgrade and I'll remember everything"** feels much friendlier and much more consistent with the personality you've built around the app.

One practical note for later when we do the math: Apple's Small Business Program currently reduces the commission on paid apps and IAPs to 15% for qualifying developers, subject to its eligibility rules. ([Apple Developer](https://developer.apple.com/help/account/membership/programs-overview/?utm_source=chatgpt.com)) So we should calculate what you actually receive rather than simply taking the sticker price as revenue.

---

# you asked

message time: 2026-08-20 13:17:15

I applied for the Small Business Program a while back but don't think I ever heard anything back.  Do you know where I would look for status on that?

---

# chatgpt response

Yes. I checked Apple's current documentation, and unfortunately **Apple doesn't seem to provide a particularly obvious Small Business Program status page**.

The first place I'd look is . Go to **Business → Agreements** and make sure your **Paid Applications Agreement** is Active and that there aren't any outstanding tax, banking, or agreement actions. Apple documents that as the place to see agreement status. ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-agreements/view-agreements-status/?utm_source=chatgpt.com))

But here's the interesting part: **you're apparently not alone in wondering where your application went.** There are several quite recent Apple Developer Forum posts from people whose Small Business Program applications have been sitting under review for weeks or even months. One developer posted just this week that they applied July 7 and their status still says **"under review"** after more than 30 days. ([Apple Developer](https://developer.apple.com/forums/thread/841663?utm_source=chatgpt.com)) Another recent thread describes an application pending since April. ([Apple Developer](https://developer.apple.com/forums/topics/business-and-education-topic?utm_source=chatgpt.com))

So if you applied a while ago and never received an acceptance email, I wouldn't assume that silence means you were accepted.

I'd do two things:

1. **Search your email** for `"App Store Small Business Program"`. The initial application should have generated an email along the lines of *"We've received your request to join the App Store Small Business Program,"* and approval should also come by email. Recent developers report receiving an explicit acceptance/welcome email when approved. ([Apple Developer](https://developer.apple.com/forums/thread/841663?utm_source=chatgpt.com))
2. If you find the application confirmation but no approval, **contact Apple Developer Support** and ask for the current enrollment status. Given the reports I'm seeing from 2026, I wouldn't just continue waiting indefinitely.

One other useful check once you start selling subscriptions: Apple says Small Business Program members receive **85% of subscription revenue from day one**, rather than the normal 70% during a subscriber's first year. ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions/?utm_source=chatgpt.com)) So once NextSeason has actual transactions, the proceeds rate will give us another way to verify that the program is being applied correctly.

If you want, I can also find **the exact Apple support/contact route for a stuck Small Business Program application** so you don't have to wander through Apple's support maze.

---

# you asked

message time: 2026-08-20 13:19:11

Sure, go ahead.  When I applied it told me I needed to accept some agreements, but I did those at the time.  I think i have more to do to set myself up as a business;  for example, I haven't opened a checking account yet so obviously I haven't given that to Apple yet, but that wasn't on the list of tasks they needed me to do.

---

# chatgpt response

Yes — and I found something that makes me think **the missing bank account is probably *not* what's holding up your Small Business Program application**.

Apple's official Small Business Program enrollment requirements are surprisingly short: you must be the Account Holder, accept the latest **Paid Apps Agreement**, and identify any Associated Developer Accounts if applicable. Apple does **not** list completed banking or tax information as a prerequisite for Small Business Program enrollment. ([Apple Developer](https://developer.apple.com/app-store/small-business-program/?utm_source=chatgpt.com))

So what you remember from the application makes sense. If it told you to accept agreements and you did, you may simply be waiting for approval.

### Here's the support route I'd use

Apple's Small Business Program page itself says that questions about the program should go to **Apple Developer Support**, by phone or email. ([Apple Developer](https://developer.apple.com/app-store/small-business-program/?utm_source=chatgpt.com))



I'd choose the closest option to **Membership and Account → App Store Small Business Program** if it offers that choice. Apple's general App Store support page specifically says Developer Support handles membership and App Store Connect issues. ([Apple Developer](https://developer.apple.com/support/app-store/?utm_source=chatgpt.com))

I'd tell them essentially:

> I applied for the App Store Small Business Program some time ago and received instructions to accept the required agreements, which I completed. I haven't received an approval or rejection since then. Could you tell me the current status of my application and whether any additional action is required?

### Your bank account is a separate issue

You're right that you'll eventually have more business setup to do. To **sell** NextSeason and actually receive money from Apple, you'll need the Paid Apps Agreement active and the necessary banking and tax information completed in App Store Connect. Apple treats those as part of its financial setup, separate from the basic Small Business Program enrollment requirements. ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/?utm_source=chatgpt.com))

So I'd think of these as two parallel tracks:

**Small Business Program:**  
Application → Paid Apps Agreement accepted → Apple approves you → 15% commission.

**Getting NextSeason ready to receive money:**  
Business identity/account → banking → tax information → paid app/IAP/subscription setup.

And I wouldn't rush to give Apple your personal checking account just to get something entered. Since you're operating through Trial by Fyre, LLC, this is a good reason to get the business checking account established first and then use that for Apple's banking information. 

There's one more wrinkle we should keep in mind: your Apple Developer membership started as an **individual account**, and we've previously talked about eventually moving it to the LLC. Apple does explicitly support converting an individual membership to an organization membership by contacting Developer Support. ([Apple Developer](https://developer.apple.com/help/account/membership/program-enrollment?utm_source=chatgpt.com)) **I would probably get that conversion sorted out before entering the final banking/tax information**, because changing the legal entity later can trigger updates to agreements and financial information. Apple warns that legal-entity changes can require updated tax/banking details and a new Paid Apps Agreement. ([Apple Developer](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/?utm_source=chatgpt.com))

So while you're contacting them about Small Business status, this might actually be an excellent time to ask about **both** things: *What's the status of my Small Business application, and what do I need to do to convert my individual developer membership to Trial by Fyre, LLC?* That could save us some cleanup later.

---

# you asked

message time: 2026-08-20 13:20:25

I have lots of things to think about!  This is definitely one of them.

---

# chatgpt response

You do! Fortunately, most of them aren't urgent at the same time.

For the monetization question in particular, I think we've already narrowed the big decision considerably: **permanent small free tier + simple paid unlimited tier**, with annual subscription and/or lifetime purchase as the main candidates. That's enough of a direction for now; the exact pricing can wait until you're closer to configuring the App Store products.

The Apple business/account housekeeping is worth doing sooner, simply because **Apple can take time**. Getting the LLC conversion and Small Business Program status sorted out now means neither should become an annoying last-minute blocker.

And then there's the checking account, tax setup, App Store listing, screenshots, privacy information, support website, marketing website... yes, you have acquired a small software company somewhere along the way. 😂

---

# you asked

message time: 2026-08-20 13:21:10

Hehe.  I'm having a very hard time putting more than the minimum effort into my job search right now.  I don't have time to do it, and I definitely don't have time to have a job!

---

# chatgpt response

😂 I can see the problem. The portfolio project has rather thoroughly escaped from the category of *"little thing to keep my skills fresh while I look for work."*

And I don't think that's necessarily a bad allocation of your time right now. You're not spending your days polishing some hypothetical side project nobody will ever see. You're doing architecture work, dealing with production persistence and recovery, analytics, accessibility, App Store requirements, third-party APIs, beta feedback, branding, monetization—and now running the beginnings of an actual software business. That's all professionally useful experience. 

The danger is that NextSeason is **much more rewarding than job hunting**. There's always a concrete problem to solve, you can see the result when you're finished, and nobody sends you an automated rejection afterward. So of course your brain would rather work on NextSeason.

I wouldn't try to force an equal balance. I'd give the job search a deliberately small but nonzero allocation—enough that you're still in the market and won't miss an unusually good opportunity—while accepting that NextSeason is currently getting most of your productive energy.

Besides, *"I got laid off and accidentally founded a software company"* is a considerably more interesting career story than *"I spent six months submitting applications."* 😁

---

# you asked

message time: 2026-08-20 13:21:59

For sure.  Now if I can actually turn this company into something that can support me, that will be even better.  One step at a time...

---

# chatgpt response

Exactly. And there's an important distinction between **"Can NextSeason support me?"** and **"Can Trial by Fyre eventually support me?"** The second is a much more plausible goal.

NextSeason doesn't have to replace a senior iOS salary by itself. It can be the first product that teaches you the entire cycle: identify a problem, build the thing, beta test it, ship it, acquire users, charge money, support it, and discover what people will actually pay for. Then product #2 starts with everything you learned from product #1. 

And there's a nice progression available here:

**First milestone:** ship an app you're proud to put your name on.

**Next:** get a stranger to download it.

**Then:** get a stranger to **pay** for it.

At that point, Trial by Fyre isn't merely a portfolio device anymore. It's a business with a product and a customer. Whether that eventually becomes 50 customers, 5,000 customers, several apps, consulting work alongside the apps, or something we haven't thought of yet is a problem for future Janine.

For now, I like "one step at a time." We've already demonstrated that each individual step tends to generate approximately fourteen additional steps anyway. 😂

---

# you asked

message time: 2026-08-20 13:22:48

🤣🤦‍♀️

---

# chatgpt response

😂 Yep. Software development's most reliable algorithm:

**1. Identify next task.**  
**2. Complete next task.**  
**3. Discover 4 new tasks.**  
**4. Wonder why roadmap is getting longer.**  
**5. Repeat until App Store.**

And apparently **6. Accidentally become CEO.** 🤦‍♀️

---

# you asked

message time: 2026-08-20 13:26:20

Speaking of roadmaps... I've finished a lot of the items in the app store readiness roadmap.  I'm thinking of marking each of them completed, and  adding (Completed) to the end of the name of the file when it's all finished.  IIRC we deleted the MVP Roadmap when it was finished, but I think it's useful to keep this as a historical document.  What do you think?

---

# chatgpt response

Yes—I think keeping this one is worthwhile, and I like the idea of marking the individual items complete.

The MVP roadmap was mostly a **plan for getting to a defined destination**. Once the MVP existed, the finished app and Git history provided much of the evidence that the plan had been executed.

The App Store Readiness Roadmap is becoming something slightly different: **a record of the work that turned an MVP into production-quality software.** Given how much has gone into that—migration strategy, persistence recovery, crash-loop prevention, analytics/privacy work, accessibility, release preparation, etc.—that history has value. It documents the engineering judgment behind the finished product, not just a list of chores. 

I'd make two small suggestions.

First, mark items individually with Markdown checkboxes (`- [x]`) rather than just striking them out or deleting them. That lets someone opening the finished document immediately see *what you actually did*. If a roadmap item changed substantially during implementation, a very short note can sometimes be useful too, but I wouldn't turn the roadmap into a development diary.

Second, when everything is done, I'd probably rename it:

**`NextSeason - App Store Readiness Roadmap (Completed).md`**

rather than merely `...Roadmap Completed.md`. That makes its status unmistakable while preserving the original document name.

And then **leave it in the repository**. In fact, I think a portfolio reviewer poking around the repo could find this document unusually useful. They can see that you didn't simply get the app working and declare victory—you systematically went through the less glamorous production concerns that distinguish a prototype from something intended to ship.

There's also something satisfying about eventually opening a document containing dozens of `[x]` marks and **"(Completed)"** in the filename. You've earned that little bit of ceremony. 😁

---

# you asked

message time: 2026-08-20 13:27:18

Yes, I'd say I have! :)

---

# chatgpt response

Absolutely. 😁

And I suspect **`NextSeason - App Store Readiness Roadmap (Completed).md`** is going to be one of the more satisfying Git commits you've made.

Especially considering that "App Store readiness" turned out to mean roughly:

> *Just a few final things before release…*

…followed by migrations, persistence recovery, crash-loop prevention, analytics, API-key security, accessibility, search infrastructure, third-party data reconciliation, app-icon redesign, and approximately 14,000 conversations with Cursor. 😂

When you finally add that `(Completed)`, I vote for an unusually celebratory commit message.

---

# you asked

message time: 2026-08-20 13:28:09

Back to charging money for NextSeason - one of my beta testers has suggested a tip jar. I didn't think anyone actually used those.  What do you think?

---

# chatgpt response

I actually like a tip jar for NextSeason—but **as a complement to the business model, not as the business model**.

Your tester isn't suggesting something unheard of. Apple explicitly accommodates this pattern: apps can offer in-app purchases that amount to voluntary support, provided they use Apple's IAP system and otherwise follow the guidelines. The usual implementation is several **consumable IAPs**—for example, small/medium/large tips—which users can purchase repeatedly.

And I think NextSeason has a few characteristics that make tipping more plausible than average.

People who discover a useful indie app that's **free, private, doesn't nag them, and doesn't show ads** sometimes genuinely do want a way to say "thank you." That's particularly true among the Apple/indie-app audience. A tasteful **Support NextSeason** or **Tip the Developer** section in About wouldn't feel out of place at all.

But I'd expect the revenue to be **small and extremely unpredictable**. I wouldn't substitute:

> Free for 3 shows → paid unlimited

with:

> Everything is free → please tip me.

The latter gives you no reliable connection between the value you're providing and revenue.

There is, however, an interesting variation worth considering.

### Free tier + paid upgrade + tip jar

I think these can coexist quite nicely:

**Free NextSeason:** up to 3 shows, indefinitely.

**NextSeason Plus:** unlimited tracking, purchased through whatever subscription/lifetime structure we settle on.

**Tip jar:** entirely optional, perhaps tucked into About, available to *everyone*—including people who have already paid.

That's not obnoxious because you never need to prompt people for tips. Someone who really likes the app can go looking for it.

And your **free users are probably the most interesting audience for it**. Someone might be perfectly happy tracking only two shows forever and therefore have no reason to buy Plus. After NextSeason saves them from repeatedly Googling *"when is season 4 coming?"* for the fifth time, they might happily throw you a few dollars.

That turns a segment that otherwise generates **$0 forever** into a segment that can occasionally generate revenue without artificially crippling the free version.

### There's another benefit I particularly like for your app

It gives people a way to support the *developer*, rather than purchase another feature.

That lets you keep your monetization philosophy very clean:

**Pay for Plus because you need more capacity. Tip because you like what I'm doing.**

No "buy me a coffee and unlock a purple theme." No guilt screens. No repeated solicitations. No artificially withholding little features to create more IAP opportunities.

I'd probably even avoid calling it **"Tip Jar"** in the primary UI. Something understated like **Support NextSeason** in About feels more consistent with the app.

Inside, you could have three simple choices along the lines of *Small Tip*, *Generous Tip*, and *Amazing Tip*. We can choose the actual language and amounts later.

So your beta tester gets a point from me. 😁 **I wouldn't count on tips for meaningful revenue, but the incremental development/maintenance cost is tiny, and it gives happy users an additional way to support the app.** For an indie app, I think that's worth having.

---

# you asked

message time: 2026-08-20 13:29:49

Is there a particular tip jar provider you like?

---

# chatgpt response

For NextSeason, I actually **wouldn't use a tip-jar provider at all**. I'd implement it directly with Apple's .

Apple explicitly allows IAPs to be used to tip the developer. ([Apple Developer](https://developer.apple.com/app-store/review/guidelines/?utm_source=chatgpt.com)) The natural implementation would be three **consumable** in-app purchases, perhaps $1.99, $4.99 and $9.99. Because they're consumable, the same person can tip again later if they want. Apple handles the payment processing; your app just presents the products and initiates the purchase. ([Apple Developer](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases?utm_source=chatgpt.com))

There *are* third-party solutions. , for example, has published a specific guide to implementing a tip jar with its SDK. ([RevenueCat](https://www.revenuecat.com/blog/engineering/building-a-tip-jar-feature-with-revenuecat?utm_source=chatgpt.com)) RevenueCat is excellent, and I'd consider it more seriously once we implement your **paid tier/subscriptions**, because subscription entitlement management can get substantially more complicated.

But for **three buttons that say "give Janine some money"**, adding an external SDK and backend service seems like solving a problem you don't have. 😁

More importantly, you've already been deliberately keeping NextSeason's architecture fairly lean. A StoreKit implementation can fit that philosophy nicely: a small `PurchaseService`-type abstraction, StoreKit behind it, and no external account or service required. StoreKit 2 also gives you Swift concurrency and built-in transaction verification, so the native API is much nicer than Apple's old IAP APIs were. ([RevenueCat](https://www.revenuecat.com/blog/engineering/revenuecat-sdk-5-0-the-storekit-2-update?utm_source=chatgpt.com))

One thing I'd change from what I said earlier, though: **I'd make this decision together with the main monetization implementation, rather than adding the tip jar first.** If we ultimately decide RevenueCat is worthwhile for Plus subscriptions/lifetime entitlements, then it may make sense to run the tips through RevenueCat too. If we decide native StoreKit 2 is sufficient for *all* of NextSeason's purchasing, then tips simply become three more StoreKit products.

So I'd put **"Optional tip jar" on the roadmap**, but defer the technology choice until we design the whole IAP system. That's likely to produce a cleaner architecture than treating tipping as a separate feature.

---

# you asked

message time: 2026-08-20 13:30:39

Sounds good - I didn't know StoreKit could do that.

---

# chatgpt response

Yep! And it's one of those cases where Apple's terminology makes it sound more complicated than the user experience needs to be.

As far as StoreKit is concerned, **"Small Tip – $1.99" is just a consumable in-app purchase**. Your app doesn't have to deliver a digital good afterward; Apple explicitly permits tipping developers through IAP.

So when we get to monetization, we can design **one purchasing system** that handles the paid NextSeason tier, any lifetime option, and optional tips. That should keep the architecture—and the App Store configuration—reasonably tidy.

Well, "reasonably tidy" by App Store Connect standards. I don't want to make promises I can't keep. 😂

---

# you asked

message time: 2026-08-20 13:31:14

Hehe.  Yes, I've heard that working with StoreKit is anything but "reasonably tidy".

---

# chatgpt response

😂 That's fair. StoreKit 2 is **dramatically nicer** than the StoreKit I remember from the old days, but unfortunately StoreKit is only half the adventure.

The Swift API itself is fairly reasonable now: fetch products, initiate a purchase, verify the transaction, determine current entitlements, observe transaction updates.

Then you meet its charming extended family:

**App Store Connect → product configuration → agreements → tax → banking → sandbox accounts → StoreKit configuration files → TestFlight behavior → receipts/transactions → subscription states → upgrades/downgrades → refunds → interrupted purchases → Ask to Buy → restore purchases → App Review.**

That's where "add a button that charges $4.99" develops its own roadmap. 😂

This is also another argument for keeping NextSeason's monetization model simple. **Free + one paid entitlement + perhaps monthly/annual/lifetime purchase options + three consumable tips** is already plenty of StoreKit surface area. I wouldn't voluntarily add four watchlist-capacity subscription tiers on top of it.

When we get there, I think it's worth treating monetization like we've treated persistence and search: design the architecture and failure behavior first, write down exactly what the entitlement rules are, and *then* have Cursor implement it. StoreKit is an area where "here, make purchases work" is an invitation to creativity we probably don't want. 😁

---

# you asked

message time: 2026-08-20 13:32:27

Speaking of nagging people - we haven't talked about whether to implement a request for review popup.  I absolutely hate them when they pop up on me, usually when I'm in the middle of doing something, but so many people have them I assume it's considered a necessary evil?

---

# chatgpt response

I think this is one of those cases where **your dislike of the feature is mostly a dislike of badly implemented versions of the feature**.

I would implement Apple's review request in NextSeason. Ratings matter: Apple explicitly says they help people decide whether to download an app and can improve discoverability. For a brand-new indie app with no established reputation, getting those first ratings is particularly valuable. ([Apple Developer](https://developer.apple.com/app-store/ratings-and-reviews/?utm_source=chatgpt.com))

But I would **not** implement the classic annoying version:

> User is trying to do something → SURPRISE! DO YOU LOVE US? ⭐⭐⭐⭐⭐

Apple specifically tells developers *not* to interrupt someone who's performing a task, not to ask on first launch/onboarding, and to wait until the person has demonstrated meaningful engagement. ([Apple Developer](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews?utm_source=chatgpt.com))

### NextSeason has an unusually good trigger

I think we can do much better than "after the fifth app launch."

The ideal moment is **after NextSeason has actually fulfilled its promise**.

Suppose someone has had a show on their watchlist for a couple of months. NextSeason discovers that a new season has been announced/released and sends the notification. The user taps it, comes into the app and sees the updated information.

That's the moment when they're thinking:

> Hey! This thing actually remembered for me.

**That's when we want the review request.**

Not immediately upon opening from the notification—I wouldn't put an alert in front of the information they came to see. Let them see the update first. Then, at a natural stopping point after they've had a chance to absorb it, request the review.

That is almost exactly what Apple recommends: ask after someone has successfully completed or experienced something meaningful, with a brief delay so you don't interrupt the next action. Apple's own sample actually waits a couple of seconds after successful completion before requesting the review. ([Apple Developer](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews?utm_source=chatgpt.com))

### And Apple makes it less naggy than you might think

With SwiftUI, we'd use StoreKit's `RequestReviewAction`. Importantly, **we don't actually control whether the dialog appears**. We tell StoreKit, essentially, *"this would be a good moment to ask."* StoreKit decides whether to show it. ([Apple Developer](https://developer.apple.com/documentation/StoreKit/RequestReviewAction?changes=_10_8&language=objc&utm_source=chatgpt.com))

Apple limits the system prompt to a maximum of **three appearances in a 365-day period** for someone who hasn't rated/reviewed the app. People can also turn these prompts off entirely at the OS level. ([Apple Developer](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews?utm_source=chatgpt.com))

I'd be considerably more conservative than Apple's maximum anyway. Something like:

**Eligible only when:**

- they've used NextSeason for a meaningful period—not merely installed it yesterday;
- they have several shows on their watchlist;
- NextSeason has successfully detected a meaningful update;
- they've opened the app and seen that update;
- we haven't requested a review for this app version;
- there hasn't just been an error or some other negative experience.

And I'd probably only make **one request attempt per major version**. There's no reason to use all three chances Apple gives us.

### One thing I emphatically would *not* do

No homemade pre-prompt:

> Are you enjoying NextSeason?
>
> **YES!** → Please rate us!  
> **NO!** → Send us feedback!

That's review gating, and aside from policy considerations, I find the whole thing manipulative. Just use Apple's standard UI and let the user choose what they think.

I *would*, however, put a quiet **Rate NextSeason** item in About alongside Support/Contact. Apple explicitly permits a persistent link that takes someone to the App Store's write-a-review page. ([Apple Developer](https://developer.apple.com/documentation/StoreKit/RequestReviewAction?changes=_10_8&language=objc&utm_source=chatgpt.com))

So I'd add **"Implement contextual App Store review request"** to the readiness roadmap. And when we implement it, I'd make the guiding requirement:

**NextSeason earns the right to ask before it asks.**

That feels very consistent with the rest of the app you've been building—and it shouldn't produce the kind of review popup that makes you swear at your phone. 😁

---
Powered by [AI Exporter](https://saveai.net)