> From: https://chatgpt.com/c/6a6e4eb8-629c-83e8-8da1-31d42f470c0e

# you asked

message time: 2026-08-01 12:54:21

I'm working on reviewing all the Swift code.  I see a few uses of fatalError and I remember you saying that I needed to change those, but I don't see them in either the pre or post AppStore roadmaps.  Where should this go, and what should it say?

---

# chatgpt response

This belongs in the **App Store Readiness Roadmap**, under a section such as **Reliability and Error Handling** or **Code Quality and Production Hardening**. It should be completed before submission because any reachable `fatalError` can terminate the app without giving the user a way to recover.

I would add something like:

> **Audit and eliminate production-reachable `fatalError` calls**
>
> Review every use of `fatalError`, `preconditionFailure`, and similar deliberate crash mechanisms. Replace any that could be reached because of malformed data, persistence problems, API responses, migration failures, or other runtime conditions with recoverable error handling, safe fallback behavior, and appropriate logging. Retain deliberate crashes only for genuinely impossible programmer errors, and document why each remaining use is safe.

A shorter checklist-style version:

> - [ ] Audit all `fatalError`, `preconditionFailure`, and forced assumptions. Replace production-reachable crashes with recoverable errors or safe fallbacks; document any deliberate crashes that remain.

I would place it near other final code-review tasks, before the testing and App Store submission sections. It is not really a post-MVP enhancement; it is production-hardening work required before release.

One important distinction: you do **not necessarily need to remove every `fatalError`**. For example, one used only in a test mock, a preview configuration, or an initializer that cannot be called incorrectly without a programming bug may be reasonable. But anything that might happen because TVMaze returned unexpected data, stored data became corrupt, dependency setup failed, or the user reached an unusual state should not crash the shipping app.

---
Powered by [AI Exporter](https://saveai.net)