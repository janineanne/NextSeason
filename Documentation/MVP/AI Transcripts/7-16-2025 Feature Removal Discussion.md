> From: https://chatgpt.com/c/6a590907-e9f8-83e8-be11-b656acff5800

# you asked

message time: 2026-07-16 09:40:32

Cursor reminded me that we have a feature that is supposed to make actor's names tappable in the About text, which brings up a "Coming Soon" alert. I think we should remove this, for two reasons.  One, we not longer have anything on the post-mvp roadmap about tracking actors, and two, I haven't seen many About texts which have actor names in them.  They are equally likely to have show character names, which isn't the same thing at all.  What do you think?

---

# chatgpt response

I think removing it is the right decision.

There are really three reasons now, not just two.

1. **It no longer aligns with the product vision.**  
   As we've refined the roadmap, NextSeason has become much more focused: it's about **tracking TV shows and notifying users when new seasons are available**. We've deliberately removed or deferred features that drift into adjacent domains, like recommendations and actor-related functionality, to keep the app laser-focused. 

2. **There's no future payoff.**  
   The "Coming Soon" alert made sense when actor tracking was a possible future feature. Now it isn't on the roadmap, so the interaction has become a tease for something that may never exist. That's generally not a great user experience.

3. **The data itself isn't reliable enough.**  
   As you point out, About text isn't consistently about actors. It often mentions:
   - character names
   - fictional places
   - production companies
   - directors
   - writers
   - or no people at all

   Trying to make "names" interactive would require reliably distinguishing actors from everyone else. That's a surprisingly difficult NLP problem, especially given that the source text is free-form.

There's also a broader design principle here that I think has guided many of our recent decisions:

> **Don't imply capabilities the app doesn't actually have.**

If something is tappable, users naturally assume it's meaningful. A "Coming Soon" alert is acceptable in a beta for a feature that's genuinely imminent, but less so for something you've consciously decided isn't part of the product anymore.

I'd actually go one step further than just removing the tap handling.

- Leave the About text as plain text.
- Remove the attributed-string machinery for actor links.
- Remove the "Coming Soon" alert.
- Remove any analytics or tests that exist solely for actor-name taps.

That simplifies the codebase a bit and eliminates a feature that no longer serves a purpose.

One final observation: this is another example of something that was a neat technical idea but doesn't materially improve the app. We've been getting better and better at recognizing those and pruning them. I think that's one of the reasons the product vision feels much clearer today than it did a month ago.

---
Powered by [AI Exporter](https://saveai.net)