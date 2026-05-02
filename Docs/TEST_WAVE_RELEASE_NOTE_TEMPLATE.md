# Test Wave Release Note Template

Copy/paste this block for each tester build drop.

```text
DVX Test Build Drop — <release_label>

Build ref:
- Branch: <branch_name>
- Commit: <short_sha>
- Tag: <tag_name>

Config for this wave:
- env_name: <ENV_NAME>
- project version: <PROJECT_VERSION>
- net_protocol_version: <NVP>
- transport_mode: <TRANSPORT_MODE>
- transport_ws_url: <WS_URL>
- transport_room_id: <ROOM_ID>

Tester setup notes:
- Single-machine dual-client test: Defold = p1, Browser = ?player=p2
- Do not run both clients with same player id
- If host/client net_protocol_version mismatches, join should be blocked and mismatch advisory should appear

What to test (priority):
1) Session create/join reliability (host and client both directions)
2) Join + setup sync (names visible, launch behavior correct)
3) Exit/re-enter stability (no marooned peer)
4) One mismatch sanity check (join blocked + advisory visible)

Required report format:
- Use Docs/TESTERS_README_FIRST.md section 10 template
```
