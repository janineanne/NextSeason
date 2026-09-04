# AI-Assisted Development Workflow

NextSeason was developed using AI as part of the engineering workflow, not as a replacement for engineering judgment. AI tools helped with planning, research, implementation, review, and documentation, while product decisions, technical direction, validation, and responsibility for the finished application remained mine (the human).

This document describes the workflow used throughout the project and complements the preserved [MVP AI transcripts](MVP/AI%20Transcripts) and [Post-MVP AI transcripts](Post-MVP/AI%20Transcripts), which provide the underlying development history.

---

## Why I Used AI-Assisted Development

NextSeason began with three goals:

1. Build a useful iOS application that solves a real problem.
2. Learn how to use modern AI tools effectively in professional software development.
3. Create a portfolio project that demonstrates not just a finished application, but the engineering process and judgment behind it.

The project was therefore intentionally structured around collaboration with AI. The objective was never to ask an AI to build an application independently. Instead, I used different tools for different kinds of work and treated their output the same way I would treat input from another engineer: useful, often productive, but subject to review and verification.

The original approach is preserved in [`ProjectKickoff.md`](MVP/ProjectKickoff.md). The workflow evolved as the application grew, but the central principle remained the same: **AI can propose and implement; I remain responsible for deciding, reviewing, testing, and shipping.**

---

# Tool Roles

## ChatGPT

ChatGPT served primarily as a planning and review partner. Its role was closest to a combination of product manager, senior engineering collaborator, and technical reviewer.

I used ChatGPT for work such as:

- Product definition and scope decisions.
- Architecture and design discussions.
- Technical and App Store research.
- Evaluating implementation approaches and tradeoffs.
- Reviewing code after implementation.
- Identifying edge cases, risks, and missing tests.
- Accessibility and Human Interface Guidelines review.
- Performance-analysis planning and interpretation.
- Release-readiness planning.
- Documentation review and drafting.
- Creating focused implementation prompts for Cursor after a direction had been agreed upon.

This separation was deliberate. For substantial changes, I often discussed the problem with ChatGPT before asking for code. That made the implementation prompt the result of an engineering decision rather than the beginning of one.

---

## Cursor

Cursor was used primarily as an implementation partner working directly with the repository.

Its work included:

- Implementing features and bug fixes.
- Refactoring existing code.
- Editing related files together when a change crossed boundaries.
- Adding and updating unit and UI tests.
- Applying changes identified during code review.
- Updating documentation associated with implementation changes.

Repository-wide guidance in [`AGENTS.md`](../AGENTS.md) defines the project's current engineering constraints, including platform versions, Swift and SwiftUI conventions, concurrency expectations, data-source responsibilities, coding style, and AI-specific instructions.

Cursor's ability to modify the codebase made it useful for implementation, but its output was not treated as authoritative simply because it compiled or looked plausible.

---

## Xcode and Apple Development Tools

Xcode remained the source of truth for whether the application actually worked.

AI output was validated using the normal iOS development toolchain, including:

- Compiler and Swift concurrency diagnostics.
- Unit tests and UI tests.
- Simulator and device testing.
- Manual functional testing.
- Accessibility testing, including VoiceOver and system accessibility settings.
- Instruments and profiling workflows.
- TestFlight builds and beta testing.

When an AI's description of expected behavior conflicted with observed behavior, the observed behavior won.

---

# Development Workflow

The exact sequence varied with the size of the task, but substantial work generally followed this pattern.

## 1. Define the Problem

I first determined what problem needed to be solved and whether it should be solved at all. This included product questions as well as technical ones.

AI was useful for exploring alternatives, but decisions about scope, user experience, priorities, monetization, and acceptable tradeoffs remained mine.

## 2. Discuss and Research

For changes with architectural, platform, or product implications, I used ChatGPT to investigate the problem before implementation. This often included reviewing existing code or documentation, checking platform behavior, comparing approaches, and identifying risks.

An important part of this step was deciding what **not** to build. AI frequently makes it easy to add complexity; the workflow deliberately favored the smallest solution that addressed a demonstrated need.

## 3. Define the Implementation

Once the direction was clear, the requirements were converted into a focused implementation task. For larger changes, ChatGPT often produced the implementation prompt that I then gave to Cursor.

Prompts included the goal, relevant context, constraints, expected behavior, testing requirements, and things that must not change. This reduced ambiguity and made the resulting code easier to evaluate.

## 4. Implement in Cursor

Cursor made the requested code and test changes in the repository. Work was intentionally kept bounded rather than asking it to redesign or rewrite large portions of the application without supervision.

Project instructions emphasize simple, maintainable Swift; avoiding unnecessary abstractions and dependencies; preserving existing behavior during refactoring; and maintaining accessibility and test coverage.

## 5. Build and Test

I built and ran the application in Xcode and performed the testing appropriate to the change. Depending on the task, that included automated tests, simulator testing, physical-device testing, accessibility checks, profiling, or TestFlight testing.

A successful AI response was never considered equivalent to a successful build or test.

## 6. Review

Significant changes were commonly returned to ChatGPT for an independent code review. The review looked for correctness problems, regressions, unnecessary complexity, missing edge cases, concurrency issues, test gaps, accessibility problems, and inconsistencies with the intended design.

When review findings were actionable, I decided which ones should be addressed and sent focused follow-up work back to Cursor. The resulting changes could then be reviewed again.

This created a useful separation between the AI doing most of the direct repository editing and the AI evaluating the result.

## 7. Human Validation and Decision

I remained the final reviewer. I tested behavior, evaluated the user experience, rejected recommendations that did not fit the product, and requested changes when an implementation was technically valid but wrong for NextSeason.

The process was iterative. Features often changed after I used them on a device, saw them with VoiceOver, received beta feedback, or simply decided that the original idea did not work as well in practice as it had on paper.

---

# Reviewing and Validating AI Output

AI-generated code and recommendations were not accepted solely because they were confidently presented or syntactically correct.

Validation included several complementary layers:

- **Code review:** inspecting the implementation and using a second AI tool to identify potential problems.
- **Compilation:** treating compiler and concurrency diagnostics as authoritative.
- **Automated testing:** maintaining unit and UI tests for behavior that can be tested reliably.
- **Manual testing:** verifying interaction and visual behavior in the simulator and on devices.
- **Accessibility testing:** checking behavior with assistive technologies and accessibility settings rather than assuming semantic code was sufficient.
- **Performance testing:** using Instruments and repeatable profiling flows where performance claims required measurement.
- **Beta testing:** using TestFlight to expose the application to real-world use outside the development environment.
- **Documentation review:** periodically comparing documentation with the current implementation so historical plans were not mistaken for current behavior.

AI also reviewed AI-generated work. That was useful, but it did not remove the need for human validation; it added another review layer.

---

# Decisions That Remained Mine

AI participated extensively in the project, but it did not own the product or the engineering decisions.

I retained responsibility for:

- What NextSeason should and should not do.
- MVP and App Store release scope.
- User experience and visual design choices.
- Architecture and acceptable technical complexity.
- Data-provider choices and how their responsibilities are divided.
- Privacy and analytics decisions.
- Accessibility expectations.
- Monetization strategy and StoreKit behavior.
- Which review findings warranted changes.
- Whether an implementation was understandable and maintainable.
- Whether testing was sufficient.
- Whether a change was ready to merge and ultimately ready to ship.

AI recommendations were sometimes accepted, sometimes modified, and sometimes rejected. Preserving those discussions is intentional because the decisions and tradeoffs are a more accurate representation of AI-assisted engineering than the generated code alone.

---

# Representative Development History

The repository preserves the AI conversations from development rather than presenting only a cleaned-up final narrative. A few useful examples are:

- **Initial development philosophy and architecture:** [`ProjectKickoff.md`](MVP/ProjectKickoff.md) and [`InitialArchitecture.md`](MVP/InitialArchitecture.md).
- **Code review:** [`7-8-2026 Indepth Code Review.md`](MVP/AI%20Transcripts/7-8-2026%20Indepth%20Code%20Review.md) followed by [`7-8-2026 Implement Items from Indepth Code Review.md`](MVP/AI%20Transcripts/7-8-2026%20Implement%20Items%20from%20Indepth%20Code%20Review.md).
- **Accessibility:** [`6-24-2026 Add Accessibility Details.md`](MVP/AI%20Transcripts/6-24-2026%20Add%20Accessibility%20Details.md) and the later [`8-30-2026 Review Accessibility Audit Suite.md`](Post-MVP/AI%20Transcripts/8-30-2026%20Review%20Accessibility%20Audit%20Suite.md).
- **Performance:** [`6-28-2026 Instruments Discussion.md`](MVP/AI%20Transcripts/6-28-2026%20Instruments%20Discussion.md), [`6-28-2026 Instruments Report Stage 1.md`](MVP/AI%20Transcripts/6-28-2026%20Instruments%20Report%20Stage%201.md), and [`6-29-2026 Instruments Report Stage 2.md`](MVP/AI%20Transcripts/6-29-2026%20Instruments%20Report%20Stage%202.md).
- **Analytics:** [`6-25-2026 Code Review and Analytics Discussion.md`](MVP/AI%20Transcripts/6-25-2026%20Code%20Review%20and%20Analytics%20Discussion.md) and [`6-25-2026 Implement Analytics.md`](MVP/AI%20Transcripts/6-25-2026%20Implement%20Analytics.md).
- **Documentation and release readiness:** [`7-20-2026 Project Code and Documentation Review.md`](MVP/AI%20Transcripts/7-20-2026%20Project%20Code%20and%20Documentation%20Review.md), [`7-29-2026 Documentation Review and Cleanup.md`](MVP/AI%20Transcripts/7-29-2026%20Documentation%20Review%20and%20Cleanup.md), and [`7-31-2026 Post-MVP Documentation Review and Cleanup.md`](MVP/AI%20Transcripts/7-31-2026%20Post-MVP%20Documentation%20Review%20and%20Cleanup.md).

These transcripts include false starts, corrections, rejected ideas, debugging, and ordinary questions as well as successful implementations. That is deliberate. The goal is to show the actual development process rather than imply that AI produced correct answers on the first attempt.

---

# Lessons from the Workflow

Several practices proved consistently useful during development:

- Discuss the problem before generating code when the decision matters.
- Give implementation agents narrow, explicit tasks and constraints.
- Use AI tools with different roles rather than treating one model as the sole authority.
- Review generated code just as seriously as human-written code.
- Test claims about platform behavior instead of trusting plausible explanations.
- Prefer simple solutions; AI can generate abstractions faster than a project needs them.
- Keep the human developer responsible for product judgment and final technical decisions.
- Preserve the reasoning behind changes, not only the resulting code.

The result is a workflow in which AI substantially increases the amount of research, implementation, and review that one developer can perform, while responsibility for the software remains unambiguously human.
