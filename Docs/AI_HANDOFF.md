# AI Handoff - Derples vs Xenos (DVX-html5)

## Path Lock (Critical)
- **Only valid working project path:** `/Users/alexscarrow/Desktop/DVX/DVX-html5`
- Do **not** read/write/edit any files outside this path.
- Before any code edits, assistant must state:
  - `Working in: /Users/alexscarrow/Desktop/DVX/DVX-html5`

---

## Project Identity
- Defold project title in `game.project`: `Derples vs Xenos`
- Folder name can differ from project title.
- Active authoritative repo for current work: `DVX-html5`.

---

## Collaboration Workflow We Use
- We iterate in **small, reversible steps**.
- We validate quickly in-engine (solo + multiplayer smoke tests).
- We avoid risky broad refactors without checkpointing.
- We keep multiplayer changes **host-authoritative first** (reliability over cleverness).
- We only commit when explicitly requested by user.
- We treat local “stable states” as **banked** milestones.

### “Bank” Terminology
- **Bank / bank this** = the current local code state is accepted as stable.
- It does **not always mean git commit** unless explicitly requested.
- It means “safe known-good point we can return to.”

---

## Git Safety Protocol (How assistant should operate)
- Run read-only checks frequently:
  - `git status --short`
  - `git diff` (targeted files)
- Never use destructive commands unless explicitly requested:
  - avoid `reset --hard`, `checkout --`, force push, etc.
- Never commit unless user explicitly asks.
- Never amend unless explicitly asked (or strict hook-only exception and still user-safe).
- Preserve unrelated dirty worktree changes.

---

## Multiplayer Architecture Direction
- Host-authoritative listen-server model.
- Host is always `p1` (Sarge).
- Host owns progression (`New Turn` gate logic), others send readiness/actions.
- Transport abstraction in place (loopback + websocket direction).
- Relay backend direction: small Node.js websocket relay.

---

## “Fake Multiplayer” Methodology Used For Testing
- Local simulation of remote players (`p2`, `p3`, `p4`) via debug controls.
- URL/query or debug active-player switching used to emulate different clients.
- Seat model assigns ownership by player ID; local testing switches command authority accordingly.
- Purpose: test turn/ready/authority flow without requiring live remote peers.

---

## Current Main Goal (Next Big Objective)
- Move from simulated/local multiplayer to **real internet multiplayer test** with a friend.
- Goal criteria:
  - two real remote clients connect via relay
  - host-authoritative gameplay remains stable
  - turn/state sync remains correct
  - reconnection/fallback behavior is understandable in logs/UI

---

## Balancing/Systems Direction
- Human AP costs centralized in `main/config.lua` (`AP_COSTS`).
- Alien tuning migration in progress:
  - config-driven alien stats/weights
  - one shared alien AP budget per turn across movement + ranged + melee
  - preserve host-authoritative multiplayer safety

---

## Known Technical Risk
- `main/game.script` is large and can hit Defold/Lua local-variable compile ceiling:
  - `Compilation failed: main function has more than 200 local variables`
- Mitigation:
  - avoid adding many new top-level `local` declarations in `game.script`
  - move logic to runtime modules where possible
  - keep edits scoped and verify compile after each substantial change

---

## Incident Log (Important Context / Operator Anxiety)
### Workspace Confusion Incident
- Two similarly named project folders existed in parallel.
- Edits were accidentally split across both folders during one session.
- Result: confusion, invalid path errors, mismatch between reported line numbers and file lengths.

### “Lost You” Incident
- User renamed active workspace folder while session was live.
- Cursor workspace appeared blank.
- Agent context appeared reset and asked what project to start.
- User experienced severe panic and restored folder name.

### Required Behavioral Response Going Forward
- Assistant must be explicit about active path before edits.
- If any ambiguity appears (line numbers/path mismatch), assistant must stop and confirm.
- Prefer one active Cursor window + one active repo during implementation sessions.

---

## Session Start Protocol (for any new AI session)
1. Read `docs/AI_HANDOFF.md`.
2. Confirm path lock in first response.
3. Run read-only sanity checks first:
   - `git status --short`
   - identify dirty files
4. Ask for confirmation before risky cross-file refactors.
5. Keep changes scoped, testable, and reversible.

---

## Quick Bootstrap Prompt (User can paste at start of any new chat)
`Read docs/AI_HANDOFF.md first. Path lock is /Users/alexscarrow/Desktop/DVX/DVX-html5 only. Do not edit any other project path. Confirm current git status before making changes.`

---

## Immediate TODO (editable)
- [ ] Continue/verify unified alien AP-budget implementation safely
- [ ] Keep `main/game.script` below local-variable compile pressure
- [ ] Prepare and execute first genuine remote multiplayer test