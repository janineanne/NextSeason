> From: https://chatgpt.com/c/6a72506d-89f4-83e8-ac76-d090c445b40f

# you asked

message time: 2026-08-04 13:50:23

Do we already have a document describing how much of the About/Diagnostics screens will be staying on past the end of the beta phase?

---

# chatgpt response

Yes, although it's spread across a couple of documents rather than being collected in one place.

The clearest statement is actually in **Post-MVP Roadmap.md**:

> "Transition the Diagnostics screen from a beta testing tool into a production support feature. Remove developer-only actions while retaining user-visible status information and the ability to generate or send a diagnostic report for troubleshooting." 

The more detailed implementation document, **MVPAnalytics.md**, describes the current beta implementation:

- `DiagnosticsView` is explicitly described as a **beta diagnostics screen**.
- It currently contains **Copy** and **Share** actions.
- It exposes analytics counters and other diagnostic information for TestFlight users. 

What I *don't* see is a document that explicitly says, item by item:

| UI Element | Beta | Production |
|------------|------|------------|
| About screen | Keep | Keep |
| Version number | Keep | Keep |
| Diagnostics access | Hidden long-press | ? |
| Analytics counters | Keep | Remove? |
| Copy diagnostics | Keep | Keep |
| Share diagnostics | Keep | Keep |
| Force Refresh | Remove | Remove |
| Test Notification | Remove | Remove |
| Other developer actions | Remove | Remove |

That decision matrix doesn't appear to exist yet.

Given where the project is now, I think it would be worthwhile to add a short section—either to the **App Store Readiness Roadmap** or the **Post-MVP Roadmap**—called something like **Production About & Diagnostics Screen** that lists exactly what survives after beta. That would become the definitive checklist when you prepare the App Store build.

---

# you asked

message time: 2026-08-04 13:51:34

Can you write that, please?

---

# chatgpt response

Certainly. I think this fits best in the **App Store Readiness Roadmap** because it's part of the work required to prepare the production build rather than a future feature.

**Document Title: **

## Production About & Diagnostics Screen

The About and Diagnostics screens will remain part of NextSeason TV after the beta period, but their purpose will shift from developer testing to user support and troubleshooting.

### About Screen

The About screen should remain available to all users and continue to include:

- Application name and version number
- Build number
- Attribution and acknowledgements (including TVMaze)
- Links to privacy policy, support, and other user-facing resources
- Notification guidance, if still applicable

### Diagnostics Screen

The Diagnostics screen should remain available as a lightweight support tool for production users.

Retain:

- Current application version/build
- Last successful refresh time
- Next scheduled refresh window (if available)
- Most recent refresh result
- Current notification authorization status
- Other non-sensitive status information useful for troubleshooting
- Copy Diagnostics
- Share Diagnostics

Remove beta-only functionality:

- Force Refresh
- Test Notification
- Simulated Update
- Any other controls intended only for development or TestFlight validation

### Analytics Information

Internal analytics counters used during beta testing should not be displayed in production builds unless they continue to provide meaningful value for customer support.

If retained, they should be presented in a user-friendly way. Otherwise, they should remain internal only.

### Support Report

The diagnostics report should continue to provide enough information to assist in troubleshooting user issues while avoiding the inclusion of personal data or sensitive information.

The report should contain only information that is safe for users to review and share with support.

### Goal

The production Diagnostics screen should answer the common support question:

> "Why didn't I receive a notification?"

without exposing implementation details that are only useful during development.

I think this also gives you a good architectural target: the Diagnostics screen becomes a **customer support feature** rather than a **developer tool**. That distinction should make future decisions about what belongs there much easier.

---
Powered by [AI Exporter](https://saveai.net)