# ProjectKickoff Phase 1 discussion

## User

Read ProjectKickoff
We're on Phase 1

## Assistant

I'll read ProjectKickoff and scan the repo so we can align on Phase 1 scope.

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Development Documentation/ProjectKickoff.md"}
```

### Tool Glob File Search

```
{"targetDirectory":"/Users/janine/Documents/TbF Projects/NextSeason","globPattern":"**/*.{swift,md}"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Development Documentation/DevelopmentLog.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/README.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/AGENTS.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Development Documentation/Prompts.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/NextSeason/ContentView.swift"}
```

## Assistant

ProjectKickoff puts us in Phase 1 (product definition, no code). AGENTS.md has a rough direction; I'll ask two decisions that shape the MVP spec before drafting the plan.

### Tool Ask Question

## User

Let's start with A, but keep C in mind since we will be going there soon.

When we get to the point where users can save shows to keep an eye on, then we will be polling TVMaze, probably once ever 12 hours or so, and then notifying the user if the next-season status of any of their saved shows has changed.

## Assistant

Incorporating your MVP choice (guest search first, full loop later) and the polling-based notification model into the Phase 1 plan.

### Tool Create Plan

## User

please remove "Widgets, sharing, recommendations" from the list of items that are documented as planned - none of these are intended to be in scope right now.  That could change in the future but don't waste any time on it now.

### Tool Read File V2

```
{"path":"/Users/janine/.cursor/plans/phase_1_product_definition_26919850.plan.md"}
```

### Tool Edit File V2

## Assistant

Updated the plan. The v0.1 "planned next" list now only covers the intentional path toward the full core loop:

- User accounts / Sign in with Apple
- Saved watchlist
- Push notifications
- Background polling

Widgets, sharing, and recommendations are removed entirely — not documented as planned, not called out as non-goals. We won't spend time on them unless you revisit that later.

## User

OK, this looks good

## Assistant

Executing the plan: drafting `ProductSpec.md` and adding the Phase 1 decision to the development log.

### Tool Read File V2

```
{"path":"/Users/janine/.cursor/plans/phase_1_product_definition_26919850.plan.md"}
```

### Tool Read File V2

```
{"path":"/Users/janine/Documents/TbF Projects/NextSeason/Development Documentation/DevelopmentLog.md"}
```

### Tool Edit File V2

### Tool Edit File V2

### Tool Edit File V2

## Assistant

Phase 1 is done. Two documents were added/updated:

**Created:** [Development Documentation/ProductSpec.md](Development Documentation/ProductSpec.md)
- Target user, problem statement, v0.1 scope (guest search only)
- Planned next: accounts, watchlist, polling, notifications
- Project-wide non-goals
- Future notification model (12-hour polling, notify on status change)
- Phase 2 open questions and v0.1 success criteria

**Updated:** [Development Documentation/DevelopmentLog.md](Development Documentation/DevelopmentLog.md)
- New entry capturing today's decisions, including your rejection of widgets/sharing/recommendations from planned scope

**Phase 1 complete.** No code was written, per the kickoff workflow.

**Next up — Phase 2:** TVMaze research (`TVMazeResearch.md`) to answer what next-season fields are actually available and how reliable they are. Say when you want to start that.
