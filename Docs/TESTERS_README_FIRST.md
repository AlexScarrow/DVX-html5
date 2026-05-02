# Testers - Readme first

Thank you for helping test DVX online builds.
Please read this once before testing.

This document is the complete tester guide.

---

## 0) 2-minute quick start

If you only read one part, read this:

1. Launch the assigned test build.
2. Confirm host/client are on the same build and protocol.
3. Join a session and play for 10-15 minutes.
4. Do one disconnect/reconnect test.
5. Report using the template in section 10.

Stop immediately and report if you hit:

- session join failure
- host/client desync
- soft-lock
- crash/freeze

---

## 1) What this test is for

Primary goal:

- Validate online stability and host/client sync on Windows and macOS.

Secondary goal:

- Catch major usability issues that block normal play.

---

## 2) Display policy (important)

DVX is authored around a **1280x720 gameplay layout**.
For PC/Mac testing, this is intentional and expected.

- Internal gameplay/UI baseline: `1280x720`
- Desktop display goal: preserve aspect ratio, avoid stretch
- On non-16:9 screens, bars (letterbox/pillarbox) are acceptable

Seeing bars alone is **not a bug**.

---

## 3) What to install and confirm before testing

Before starting a session, confirm all of these:

- You are on the assigned test build
- Host and client are on the same build/protocol
- You know your role: Host or Client
- You can capture screenshot or short video clip if needed

If host/client builds differ, stop and align versions first.

Local dual-client test note (single machine):

- Defold runtime should use `p1`
- Browser runtime should use `?player=p2`
- Do not run both clients as the same player id

Protocol mismatch expected behavior:

- If host/client `dvx.net_protocol_version` values differ, join should be blocked
- Client should see the network version mismatch advisory in lobby

---

## 4) Quick test flow (every session)

Run this order:

1. Launch game
2. Create/join online session
3. Play normal turn/action loop for at least 10-15 minutes
4. Perform one disconnect/reconnect attempt
5. End session and submit report

---

## 5) Minimum device and resolution matrix

Please cover as many as possible:

- Platform: Windows + macOS
- Modes: windowed + fullscreen
- Resolutions:
  - `1280x720` (baseline)
  - `1366x768`
  - `1920x1080`
  - `2560x1440` (if available)
- Optional: one ultrawide test

---

## 6) Multiplayer focus checklist

Prioritize these checks:

- Session creation/join reliability
- Host authority consistency (state remains correct)
- Action sync (both players see same results)
- No duplicate, missing, or delayed critical actions
- Reconnect behavior after host/client drop
- Match remains stable under longer play

---

## 7) What counts as a high-priority bug

Report immediately if any of these happen:

- Desync between host/client game state
- Session cannot be created or joined
- Match soft-lock (cannot continue turn flow)
- Crash/freeze during online session
- Data loss of critical mission/session state

---

## 8) What counts as a display bug

Please report these:

- UI buttons/hitboxes do not match clicks
- Text or UI panels clipped/cut off
- Gameplay view stretched/squashed
- Mouse clicks map to wrong world location
- Fullscreen/window switching breaks layout
- Severe blur or unreadable UI on Retina/HiDPI

---

## 9) Known acceptable behavior in this phase

These are usually acceptable unless they block play:

- Letterbox/pillarbox bars on non-16:9 screens
- Minor visual polish gaps
- Non-critical cosmetic animation timing differences

If unsure, report anyway and mark as "uncertain severity".

---

## 10) Report template (copy/paste)

Use this exact template:

```text
Build ID:
Protocol version:
Platform: (Windows/Mac)
OS version:
Display resolution:
Window mode: (Windowed/Fullscreen)
Role: (Host/Client)
Network quality: (good/ok/poor)

What happened:
Expected result:
How to reproduce:
Frequency: (once/sometimes/always)
Severity: (blocker/high/medium/low)
Screenshot or video:
Session ID or timestamp:
```

---

## 11) Tester etiquette and safety

- Do not share private test builds publicly
- Do not post invite codes/links in public channels
- Keep reports factual, short, and reproducible
- One issue per report is preferred

---

## 12) Final note

We are prioritizing online reliability first.
Your reports directly decide launch readiness.

Thank you for testing.
