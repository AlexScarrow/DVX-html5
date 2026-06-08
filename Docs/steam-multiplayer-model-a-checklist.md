# Steam Multiplayer Model A Checklist

This document captures the implementation plan for wiring multiplayer into Steam using Model A:

- Steam handles discovery/invites/lobby shell.
- Existing in-game lobby and transport continue handling gameplay setup and sync.

## Ownership Legend

- `YOU`: Steamworks portal/account/business decisions.
- `ME`: code/config tasks in this repo.
- `BOTH`: shared decision + implementation/testing.

## 1) Steamworks Setup

- `YOU` Confirm full-game AppID and Steamworks multiplayer feature enablement.
- `YOU` Configure branches/depot setup for multiplayer testing.
- `YOU` Decide default lobby policy (public/private, max players, invite behavior).
- `YOU` Confirm supported OS targets for multiplayer.

## 2) Runtime Steam Integration

- `ME` Add desktop Steam init path with safe fallback when unavailable.
- `ME` Capture Steam identity (SteamID/display name) into runtime player profile.
- `ME` Gate Steam usage behind feature flags so local/dev paths still work.

## 3) Lobby Bridging (Steam -> Existing MP Lobby)

- `ME` Add a Steam bridge layer:
  - create/join/leave lobby
  - read/write lobby metadata
- `ME` Map Steam lobby metadata to existing session fields:
  - protocol/version
  - room/session id
  - player count limits
- `ME` Route Steam invite/lobby joins into existing in-game MP setup/lobby flow.
- `BOTH` Keep source-of-truth split clear:
  - Steam = discovery/invite shell
  - in-game lobby = setup/ready/start

## 4) Transport + Handshake

- `ME` Keep current websocket/host-authoritative gameplay transport.
- `ME` Include Steam identity fields in current join/seat handshake.
- `ME` Add strict protocol/build mismatch rejection before seat assignment.

## 5) Invite UX + Overlay

- `ME` Add `Invite Friends` button action to open Steam overlay invite dialog.
- `ME` Handle "join via invite" callback and deep-link to MP lobby flow.
- `YOU` Provide preferred player-facing copy for invite/join failure states.
- `ME` Add graceful fallback messaging when overlay is unavailable.

## 6) Failure/Edge Case Policy

- `ME` Handle:
  - Steam init failure
  - lobby create/join failure
  - transport timeout after lobby join
  - host disconnect
- `BOTH` Decide host migration policy (recommended first pass: end match and return to lobby cleanly).

## 7) QA Checklist

- `BOTH` Two-account invite/join flow on same branch.
- `BOTH` Build/protocol mismatch rejection behavior.
- `BOTH` Reconnect/drop behavior in lobby and during match.
- `BOTH` Late-join policy validation (allowed or blocked by design).
- `YOU` Steam beta-branch QA with trusted testers.

## 8) Release Steps

- `YOU` Promote tested branch in Steamworks.
- `YOU` Confirm store metadata aligns with shipped MP scope.
- `YOU` Publish release notes and known issues.
- `ME` Optional: add lightweight runtime diagnostics for post-launch triage.

## Suggested Build Order (Low Risk)

1. Steam init + identity only.
2. Steam lobby create/join + metadata mapping.
3. Invite accept routing into existing MP lobby.
4. Handshake/version gates.
5. QA pass + polish.

