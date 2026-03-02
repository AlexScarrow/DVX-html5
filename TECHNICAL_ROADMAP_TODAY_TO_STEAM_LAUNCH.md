# Technical Roadmap: Today to Steam Launch

## 1) Objective

Ship a stable, commercially viable PC/Steam Deck build of Derples vs Xenos with reliable multiplayer and a production-ready release pipeline.

## 2) Guiding Technical Principles

- **Host-authoritative multiplayer** for anti-desync reliability.
- **Command-based net protocol** (intent -> validation -> broadcast).
- **Deterministic-enough turn flow** with explicit state sync checkpoints.
- **Platform-first stability** before adding advanced monetization/live-ops.

## 3) Phase Plan

## Phase 0: Pre-Production Alignment (1-2 weeks)

Deliverables:

- Multiplayer technical design doc finalized.
- Feature scope locked for v1 launch.
- Risk register for networking/platform/release.

Key decisions:

- Session model: host/join with host authority.
- Ownership model: player-to-human assignment rules.
- Turn gating: host controls new turn; remote players ready up.

Exit criteria:

- Agreed message schema and state ownership boundaries.

## Phase 1: Multiplayer Core Architecture (2-4 weeks)

Deliverables:

- Network abstraction layer (transport-agnostic API).
- Session lifecycle states: Lobby -> In Match -> Post Match.
- Player identity, connection, and role assignment.

Implementation targets:

- Host receives commands only (move, action, ready, etc.).
- Host validates and applies; clients mirror resulting state/events.

Exit criteria:

- Two clients + host can complete full turn cycles without desync.

## Phase 2: Gameplay Sync and Reliability (2-4 weeks)

Deliverables:

- Snapshot + event stream sync model.
- Rejoin/reconnect support.
- Turn/state checksum diagnostics for desync detection.

Implementation targets:

- On join/rejoin: full authoritative snapshot from host.
- During play: ordered event replication.
- Recovery path for dropped packets/late joins.

Exit criteria:

- 30+ minute sessions without unrecoverable desync.

## Phase 3: UX and Multiplayer Productization (2-3 weeks)

Deliverables:

- Host/join UI.
- Lobby UI with ready states and role ownership indicators.
- Host-only `NEW TURN` gating tied to all required ready flags.

Implementation targets:

- Clear connection status and error messages.
- Input lockouts when action ownership rules are violated.

Exit criteria:

- Playtesters can host/join and understand flow without dev assistance.

## Phase 4: Steam Integration Layer (2-4 weeks)

Deliverables:

- Steam app setup and build/depot pipeline.
- Steam input/controller support pass.
- Optional Steamworks features (prioritized):
  - presence/lobby integration,
  - cloud save (if used),
  - achievements.

Implementation targets:

- Build artifacts for Windows (and Linux path if needed for Deck strategy).
- Runtime checks for Steam-enabled vs non-Steam execution.

Exit criteria:

- Internal Steam beta branch install/update/play verified.

## Phase 5: Steam Deck Readiness Pass (1-3 weeks)

Deliverables:

- UI readability pass for Deck resolution/scaling.
- Controller-only navigation pass.
- Performance and battery behavior check.
- Suspend/resume behavior validation.

Implementation targets:

- Ensure key gameplay loops are fully controller-friendly.
- Confirm no blocking desktop-only assumptions in UX.

Exit criteria:

- Deck playtest checklist fully green.

## Phase 6: QA, Hardening, Release Candidate (2-4 weeks)

Deliverables:

- Regression suite execution across:
  - solo,
  - host multiplayer,
  - client multiplayer,
  - reconnect scenarios.
- Crash/error telemetry plan.
- Day-0 patch branch readiness.

Implementation targets:

- Fix top-severity defects only near code freeze.
- Lock content and code for candidate release.

Exit criteria:

- Release candidate passes launch checklist with no blockers.

## 4) Core Technical Workstreams

### A) Networking

- Command protocol and validation.
- Event ordering and idempotency.
- Snapshot serialization/deserialization.

### B) Gameplay State Management

- Authoritative state container boundaries.
- Deterministic turn transitions and action resolution.
- Ownership and permissions.

### C) Platform and Build

- Automated builds per target.
- Steam depots/branching strategy.
- Debug vs release configuration.

### D) Quality and Observability

- Structured logs for network/gameplay events.
- Session replay/debug tooling (optional but high value).
- Error categorization for quick triage.

## 5) Launch-Critical Risks and Mitigations

### Risk: Multiplayer desync

Mitigation:

- Host-authoritative model, periodic snapshots, checksums.

### Risk: Connectivity failures in real-world networks

Mitigation:

- Robust timeout/retry flows, user-facing reconnect UX.

### Risk: Deck usability gaps

Mitigation:

- Early controller-first pass; repeated Deck playtests.

### Risk: Scope creep

Mitigation:

- Strict v1 launch scope and milestone gates.

## 6) Recommended v1 Scope Guardrails

Include:

- Host/join multiplayer.
- Ready gating + host turn advance.
- Stable core tactical loop.
- Basic Steam platform integration.

Exclude (post-launch):

- Complex ranking ladders.
- Real-money systems.
- Extensive live-ops backend.

## 7) Suggested Milestone Artifacts

Each phase should produce:

- short technical note (what changed),
- test checklist results,
- known issues list,
- go/no-go decision.

## 8) Immediate Next Steps (This Week)

1. Create multiplayer architecture doc (message schema + ownership rules).
2. Implement local "mock multiplayer mode" to validate command/state boundaries.
3. Define Steam launch MVP checklist and cut non-essential features.
4. Prepare branch strategy:
   - `feature/multiplayer-core`
   - `feature/steam-integration`
   - `release/steam-v1`

---

Owner: Engineering  
Version: v1  
Purpose: Execution roadmap from current codebase to Steam release
