> From: https://chatgpt.com/c/6a5fff4a-2eb4-83e8-adca-fe4b94b869ba

# you asked

message time: 2026-07-21 16:25:59

I'm starting to see more job descriptions that want people to have experience with using AI in their apps, not just using it to write them.  I would like to add something like this to NextSeason.  It's much more for portfolio reasons than because I think users need it, but if it's going to be in there it needs to be both useful and unobtrusive.  Can you think of any features that might be suitable?

---

# chatgpt response

I actually think this is worth doing, but I'd be careful about *why* you do it.

If a hiring manager sees "AI-powered" in a portfolio app, the next question is usually, "Did they bolt ChatGPT onto something, or did they identify a real problem where AI genuinely helps?" The latter is much more impressive.

For NextSeason, I'd avoid anything that requires the user to have a conversation with an LLM. That would feel out of place in a lightweight utility app. Instead, I'd look for features where AI quietly makes the app better.

Here are the ideas I think fit best, in roughly descending order.

## 1. "Should I Add This Show?" ⭐⭐⭐⭐⭐

After the user taps a search result, add a small AI-generated section:

> **Why you might like it**
>
> • Similar to *Severance* and *Silo*
>
> • Slow-burn mystery with strong character development
>
> • Already renewed through Season 3

or

> **Good fit if you enjoy**
>
> • British detective dramas
>
> • Character-driven mysteries
>
> • Limited series

This is genuinely useful because TVMaze descriptions are often terrible.

The prompt can use:

- show synopsis
- genres
- cast
- network
- runtime
- status

and generate 2–4 concise bullets.

### Why it looks good on a résumé

It demonstrates:

- prompt engineering
- structured prompting
- presenting AI output in a constrained UI
- caching
- fallbacks
- cost management

without feeling gimmicky.

---

## 2. Natural Language Search ⭐⭐⭐⭐⭐

Instead of only searching by title:

> "funny sci-fi"

> "murder mystery in Sweden"

> "shows like Ted Lasso"

> "something to watch with kids"

AI converts this into one or more TVMaze searches and ranking criteria.

Even if TVMaze doesn't directly support semantic search, you can:

1. perform several keyword searches
2. rank results using AI

This is a surprisingly realistic use case.

---

## 3. "Explain Why This Show Appeared" ⭐⭐⭐⭐☆

Suppose the search is:

> shows like Slow Horses

AI could explain:

> Included because it's another British espionage drama with dark humor and an ensemble cast.

Tiny feature.

Useful.

Shows reasoning.

---

## 4. Better Show Summaries ⭐⭐⭐⭐☆

Current descriptions can be awful.

Generate a concise summary:

> A gripping political thriller following...

instead of:

> "John returns after twenty years..."

Users often want to know whether a show is worth watching without reading a giant synopsis.

---

## 5. Spoiler-Free Recommendation Notes ⭐⭐⭐⭐☆

Generate things like:

> Best for:
>
> • fans of mystery
>
> • ensemble casts
>
> • long-running dramas

without revealing plot twists.

---

## 6. "Previously On..." ⭐⭐⭐☆☆

If someone hasn't watched a show for two years:

> Last season ended with...

This is genuinely useful but much harder because you'd need spoiler-aware summaries.

---

## 7. AI-Generated Notification Text ⭐⭐⭐☆☆

Instead of:

> New season available.

Generate:

> Season 4 of *Only Murders in the Building* premieres tomorrow.

or

> *Foundation* has been renewed for another season.

Nice, but probably not worth the complexity.

---

## 8. AI Watchlist Insights ⭐⭐⭐☆☆

Occasionally show:

> You have 12 comedies, 8 dramas and 1 documentary.

or

> Four of your watchlist shows return this fall.

This feels more like analytics than AI.

---

# What I'd avoid

### Chatbot

> "Ask NextSeason anything."

Doesn't fit the app.

---

### "Recommend me something"

You're not trying to compete with Netflix.

---

### AI-generated reviews

Adds cost without much value.

---

### Conversational assistant

It would feel bolted on.

---

# A feature I think could be surprisingly strong

One idea I haven't seen many TV apps do is:

> **Should I watch this?**

The AI gets:

- TVMaze metadata
- IMDb/TVMaze rating
- genres
- status
- episode count
- runtime
- description

and returns something like:

> **Worth watching if...**
>
> • You enjoy slow science-fiction mysteries.
> • You're okay with a deliberate pace.
> • You prefer character-driven stories over action.
>
> **Maybe skip if...**
>
> • You want a fast-paced thriller.
> • You dislike unresolved mysteries.

That's the kind of thing a person naturally wonders before committing to a series, and it feels like a thoughtful enhancement rather than an AI demo.

---

## For portfolio purposes

If your goal is to strengthen your résumé, I'd optimize less for "most impressive AI" and more for "demonstrates modern product engineering." A feature like the "Should I Add This Show?" panel is ideal because it touches many real-world concerns:

- Calling an LLM API.
- Designing prompts for consistent, bounded output.
- Caching results to control cost and latency.
- Handling failures gracefully.
- Showing loading and retry states.
- Keeping AI output concise and useful.
- Potentially using structured JSON responses rather than free text.

That gives you plenty to talk about in interviews, while also making NextSeason a slightly better product instead of an app with AI added for its own sake.

---

# you asked

message time: 2026-07-21 16:29:16

Yes, that's a good idea.  Now, are there any AI options that aren't going to cost me money every time the feature is used?

---

# chatgpt response

Absolutely, and I think this is actually the more interesting direction for NextSeason.

When people say "AI features," they often think "send everything to GPT-5." But there are really three categories:

| Approach | Ongoing cost | Privacy | Portfolio value |
|---------|-------------:|---------|-----------------|
| Cloud LLM (OpenAI, Anthropic, Gemini) | $$ | Data leaves device | High |
| Small local model | Free | Excellent | Very high |
| Apple Foundation Models / Apple Intelligence | Free (for you) | Excellent | Extremely high on iOS |

## 1. Apple Foundation Models (my favorite)

Apple has introduced on-device foundation models that apps can use directly through the system. Assuming your deployment target eventually supports them (currently the newest OS releases), this is almost tailor-made for what you're describing.

Advantages:

- No API bill.
- No backend.
- Works offline (for supported tasks/models).
- Privacy-friendly.
- Shows employers you know Apple's modern AI stack.

For example:

```
Generate three bullet points explaining who would enjoy this TV show.
```

or

```
Summarize this show's premise in 40 words.
```

This is almost exactly the kind of constrained generation these models are good at.

For someone interviewing iOS developers in the next few years, seeing "Uses Apple's Foundation Models framework" on a résumé is likely to be a plus.

---

## 2. Ship a tiny local LLM

You could bundle a model such as:

- Gemma 3n
- Phi-3 Mini
- Qwen 2.5 (small variants)
- SmolLM

using Apple's ML stack.

Pros:

- Completely free after download.
- Works offline.
- No rate limits.
- No API keys.

Cons:

- App size increases.
- Slower on older phones.
- More engineering work.

For NextSeason, this is probably more work than it's worth.

---

## 3. Use embeddings instead of generation

This is one many people overlook.

Instead of asking an LLM every time:

> "Recommend shows like Ted Lasso"

you precompute embeddings for every show.

Then the app can answer:

- similar shows
- genre similarity
- mood similarity
- semantic search

without ever calling an LLM.

The heavy AI work happened once during preprocessing.

Runtime cost:

**$0**

This is how many recommendation systems work.

---

## 4. Build an on-device classifier

Instead of asking:

> "Who would like this?"

you can train a Core ML model to predict things like:

- family-friendly
- slow burn
- dark
- lighthearted
- serialized
- bingeable

No LLM required.

Not as flashy, but still genuine machine learning.

---

## 5. Generate everything ahead of time

If every show only needs one AI summary...

Generate it once.

Store it.

Ship it.

Every user sees the same generated text.

Your runtime cost becomes:

```
$0
```

after preprocessing.

This is especially attractive because TV shows don't change very often.

---

# A hybrid approach I'd seriously consider

Because NextSeason is essentially a TV metadata app, you don't actually need AI to think in real time.

Imagine this pipeline:

```
TVMaze data
      │
      ▼
Offline AI generation
      │
      ├── 40-word summary
      ├── Why watch it
      ├── Similar audiences
      ├── Tone
      ├── Pacing
      ├── Family friendliness
      ▼
Store with show
      ▼
App displays instantly
```

The app itself never calls an LLM.

The AI work happened during content preparation.

---

# If I were optimizing for your résumé

Knowing your goals, I'd actually lean toward **Apple's Foundation Models** over a cloud API.

Here's why:

- You're targeting iOS roles.
- Apple is pushing on-device AI heavily.
- It avoids introducing backend infrastructure into a deliberately simple app.
- You can talk about integrating modern Apple AI APIs, prompt design, structured outputs, graceful fallback, and privacy-aware UX—all without incurring per-user costs.

One caveat is deployment target. If you want NextSeason to support older iOS versions (which is generally a good idea for an App Store utility), you could make the feature conditional:

- On supported devices and OS versions: use Apple's on-device foundation model.
- Otherwise: hide the AI panel or show the original TVMaze description.

That gives you a clean, maintainable implementation while still demonstrating current AI integration in your portfolio. Given everything we've discussed about NextSeason, that strikes me as the best balance between engineering value, user value, and long-term maintenance.

---

# you asked

message time: 2026-07-21 16:31:14

Yes, I agree.  Thanks!

---

# chatgpt response

I think it also fits nicely with the philosophy we've developed for NextSeason over the past month.

One thing I've noticed is that we've consistently rejected features that feel like they exist because they're technically interesting rather than because they solve a problem. This approach is the same: AI is there to remove friction, not to become the focus of the app.

If you do add it, I'd probably keep it to a single section on the Show Details screen. Something like:

> **AI Insights**
>
> • Great for fans of character-driven sci-fi mysteries.
>
> • Slow pacing, but rewarding if you enjoy world-building.
>
> • Already renewed, so you won't be left on a cliffhanger.

Three short bullets are enough. If the feature disappeared tomorrow, the app would still be perfectly usable—that's usually a sign that it's additive rather than intrusive.

One other thought for your portfolio: don't undersell the engineering work. The interesting part isn't "I called an AI API." It's the surrounding design:

- Detect whether on-device AI is available.
- Fall back gracefully when it isn't.
- Keep the UI responsive while generation happens.
- Cache the generated output so it only runs once per show.
- Invalidate the cache if the show's metadata changes.
- Bound the output with structured prompts (or structured generation) so it always fits the UI.
- Handle failures without exposing AI jargon or errors to the user.

Those are exactly the kinds of engineering decisions interviewers tend to ask about.

And one last suggestion: I'd leave this until after the App Store release. Your roadmap already separates "App Store readiness" from "Product evolution," and this fits squarely in the latter. It won't materially improve your chances of getting approved, but it *will* give you something fresh to talk about in interviews and a nice update to post on LinkedIn:

> "I wanted to explore Apple's new on-device Foundation Models, so I added AI-generated viewing insights to NextSeason. The feature runs locally, preserves user privacy, and adds a little context without getting in the way."

That's the kind of post that demonstrates curiosity and modern iOS development without sounding like you're chasing the latest buzzword.

---

# you asked

message time: 2026-07-21 16:36:09

Here's the post-App Store roadmap.  Please add the AI feature we've been discussing.

---

# chatgpt response

I think this fits very naturally into the roadmap, and I intentionally kept it aligned with the product principles we've established:

- It emphasizes **Apple's on-device Foundation Models** rather than cloud AI.
- It focuses on **helping users decide whether to add a show**, not on recommendations or chat.
- It includes implementation guidance (caching, fallback, privacy) rather than just the feature idea.
- It remains explicitly **optional and unobtrusive**, which matches the overall philosophy of NextSeason.

I inserted a new section titled **"AI-Assisted Show Insights"** just before **Platform Features**, since it represents a product capability rather than infrastructure.

You can download the updated roadmap here:

[**📄 NextSeason - Product Evolution Roadmap - AI.md**](sandbox:/mnt/data/NextSeason%20-%20Product%20Evolution%20Roadmap%20-%20AI.md)

One small suggestion I'd consider after you've lived with it for a few days: we might add a short note that this feature is **conditional on OS support** (for example, "Available on supported versions of iOS"). That makes it clear to future readers—and potential employers—that the design intentionally degrades gracefully on older devices.

---

# you asked

message time: 2026-07-21 16:40:14

Go ahead and add that now, so we (I) don't forget.

---

# chatgpt response

Done! I added an explicit roadmap item to make sure the feature degrades gracefully:

> **Clearly identify this as a feature available only on supported versions of iOS, ensuring the app continues to provide a complete experience on older devices.**

I like this wording because it frames the limitation as a deliberate product decision rather than a technical constraint.

You can download the updated version here:

[**📄 NextSeason - Product Evolution Roadmap - AI v2.md**](sandbox:/mnt/data/NextSeason%20-%20Product%20Evolution%20Roadmap%20-%20AI%20v2.md)

One additional thought for the future: if you do end up implementing this, I'd also add a brief note to your README along the lines of:

> *"Uses Apple's on-device Foundation Models (when available) to generate concise, privacy-preserving viewing insights, with automatic fallback on unsupported devices."*

That's exactly the sort of sentence that catches the eye of an iOS hiring manager skimming a GitHub project.

---
Powered by [AI Exporter](https://saveai.net)