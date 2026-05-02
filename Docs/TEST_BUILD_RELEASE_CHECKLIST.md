# Test Build Release Checklist

Use this checklist every time you prepare a new tester build.

---

## 1) Set and confirm config

In `game.project`, confirm:

- `[project] version` is correct for this build
- `[dvx] env_name` is correct (for example `LOCAL`, `STAGING`, `PROD`)
- `[dvx] net_protocol_version` is correct and intentional
- `[dvx] transport_mode` is correct
- `[dvx] transport_ws_url` points to the intended relay
- `[dvx] transport_room_id` is correct for this test wave

Do not mix old and new `net_protocol_version` unless mismatch behavior is being tested on purpose.

---

## 2) Build naming convention

Name artifacts with version and protocol included.

Recommended format:

`DVX-<env>-v<project_version>-nvp<net_protocol_version>-<yyyymmdd>`

Example:

`DVX-LOCAL-v1.1-nvp1-20260502`

---

## 3) Bundle artifacts

Bundle the required targets for the test wave (for example HTML5 and macOS).

Before sending to testers, ensure the build launches cleanly and required files are present.

For HTML5 specifically, ensure the bundle contains:

- `index.html`
- `dmloader.js`
- `archive/game0.dmanifest`

If `archive/game0.dmanifest` is missing, stop and rebuild.

---

## 4) Pre-release smoke test (required)

Run this before distributing:

1. Launch host/client with distinct player ids (`p1` and `p2`)
2. Host creates session
3. Client sees session and joins
4. Verify both names appear in setup and launch behavior is correct
5. Exit/re-enter once and verify lobby/session consistency

---

## 5) Mismatch behavior check (required)

Validate protocol safety:

1. Build A with `net_protocol_version = 1`
2. Build B with `net_protocol_version = 2`
3. Attempt cross-join

Expected result:

- Join is blocked
- Mismatch advisory is visible in lobby

If either condition fails, do not release.

---

## 6) Tester package contents

For each test wave, provide:

- Build artifact(s)
- `Docs/TESTERS_README_FIRST.md`
- Short run note with:
  - target platform
  - expected protocol version
  - relay endpoint/room if relevant
  - known limitations for this wave

---

## 7) Release record

Record the exact references used for this release:

- branch name
- commit SHA
- tag name (recommended stable tag)
- build filename(s)
- release date/time

---

## 8) Rollback plan

If tester wave is unstable:

1. Stop distribution of current build
2. Revert to stable tag
3. Rebundle from stable tag
4. Re-issue with a new artifact name and clear note

Current stable fallback tag:

- `stress-prep-stage2-stable`

