# DVX Online Stress Test Guide
## A very detailed, child-friendly playbook for Mac + PC crossplay using itch.io and Supabase

Author: Alex + Codex  
Purpose: Help you ship private internet tests safely, step by step  
Audience: You (and anyone who wants plain explanations)

---

## How to use this guide

Think of this guide like building a LEGO city:

- You do **one stage at a time**.
- You do **not** skip the foundation pieces.
- If something breaks, you go back to the last stable piece.

There are 9 stages.  
Each stage has:

- **What this means in simple words**
- **Why it matters**
- **What to do**
- **How to know you're done**
- **Common mistakes**

---

## Tiny dictionary (simple words)

### Build
A packaged game app players run.  
Example: `DVX Windows Build 0.8.1` or `DVX Mac Build 0.8.1`.

### Crossplay
Mac players and Windows players can play each other.

### Backend
The online "brain/storage place" on the internet.

### Supabase
A cloud service where you can store game data, events, and logs.

### itch.io
A website where players can download your game builds.

### Session
One game room/match.

### Telemetry
"Game health notes" your game writes while it runs:
what happened, when, and to whom.

### Protocol version
A strict compatibility number for networking messages.
If this number is wrong/mismatched, clients should not play together.

### Staging
Private test environment (safe sandbox).

### Public
Wider test environment.

### TLS / WSS
Secure encrypted internet connection (`wss://`).

---

## The big goal

You want:

1. Mac and PC builds on itch.io
2. Those players can play each other online
3. You can stress test hard
4. When things break, you can find out why quickly

---

# Stage 1 - Freeze a safe baseline

## Simple meaning
"Take a photo" of a known-good version before changing online systems.

## Why this matters
If future network work breaks things, you can safely rewind.

## What to do

1. Finish your current design edits.
2. Commit current gameplay/content state.
3. Create a tag, for example: `stress-baseline-v1`.
4. Create a branch for network hardening, for example: `online-stress-prep`.
5. Write a short note file with:
   - current accepted behavior
   - known issues
   - baseline tag name

## Done checklist

- [ ] Baseline commit exists
- [ ] Baseline tag exists
- [ ] Branch exists
- [ ] Note file exists

## Common mistakes

- Starting online changes without a baseline tag
- Mixing content changes and network changes in the same commit all day

---

# Stage 2 - Add environment and version controls

## Simple meaning
Teach your game how to know:

- where to connect
- which test environment it is in
- which network version it speaks

## Why this matters
Without this, you'll accidentally connect wrong builds to wrong servers.

## What to do

Add config values for:

- `ENV_NAME` (`LOCAL`, `STAGING`, `PUBLIC_TEST`)
- transport URL (example websocket endpoint)
- room namespace
- `GAME_VERSION` (human label)
- `NET_PROTOCOL_VERSION` (strict compatibility gate)

In your UI, show:

- build id
- env name
- protocol version

On join/match start:

- if protocol versions mismatch, reject with clear message

## Example rejection text
"You and the host are on different network versions. Please update to the same build."

## Done checklist

- [ ] Env switch works
- [ ] Build label visible
- [ ] Protocol label visible
- [ ] Mismatch blocks join

## Common mistakes

- Only checking game version string, not protocol version
- Forgetting to update Mac and PC together

---

# Stage 3 - Build your Supabase staging environment

## Simple meaning
Set up your internet "notebook" where sessions and events are stored.

## Why this matters
During stress tests, you need proof of what happened.

## What to do

Create a Supabase project for staging.

Create base tables:

1. `sessions`
2. `session_players`
3. `session_events`
4. `network_events`
5. `client_errors`

Minimum columns you should include often:

- `session_id`
- `player_id`
- `platform` (`windows` / `macos`)
- `build_id`
- `protocol_version`
- `event_type`
- `payload_json` (optional event detail)
- `created_at`

Add indexes on:

- `session_id`
- `event_type`
- `created_at`

Enable basic safety policies (RLS/policies) so random users cannot write anywhere.

## Done checklist

- [ ] Supabase staging project exists
- [ ] Base tables created
- [ ] Indexes created
- [ ] Security policies set
- [ ] Game can write a test event

## Common mistakes

- No indexes (queries become slow)
- Missing platform/build fields (hard to debug crossplay)
- No RLS/policies (security risk)

---

# Stage 4 - Add telemetry and in-game debug visibility

## Simple meaning
Give yourself a "black box flight recorder" for every session.

## Why this matters
Stress testing without telemetry is like fixing a car blindfolded.

## What to log

At minimum:

- connect/disconnect
- join success/fail
- ready toggles
- turn begin/end
- snapshot sequence/age
- checksum mismatch
- resync triggered
- command send time + apply time

Add platform metadata each time:

- OS
- build id
- protocol version

Add in-game debug panel toggle:

- session id
- role (host/client)
- env
- protocol version
- ping/snapshot age
- mismatch count

Add local file logs too (native builds):

- one log per run
- include UTC timestamps

## Done checklist

- [ ] Telemetry events go to Supabase
- [ ] Debug panel visible in game
- [ ] Local log file generated
- [ ] Session id visible and searchable

## Common mistakes

- Logging too little detail
- Not including session id in logs
- No timestamp consistency (use UTC)

---

# Stage 5 - Harden session lifecycle (disconnect/reconnect)

## Simple meaning
Make sure sessions don't get confused when players drop or return.

## Why this matters
Most online bugs happen here, not in normal "happy path" play.

## Scenarios to test

1. Host disconnects mid-match
2. Client disconnects and reconnects
3. Client reconnects with stale state
4. Two clients try to become same slot
5. Stale room remains alive too long
6. Ready states survive incorrectly into next match

## Required behavior principles

- Host remains authority for truth
- Reconnecting client requests fresh state
- Session can expire if everyone is gone (TTL)
- UI never gets stuck forever on waiting

## Done checklist

- [ ] Reconnect works in basic cases
- [ ] Stale rooms are cleaned up
- [ ] No permanent stuck-wait states
- [ ] Clear user error messages exist

## Common mistakes

- No TTL cleanup for dead rooms
- Reconnect merges stale and fresh state badly
- "Waiting for snapshot" with no timeout

---

# Stage 6 - Publish private Mac + PC staging builds on itch.io

## Simple meaning
Let real testers download and run your game easily.

## Why this matters
Real internet behavior appears only with real users and mixed machines.

## What to do

On itch.io:

1. Create private/restricted test page.
2. Create separate channels or uploads:
   - Windows staging build
   - macOS staging build
3. Name both with same build id and protocol version.
4. Add test instructions right on the page.

## Include on page

- build id
- protocol version
- test schedule window
- bug reporting format
- where to find in-game session id

## Done checklist

- [ ] Both OS builds uploaded
- [ ] Same protocol version on both
- [ ] Test page includes reporting instructions
- [ ] Testers can join sessions

## Common mistakes

- Uploading only one OS update
- Forgetting to update protocol label
- No clear tester instructions

---

# Stage 7 - Add synthetic load (scripted stress)

## Simple meaning
Use scripts/bots to do repetitive online actions faster than humans can.

## Why this matters
Humans are great for feel, bad for high-volume repeat tests.

## What scripted clients should do

- connect
- join/create session
- send repeated command patterns
- ready/unready cycles
- disconnect/reconnect loops

## Metrics to collect

- join fail rate
- command latency (p50, p95)
- mismatch/resync count
- stuck session count
- server error rates

## Done checklist

- [ ] Script can run many session loops
- [ ] Metrics are captured
- [ ] Failures are visible in Supabase logs

## Common mistakes

- No deterministic script path (hard to compare runs)
- Not tagging events with test-run id

---

# Stage 8 - Define hard pass/fail gates

## Simple meaning
Set clear numbers that must pass before wider release.

## Why this matters
Without gates, stress tests become opinions and arguments.

## Example gates

- Reconnect success >= 95%
- Stuck-turn sessions < 1%
- Critical desync count = 0 in defined soak window
- p95 command latency below your chosen target
- Mixed OS sessions pass at same quality as same-OS sessions

## Required crossplay matrix

You must test all:

1. Win host + Win client
2. Mac host + Mac client
3. Win host + Mac client
4. Mac host + Win client

## Done checklist

- [ ] Gates written down
- [ ] Gates measured from telemetry
- [ ] All matrix combinations tested

## Common mistakes

- Testing only same-platform first
- No numeric thresholds

---

# Stage 9 - Public safety and rollback

## Simple meaning
Be ready for internet chaos before inviting larger crowds.

## Why this matters
Public testing always brings weird cases and abuse attempts.

## Safety tasks

- validate incoming payload shape server-side
- rate limit command spam
- keep staging and public data separated
- protect Supabase keys and policies
- keep alerting for error spikes

## Rollback plan (must be pre-written)

When bad issue appears:

1. Pause/hide broken itch channels
2. Block new sessions if needed
3. Re-enable last known good build
4. Announce short status to testers
5. Patch, verify, re-open

## Done checklist

- [ ] Rollback steps written and tested once
- [ ] Older good build is available
- [ ] Team knows who presses rollback button

## Common mistakes

- No rollback owner
- No previous build artifact saved

---

## Crossplay golden rules (print this section)

1. Same protocol version for Mac and PC, always.
2. Release Mac+PC together from same commit.
3. Block mismatched protocol join every time.
4. Log platform/build/protocol in every major event.
5. Test mixed platform pairs early, not as afterthought.

---

## Suggested weekly testing rhythm

### Monday
Build + upload Mac/PC staging from same commit.

### Tuesday
Smoke tests (all 4 platform combinations).

### Wednesday
Reconnect/disconnect chaos tests.

### Thursday
Long soak sessions + synthetic load runs.

### Friday
Analyze Supabase data, fix top issues, bank improvements.

Repeat.

---

## Tester bug report template (copy this exactly)

Build ID:  
Protocol Version:  
Platform (Mac/Windows):  
Role (Host/Client):  
Session ID:  
UTC time of issue:  
What happened:  
What should happen:  
Steps to reproduce:  
Log file attached (yes/no):

---

## "If I only remember 5 things" summary

1. Keep strict protocol version matching.
2. Always ship Mac+PC pairs together.
3. Log everything important with session id + UTC.
4. Harden reconnect before big public tests.
5. Never run public tests without rollback ready.

---

## End note

You already have the hardest part (game logic + host authority) moving well.  
This guide makes the online part safe and systematic.

Do one stage at a time.  
Bank progress often.  
Use data, not guesswork.

