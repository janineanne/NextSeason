# Development Log
Entries written by human hands

## Entry Template
1. Problem being solved
2. Prompting approach used
3. AI output accepted
4. AI output rejected or modified
5. Human engineering judgment applied

## June 13th, 2026
1. Problem being solved
	- Xcode creates an empty directory for the Cursor Rules group
2. Solution: after several tries ChatGPT figured out how to get tot the hidden menu item I needed:
	1. Choose 'Add Files to project root'
	2. Hold down commend-shift-. to show the .cursor folder
	3. Choose files to add
	4. Select the files from the project navigator
	5. Right click on the selection and hold down option key
	6. Choose 'New Group From Selection Without Folder'
	7. Rename folder in project navigator

## June 13th, 2026 — Phase 1 product definition
1. Problem being solved
	- Define product scope before writing code (Phase 1 of ProjectKickoff workflow)
2. Prompting approach used
	- Read ProjectKickoff; clarified MVP slice and notification model via structured questions
3. AI output accepted
	- v0.1 = guest search only (look up show, see next-season status/date)
	- Future path = accounts, saved watchlist, 12-hour TVMaze polling, push on status change
	- ProductSpec.md structure and non-goals list
4. AI output rejected or modified
	- Removed widgets, sharing, and recommendations from any planned-scope list — not intended now
5. Human engineering judgment applied
	- Start small (guest search) but keep full core loop in mind for near-term follow-on
	- Notifications triggered by status change after polling, not by premiere-date reminders alone
