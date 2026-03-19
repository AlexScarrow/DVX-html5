# Recovery Checklist (If Agent Disconnects)

Use this quick flow to safely continue work.

## 1) Check current state
```bash
git status --short --branch
git log --oneline -10
```

## 2) If there are uncommitted changes, bank them
```bash
git add -A
git commit -m "Bank in-progress work after disconnect."
```

## 3) Sync to remote (credential-helper workaround if needed)
```bash
git -c credential.helper= push origin HEAD
```

## 4) Write a short continuity note
- Update `DEV_LOG.md` with:
  - goal
  - what changed
  - what still needs doing
  - any known issues

## 5) Restart from a clean base when needed
```bash
git checkout main
git pull origin main
```

## 6) Start next task safely
```bash
git checkout -b feature/<short-task-name>
```

---

## Quick handover brief (copy/paste)
- Current branch:
- Latest commit hash:
- Current goal:
- Files touched:
- Known issue(s):
- Next exact step:
