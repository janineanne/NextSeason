# TV Show Tracker App - Project Kickoff
Written by ChatGPT to summarize a lengthy chat, 6-13-26

## Purpose

This project has three goals:

1. Build a useful iOS application that notifies users when new seasons of their favorite TV shows become available.
2. Learn modern AI-assisted software development workflows.
3. Create a portfolio project demonstrating the ability to effectively supervise and collaborate with AI tools during software development.

Success is not measured solely by whether the app becomes commercially successful. Learning AI-assisted development and creating a strong portfolio piece are equally important goals.

---

# AI Development Philosophy

The goal is not to have AI write the application independently.

The goal is to use AI as a collection of specialized collaborators while maintaining responsibility for:

- Product decisions
- Architecture decisions
- Code quality
- Testing strategy
- Tradeoff analysis
- Final implementation decisions

The most valuable skill is engineering judgment, not code generation.

---

# AI Tool Roles

## ChatGPT

Primary uses:

- Product planning
- Requirements gathering
- Scope reduction
- Architecture review
- Technical research
- API evaluation
- Code review
- Design discussions
- Second opinions on AI-generated solutions

Role:

- Product Manager
- Staff Engineer
- Technical Reviewer

Examples:

- Is this feature worth building?
- Is this architecture too complex?
- What are the risks of this design?
- What data source should be used?

---

## Claude (Cursor)

Primary uses:

- Writing code
- Refactoring code
- Editing multiple files
- Generating tests
- Understanding project structure
- Implementing features

Role:

- Pair Programmer
- Junior Engineer

Examples:

- Implement a feature
- Refactor existing code
- Generate tests
- Apply architectural changes

---

## Xcode

Primary uses:

- Build
- Run
- Debug
- Profile
- Simulator
- Signing
- Deployment

Role:

- Source of Truth

The application must always compile and run correctly in Xcode regardless of what any AI tool claims.

---

# Development Workflow

## Phase 1 - Product Definition

Before writing code:

- Define target user
- Define problem being solved
- Define MVP scope
- Define non-goals

Questions:

- What notification does the user actually want?
- What information is available from data providers?
- What is the smallest useful version?

---

## Phase 2 - Research

Investigate:

- TVMaze capabilities
- Notification requirements
- App Store constraints
- Data availability

Avoid implementation discussions until research is complete.

---

## Phase 3 - Architecture

Create:

- ProductSpec.md
- Architecture.md
- TVMazeResearch.md

Determine:

- Data model
- Persistence strategy
- Networking approach
- Notification architecture
- Testing strategy

Avoid coding until architecture is reasonably understood.

---

## Phase 4 - Implementation

Build small vertical slices.

Avoid prompts such as:

"Build the whole app."

Prefer:

"Implement only the show search feature."

"Implement only persistence."

"Implement only notifications."

Each feature should:

- Compile
- Be testable
- Be understandable
- Have a clear purpose

---

## Phase 5 - Review

Before accepting significant AI-generated code:

- Review architecture impact
- Review complexity
- Review accessibility
- Review testability
- Review maintainability

Ask:

"Is this solving a real problem or creating unnecessary complexity?"

---

# Prompting Guidelines

Preferred structure:

Goal:
What is being accomplished?

Context:
What does the AI need to know?

Constraints:
What must be preserved?

Output:
What form should the answer take?

Example:

Goal:
Implement TV show search.

Context:
SwiftUI app using TVMaze.

Constraints:
- SwiftUI only
- Async/await
- No third-party dependencies

Output:
Compilable Swift code with explanation.

---

# Cursor Rules Strategy

Maintain project-wide guidance through documentation.

Potential rules:

- Prefer simple SwiftUI solutions.
- Avoid premature abstraction.
- Do not introduce third-party dependencies without approval.
- Keep views small.
- Maintain accessibility.
- Preserve behavior during refactoring.
- Explain non-obvious decisions.

---

# Documentation Strategy

Repository structure:

Docs/
- ProductSpec.md
- Architecture.md
- TVMazeResearch.md
- Decisions.md
- AIDevelopmentLog.md

Prompts/
- ProductPlanning/
- Architecture/
- Networking/
- SwiftUI/
- Testing/
- Debugging/

Important AI conversations should be summarized into documents rather than relying on chat history.

---

# AI Development Log

For significant work sessions record:

Date:
Goal:
AI Tool Used:
Prompt Summary:
Outcome:
Decision:
Follow-up Work:

Example:

Date:
2026-06-13

Goal:
Determine TV data source.

AI Tool:
ChatGPT

Outcome:
Selected TVMaze for initial investigation.

Decision:
Research available season-related endpoints before designing notifications.

---

# Important Lessons

- Small prompts outperform giant prompts.
- Small features outperform large feature requests.
- Architecture should precede implementation.
- AI-generated code should always be reviewed.
- Simplicity is usually preferable to cleverness.
- Engineering judgment is the primary skill being demonstrated.

---

# Portfolio Goal

This project should demonstrate:

- SwiftUI development
- API integration
- Application architecture
- Testing practices
- AI-assisted development workflow
- Technical decision-making

The final portfolio should ideally include:

- Source code
- Product specification
- Architecture documentation
- AI development log
- Design decisions
- Examples of AI suggestions that were accepted or rejected and why
