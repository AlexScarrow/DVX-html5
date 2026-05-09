# Multiplayer Sync Bug Log

This file tracks multiplayer sync-related issues found during remote and LAN tests.

---

## Session Baseline

- Date: 2026-05-09
- Test type: Remote internet test (host + friend client)
- Result: Full match completed successfully
- Notes: Core host/join/start path is stable; minor sync bugs reported for follow-up

---

## Open Bugs

Use one block per bug:

```text
ID: MP-SYNC-00X
Title:
Severity: P0 / P1 / P2
Area: Lobby / Setup / In-match / Outro / UI
Host/Client/Both:
Expected:
Actual:
Repro steps:
Frequency: once / sometimes / always
Evidence: screenshot/video/log snippet
Status: Open / In Progress / Fixed / Verify
Owner:
Notes:
```

---

## Entries

<!-- Add new bugs below this line -->

```text
ID: MP-SYNC-001
Title: Client pickup of gun turret can vanish without entering backpack
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Picked item appears in client backpack and syncs to host.
Actual: Turret pickup acknowledged but item disappears from world and backpack.
Repro steps: Client picks up gun turret during mission.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Check authoritative item transfer + inventory reconcile path for client pickups.
```

```text
ID: MP-SYNC-002
Title: Client needs multiple clicks to release civilians
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Single valid release interaction resolves action.
Actual: Multiple clicks required before release succeeds.
Repro steps: Client attempts civilian release interaction in mission.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: May share root cause with command reject/retry or stale target validation.
```

```text
ID: MP-SYNC-003
Title: Dead civilians appear on exterior tiles in rescue mission
Severity: P1
Area: In-match
Host/Client/Both: Both
Expected: Exterior tiles excluded from civilian spawn candidates.
Actual: Dead civilians appear on exterior tile positions.
Repro steps: Play rescue mission and observe civilian spawn/death placement.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Likely mission spawn rules issue; not necessarily network-specific.
```

```text
ID: MP-SYNC-004
Title: Client cannot apply meds from medic to techie reliably
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Med transfer applies and health increases after valid drag/drop.
Actual: UI acknowledges action but no health-up occurs.
Repro steps: Client drags meds from medic context onto techie.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Validate command acceptance and heal application echo on client.
```

```text
ID: MP-SYNC-005
Title: Simultaneous human movement causes visual glitching
Severity: P1
Area: In-match
Host/Client/Both: Both
Expected: Concurrent movement interpolates smoothly.
Actual: Movement glitching/jitter visible on host and client.
Repro steps: Move multiple humans at same time.
Frequency: sometimes
Evidence: tester report; also present in solo
Status: Open
Owner: Unassigned
Notes: Likely core interpolation/timing issue, not only net-sync.
```

```text
ID: MP-SYNC-006
Title: Client does not see host unit projectiles
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Client sees ranged projectile visuals for host shots.
Actual: No projectile visual cue on client for host firing.
Repro steps: Host fires ranged weapon while client observes.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Check broadcast/apply path for realtime projectile events.
```

```text
ID: MP-SYNC-007
Title: Dead brute impact ring missing on client
Severity: P2
Area: In-match
Host/Client/Both: Client
Expected: Client sees brute death impact ring FX.
Actual: Impact ring FX absent on client.
Repro steps: Kill brute and observe death FX on client.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Likely missing remote FX event or filtered FX playback.
```

```text
ID: MP-SYNC-008
Title: Client cannot pick up ammo clips from world
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Client can collect ammo clips into inventory.
Actual: Ammo clip pickups fail for client.
Repro steps: Client attempts world ammo pickup.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Potentially same family as MP-SYNC-001 item pickup failures.
```

```text
ID: MP-SYNC-009
Title: Comms bubbles persist into next level
Severity: P2
Area: UI
Host/Client/Both: Both
Expected: Comms bubbles clear on level transition/start.
Actual: Prior-level comms bubbles linger on screen.
Repro steps: Finish/play multiple levels and observe UI carry-over.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Reset/cleanup issue on mission transition.
```

```text
ID: MP-SYNC-010
Title: Client gunner ammo power bar does not update after ammo drag
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Ammo bar updates after valid ammo clip drag to bar.
Actual: Drag accepted but ammo power bar unchanged.
Repro steps: Client drags ammo clip from backpack to ammo bar.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Check inventory mutate + UI refresh event ordering.
```

```text
ID: MP-SYNC-011
Title: Client cannot apply night-vision glasses to AI portrait
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Night-vision item applies and tile tint updates.
Actual: Drag/drop fails to apply night vision tint effect.
Repro steps: Client drags night-vision glasses onto target portrait.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Buff-apply path may be rejected or not echoed back to client.
```

```text
ID: MP-SYNC-012
Title: Client randomly loses last two ammo blips without firing
Severity: P1
Area: In-match
Host/Client/Both: Client
Expected: Ammo blips change only on valid ammo spend/reload events.
Actual: Last two blips disappear without apparent firing action.
Repro steps: Play client turn and monitor gunner ammo state over time.
Frequency: sometimes
Evidence: tester report (2026-05-09 remote session)
Status: Open
Owner: Unassigned
Notes: Might be reconcile overwrite from stale authoritative state.
```
