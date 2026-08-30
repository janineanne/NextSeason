> From: https://chatgpt.com/c/6a91e4e3-1af0-83e8-b046-d8273a9c2745

# you asked

message time: 2026-08-28 12:44:37

I've had some ideas for the Product Evolution Roadmap and I'd like your thoughts.

1.

---

# chatgpt response

Absolutely. What’s idea #1?

---

# you asked

message time: 2026-08-28 12:45:14

Sorry, I keep forgetting to use shift-return.  I've had the same problem for years in Slack.

---

# chatgpt response

😂 And once Enter = “send” is in your muscle memory, remembering Shift-Return *before* you hit it is apparently asking a lot.

Go ahead and send the ideas however they come out — one at a time is perfectly fine. I’ll keep track.

---

# you asked

message time: 2026-08-28 12:49:15

1.
Add a control to the notifications that lets the user request that that notification be repeated, with frequency and interval options.  Most people will forget something that happens once while they're busy with something else.

2.
Let users choose to receive emails instead of or in addition to notifications, since an email is sort of the electronic version of writing it on a post-it note.

3.
Let users opt-in to a regular notification which is a report of all the shows on their watchlist and their current statuses.  This is to remind the user that the app exists.

All three of these might require adding a Settings page.

---

# chatgpt response

I like the direction of all three. More importantly, they fit together: they’re all about making NextSeason useful **after the moment when it discovers something**, rather than assuming one notification is enough.

### 1. Repeat notifications

This is the strongest of the three to me.

The current model effectively says, “You asked me to tell you when this happens; I told you once; my job is done.” But that isn't how people use reminders. If I see “Season 4 of *Only Murders in the Building* is now available” while I'm in the grocery store, there is a very good chance I've forgotten about it by the time I'm sitting in front of the TV.

I would be careful about making the notification itself too complicated, though. Rather than putting frequency/interval controls directly into every notification, I'd consider a notification action such as **Remind Me**. Tapping it could give a small set of useful choices—later today, tomorrow, this weekend, perhaps custom.

That makes it feel like a reminder rather than a notification-spam feature, and it doesn't require users to predict in advance how often they'll need nagging.

For Product Evolution, I think this is an excellent feature. It also feels very consistent with the fundamental promise of NextSeason: **“I don't want to have to remember this.”**

### 2. Email notifications

I like this more than I initially expected to.

Email has an important property that a push notification doesn't: **it remains somewhere until I deal with it.** Your Post-it analogy is good. It also gives NextSeason another way to reach someone who has notifications disabled.

There are costs, though. This is substantially more infrastructure than #1. Once NextSeason has its planned backend notification service, email becomes much more reasonable, but you'd still need email collection/verification, delivery infrastructure, unsubscribe handling, bounce handling, privacy-policy changes, and so forth.

So I'd put this **later in Product Evolution**, probably after the server-side notification work. It's a nice optional delivery channel, but I wouldn't make it part of the core notification architecture initially.

I'd also absolutely allow **push, email, or both** rather than treating email as a replacement.

### 3. Regular watchlist status report

This one may actually have the most interesting product implications.

You're explicitly identifying the problem: NextSeason is deliberately an app users **shouldn't need to open very often**. That's good product design, but terrible for retention metrics and for users remembering they installed it.

A periodic digest solves that without manufacturing fake reasons to open the app.

Something like:

> **Your NextSeason update**
>
> 2 shows are airing now  
> 3 are returning soon  
> 4 are still waiting for a date  
> 1 has ended

And tapping it opens the Watchlist.

I would **not enable this by default**. Someone who wants NextSeason to silently watch their shows until something changes should be allowed to use it exactly that way.

But an opt-in **weekly/monthly watchlist update** seems quite useful. Eventually this could work particularly well as an email digest, too. That gives #2 and #3 a nice intersection.

### And yes: I think you've finally invented Settings. 😄

Until now, we've repeatedly managed to avoid adding Settings because there really wasn't much that belonged there. These features change that.

You'd potentially have:

- **Notifications:** enabled status, repeat/reminder behavior, digest frequency
- **Email:** email address, delivery preference
- **Watchlist digest:** off / weekly / monthly, perhaps preferred day
- Later, other genuinely global preferences that accumulate

That's enough to justify a Settings screen rather than stuffing more controls into About.

I'd keep **About NextSeason** separate. Settings answers *“How should NextSeason behave for me?”* About answers *“What is this app / what version am I running / how do I support it?”*

There's also a nice product theme emerging here that I think is worth capturing explicitly in the roadmap:

**NextSeason shouldn't merely notify users. It should help them remember.**

That's a meaningfully better product proposition than “an app that sends a notification when a show returns.” It gives you a coherent reason for repeat reminders, email delivery, and periodic digests rather than making them look like three unrelated feature ideas.

---

# you asked

message time: 2026-08-28 12:52:06

Exactly.  And since we're not implementing ads, we don't have any need to drive users back to the app.  We just want them to remember they have it.

---

# chatgpt response

Yes — and I think that distinction should influence how you design #3.

You **don't need engagement for engagement's sake**. There is no benefit to Trial by Fyre if someone opens NextSeason three times a week instead of three times a year, as long as the app continues doing its job and the user remains happy with it. In fact, an app whose users can mostly forget about it is arguably succeeding at its purpose.

So I wouldn't describe #3 internally as an engagement or retention feature. I'd describe it as a **reassurance/remembrance feature**:

> “NextSeason is still here, still watching your shows, and here's what it knows.”

That suggests the regular report shouldn't contain artificial calls to action like “Open NextSeason to see your watchlist!” It should deliver the useful information **right in the notification**. If the user wants to open the app afterward, great; if not, the notification has done its job.

It also reinforces why opt-in matters. Some users will think, “I trust you; don't bother me until something happens.” Others will appreciate an occasional confirmation that NextSeason hasn't disappeared into the collection of apps they installed six months ago.

And there's a subtle commercial benefit even without advertising: when renewal time arrives, a Plus subscriber who has periodically seen *“NextSeason is still keeping track of these 14 shows for me”* has a much clearer sense of what they're paying for than someone who hasn't thought about the app in eleven months.

That's **reminding them of the service's value**, rather than manufacturing engagement. I think that's entirely consistent with the kind of product you've been building.

---

# you asked

message time: 2026-08-28 12:55:29

One possible problem did occur to me the other day.  If someone has Offload Unused Apps turned on, it's very possible that NextSeason could be offloaded.  Is there any way to prevent that?

---

# chatgpt response

Unfortunately, **no — an ordinary App Store app cannot opt itself out of Offload Unused Apps.** Apple controls that behavior, and there isn't an API or entitlement NextSeason can use to say “never offload me.” Apple describes the feature as automatically removing unused apps when storage is low while retaining their documents and data. ([Apple Support](https://support.apple.com/en-tm/guide/iphone/iph47c931112/26/ios/26?utm_source=chatgpt.com))

And you're right to flag this as a particular problem for NextSeason. Its ideal behavior is almost designed to make iOS conclude that it's “unused”: the user sets up a watchlist, closes the app, and happily doesn't touch it for months.

There is an important wrinkle, though, because of the backend notification work already on the Product Evolution Roadmap.

**Once NextSeason moves to server-generated push notifications, being offloaded is much less of a product-design concern than it is with the current background-refresh architecture.** APNs delivers user-facing remote notifications independently of the app actively running; Apple explicitly describes notifications as communicating information “regardless of whether your app is running on the user’s device.” ([Apple Developer](https://developer.apple.com/Documentation/usernotifications/?utm_source=chatgpt.com))

The current architecture is much more vulnerable because NextSeason itself has to get background execution time, fetch the TV data, notice the change, and generate the notification. Apple makes background execution discretionary in the first place. ([Apple Developer](https://developer.apple.com/documentation/uikit/uiapplication/backgroundrefreshstatus?changes=_8&utm_source=chatgpt.com))

So this actually strengthens the case we've already made for moving notification detection to the server.

There is one thing I **wouldn't** do: try to manufacture app launches to prevent offloading. That would run directly contrary to what we were just talking about. NextSeason should be an app that users don't have to babysit. If somebody hasn't opened it for nine months because it has quietly done its job for nine months, that's a successful nine months.

I think I'd add **“Resilience to app offloading / long periods without launch”** as a consideration under the server-side notifications roadmap item rather than treating it as another feature. When we design that system, one of its explicit requirements should be:

> A user who has configured NextSeason should continue receiving requested show-status notifications without periodically launching the app.

That's a very good architectural requirement for this particular product.

---

# you asked

message time: 2026-08-28 12:56:52

Will an offloaded app still receive notifications, local or external?

---

# chatgpt response

There’s an important distinction here between **already-scheduled local notifications** and notifications that require the app to run again. I’m checking Apple’s documented behavior because offloading is a slightly different state from simply terminating an app.

The answer is a little more nuanced than my previous message implied.

**Local notifications:** if NextSeason has **already scheduled** a local notification with `UNUserNotificationCenter`, iOS owns that pending request and can deliver it even when the app itself is not running. Apple says a scheduled request remains active until it fires or is explicitly canceled. ([Apple Developer](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app?utm_source=chatgpt.com))

But that does **not** help with NextSeason’s current “wake up, check TV data, discover a new season, then create a notification” workflow. An offloaded app can’t run that code, so it can’t discover anything new or schedule new local notifications.

**Remote/push notifications:** these are the much better fit for an offloaded-app scenario because the server creates the notification and APNs delivers it; Apple specifically describes remote notifications as working when the app isn’t running. ([Apple Developer](https://developer.apple.com/documentation/usernotifications?changes=l_6&utm_source=chatgpt.com))

The part Apple’s public documentation does **not clearly guarantee** is the exact behavior of user-visible APNs notifications while an app is specifically in the *offloaded* state, as opposed to merely terminated. I would therefore not design NextSeason around an undocumented assumption that offloaded apps will definitely continue receiving pushes indefinitely.

So the practical picture is:

| Situation | Current local approach | Server push |
|---|---|---|
| App merely closed | Yes, if background refresh runs and discovers change | Yes |
| Previously scheduled local reminder | Yes; system owns it | N/A |
| App offloaded | **Cannot perform new checks or schedule new alerts** | **Potentially much more resilient, but I would test this explicitly** |
| App deleted | No | No reliable delivery |

And this gives us a very worthwhile test case for the backend work: install NextSeason, register for APNs, **offload it manually from Settings**, send a visible push from the server, and see exactly what current iOS does.

So I would slightly revise what I said before: **server-side notifications greatly reduce the offloading problem, but I wouldn't yet say they eliminate it until we've verified actual offloaded-app APNs behavior on-device.**

---

# you asked

message time: 2026-08-28 13:01:02

Is there any way to detect that an app has been offloaded?  I'm wondering whether once we have server-side notifications we could automatically switch to email when the app is offloaded (if we have the user's email address, which would mean they gave us permission to do so).

---

# chatgpt response

Not reliably, and Apple appears to make that difficult on purpose.

There is **no supported API that tells your server “this app has been offloaded.”** APNs can eventually tell you that a device token is no longer usable with a `410 Unregistered` response, but Apple explicitly says that should **not** be interpreted as proof that the app was removed. The token may have changed for other reasons, and Apple deliberately avoids giving developers a precise uninstall signal for privacy reasons. ([Apple Developer](https://developer.apple.com/forums/thread/682939?utm_source=chatgpt.com))

That means I would **not** design automatic email fallback as:

> push failed ⇒ app is offloaded ⇒ send email

because the premise is too uncertain.

What you *can* do is design a broader **delivery fallback policy**. For example: if the user has explicitly enabled email as a backup channel, and your backend determines that push delivery is no longer viable for that device token, it can send the important notification by email instead. A `410 Unregistered` is a strong enough signal to stop using that token; Apple says it is final and the server should remove it. ([Apple Developer](https://developer.apple.com/forums/thread/806522?utm_source=chatgpt.com))

The wording matters. I’d frame the preference as something like **“Email me when push notifications aren’t available”**, not **“Email me if the app is offloaded.”** That keeps the product behavior tied to something you can actually observe rather than something iOS won’t reliably reveal.

There’s one more limitation: APNs success does **not** mean “the user definitely saw this notification.” A successful provider response mainly means APNs accepted the notification request; it is not a read receipt or guaranteed-delivery receipt. So you shouldn’t switch to email merely because you haven’t heard back from the app. ([Apple Developer](https://developer.apple.com/documentation/usernotifications/setting-up-a-remote-notification-server?utm_source=chatgpt.com))

So for the roadmap, I’d define the eventual behavior as: **push is primary; email can be an explicit secondary or fallback channel; confirmed-invalid push tokens trigger fallback when email permission exists.** That gives you most of what you want without pretending we can detect offloading itself.

---

# you asked

message time: 2026-08-30 12:04:25

Please write up all these ideas to be included in Product Revolution Roadmap.

---

# chatgpt response

Here’s a roadmap-ready section that treats these as one coherent feature area rather than four unrelated additions. I’m assuming “Product Revolution Roadmap” was an autocorrect for **Product Evolution Roadmap**. 😄

**Document Title: **

## Notification, Reminder, and Delivery Enhancements

### Goal

Expand NextSeason from a service that simply detects changes and sends a one-time notification into one that helps users **remember** the shows they are waiting for.

NextSeason should not require frequent engagement. A user should be able to configure a watchlist and largely forget about the app while NextSeason continues doing its job. These features should therefore focus on useful reminders and reliable delivery rather than driving users back into the app.

### Repeatable Reminders

Allow users to request a reminder after receiving a show notification.

A notification action such as **Remind Me** should provide convenient choices for when the user wants to be reminded again, rather than requiring the user to act on a notification immediately.

Possible options include:

- Later today
- Tomorrow
- This weekend
- Custom date/time

Consider whether users should also be able to establish default reminder behavior in Settings, including recurring reminders or preferred reminder intervals.

The objective is to handle the common situation in which a user receives a notification while busy, acknowledges it mentally, and subsequently forgets about it.

### Email Delivery

Add email as an optional notification delivery channel.

Users who provide an email address and explicitly opt in should be able to choose among:

- Push notifications
- Email
- Push notifications and email

Email provides a persistent alternative to transient push notifications: effectively an electronic Post-it note that remains available until the user deals with it.

Email delivery will require supporting backend infrastructure, including address verification, delivery management, unsubscribe handling, bounce handling, and appropriate privacy-policy disclosures. This feature should therefore follow or be developed alongside server-side notification infrastructure.

#### Email as a Delivery Fallback

Support email as an optional backup when push notification delivery is no longer available.

iOS does not provide a reliable way for NextSeason or its server to determine that the app has been offloaded. APNs may eventually report that a device token is no longer valid, but this cannot reliably be interpreted as proof that the app was offloaded.

Therefore, fallback behavior should be based on **notification availability**, not an inferred app state.

If:

1. The user has explicitly opted into email fallback, and
2. The backend receives a definitive indication that the registered push token is no longer valid,

NextSeason may deliver important notifications through email instead.

The user-facing setting should describe the behavior in terms such as **“Email me when push notifications aren't available”**, rather than suggesting that NextSeason can detect whether the app has been offloaded.

A successful APNs submission should not be treated as proof that the user received or saw the notification, so lack of subsequent app activity should not by itself trigger an email fallback.

### Periodic Watchlist Reports

Allow users to opt into periodic summaries of their watchlist.

The purpose is not to manufacture engagement or encourage unnecessary app launches. Instead, the report should reassure users that NextSeason is still monitoring their shows, remind them that the service exists, and provide useful information without requiring them to open the app.

A report might summarize information such as:

- Shows currently airing
- Shows returning soon
- Shows announced without a premiere date
- Shows still awaiting renewal/status information
- Shows that have ended

Where practical, the useful information should appear directly in the notification or email rather than requiring the user to open NextSeason.

Possible frequencies include:

- Weekly
- Monthly
- Off

Periodic reports should be opt-in. Users who prefer NextSeason to remain completely silent until something relevant changes should be able to use it that way.

Eventually, periodic reports could be available as push notifications, email digests, or both.

### Settings

These features create enough persistent user preferences to justify adding a dedicated **Settings** interface.

Settings may eventually include:

**Notifications**
- Notification status
- Reminder preferences
- Default reminder behavior
- Periodic watchlist report frequency

**Email**
- Email address
- Email verification status
- Delivery preference
- Email fallback preference

**Watchlist Reports**
- Enabled/disabled
- Frequency
- Preferred delivery method
- Potentially preferred delivery day/time

Settings should remain distinct from **About NextSeason**. Settings controls how NextSeason behaves for the user; About provides information about the app, support options, version information, diagnostics, and related application-level information.

### Resilience to App Offloading and Long Periods Without Launch

NextSeason's usage model makes it particularly susceptible to iOS's **Offload Unused Apps** feature. A satisfied user may legitimately go months without opening NextSeason.

The product should therefore be designed so that infrequent app launches do not prevent NextSeason from performing its core function.

The server-side notification architecture should have an explicit requirement that, to the greatest extent supported by iOS and APNs:

> A user who has configured NextSeason should continue receiving requested show-status notifications without periodically launching the app.

An offloaded application cannot perform background refreshes, discover new show information locally, or schedule new local notifications. This makes server-side change detection and remote notifications important not only for notification reliability but also for compatibility with NextSeason's intentionally low-engagement usage model.

As part of server-side notification development, explicitly test APNs behavior with NextSeason manually offloaded on supported iOS versions. Apple's APIs do not provide a reliable offload-state signal, so the architecture should not depend on detecting offloading itself.

Previously scheduled local notifications may continue to be managed by iOS, but they should not be considered a substitute for server-side monitoring because an offloaded NextSeason cannot discover subsequent changes or schedule new notifications.

### Product Principle

These capabilities should follow a common principle:

> **NextSeason shouldn't merely notify users. It should help them remember.**

Success should not be measured by how frequently NextSeason persuades users to reopen the app. With no advertising model requiring repeated engagement, unnecessary app launches have little inherent value.

A user who rarely opens NextSeason because it reliably monitors their watchlist, reminds them when appropriate, and delivers information through the channel they prefer is using the product exactly as intended.

---

# you asked

message time: 2026-08-30 13:37:23

That doesn't really fit the style of Product Evolution Roadmap.  Can you look over the file and make this into more of an outline like the other sections there?

---

# chatgpt response

Yes. Looking at the actual roadmap, my previous version was **far too much of a mini-spec**. The roadmap generally names the capability, gives a sentence or two of context where necessary, and then lists the important possibilities/constraints.

I’d also integrate these ideas into the existing **Notification Enhancements** and **Monitoring & Notifications** sections rather than creating one large new section.

Here’s text that matches the existing style much better:

**Document Title: **

## Notification Enhancements

- Global notification preferences.
- Per-show preferences.
- Quiet hours.
- Notification history.
- Additional notification categories.
- Allow users to request a reminder from a show notification when they cannot act on it immediately.
  - Offer convenient intervals such as later today, tomorrow, or this weekend.
  - Consider custom and/or recurring reminder options if useful.
- Support email as an optional notification channel.
  - Allow users to choose push notifications, email, or both.
  - Allow users to opt into email as a fallback when push notification delivery is known to be unavailable.
- Offer optional periodic watchlist status reports.
  - Summarize the current status of tracked shows.
  - Support an appropriate cadence such as weekly or monthly.
  - Deliver useful information directly in the notification or email rather than requiring an app launch.
  - Keep periodic reports opt-in; users should be able to hear from NextSeason only when something changes.

These features should help users remember information they asked NextSeason to track without creating artificial reasons to reopen the app.

Consider adding a dedicated Settings screen as notification, email, and other global preferences become substantial enough to warrant one.

# Platform Features

[...]

## Monitoring & Notifications

- Move season monitoring to a backend service.
- Monitor each relevant show centrally rather than independently polling the same show for every user who tracks it.
- Detect meaningful season and release-date changes on the server and fan notifications out to users who track the affected show.
- Deliver reliable push notifications through Apple Push Notification service (APNs), even when the app is not running.
- Reduce dependence on background app refresh.
- Keep notification delivery consistent across all of a user’s devices and avoid confusing duplicate notifications.
- Minimize battery impact by performing monitoring on the server whenever possible.
- Design backend monitoring and cloud sync together so the server can determine which users should receive notifications without unnecessarily duplicating or exposing user data.
- Design monitoring to remain useful during long periods when the user does not launch the app.
- Account for iOS potentially offloading NextSeason when Offload Unused Apps is enabled.
  - Do not depend on detecting whether the app has been offloaded; iOS does not provide a reliable offload-state signal.
  - Test remote notification behavior explicitly with NextSeason in the offloaded state.
  - Where the user has opted into email fallback, use email when push delivery is definitively known to be unavailable rather than attempting to infer that the app was offloaded.

One other thing jumped out at me now that I've read the whole roadmap: **“Intelligent Monitoring Experience” and these new notification ideas are really two halves of the same product philosophy.** The existing section already says NextSeason should *“quietly monitor the TV shows users care about”* and *“reinforce user confidence that the app is actively monitoring on their behalf without encouraging unnecessary engagement.”*

That's almost exactly what we independently arrived at in this conversation. So I think these additions fit the roadmap unusually well; they extend an existing principle rather than changing direction.