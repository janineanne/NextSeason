# NextSeason Mermaid Diagrams

This folder contains Mermaid-based architecture and flow diagrams for the NextSeason project.

These diagrams are intentionally documentation-oriented rather than code-generated. They are meant to explain how the app works, why the MVP is scoped the way it is, and how the architecture can grow after MVP.

## Files

- `01_system_architecture.md` — High-level MVP architecture
- `02_user_flows.md` — User-facing flows
- `03_search_flow.md` — Show search and TVMaze interaction
- `04_watchlist_flow.md` — Add/remove watchlist behavior
- `05_season_calculation_flow.md` — How the app reasons about season status
- `06_data_model.md` — Core conceptual data model
- `07_post_mvp_architecture.md` — Future architecture after accounts, cloud sync, and push notifications (local notifications are MVP; see `01_system_architecture.md`)
- `08_decision_context.md` — Scope and decision rationale

## Notes

These diagrams assume the current MVP approach:

- SwiftUI iOS app
- TVMaze as the external show data source
- Local-only watchlist persistence
- Local notifications when season status changes (on-device scheduling)
- No login/accounts in MVP
- Push/cloud notifications and account sync are post-MVP (see `07_post_mvp_architecture.md`)
