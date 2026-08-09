# Lokum Mobile Development Workflow

## Sprint Process

1. Receive Sprint package
2. Copy or replace files
3. Format code

```powershell
dart format .
```

4. Update dependencies if pubspec.yaml changed

```powershell
flutter pub get
```

5. Analyze project

```powershell
flutter analyze
```

6. Run tests

```powershell
flutter test
```

7. Start application

```powershell
flutter run
```

8. Visual verification
- UI
- Console
- Device behavior

9. Git check

```powershell
git status
```

10. Commit and push

```powershell
git add .
git commit -m "Sprint XX - description"
git push
```

## Rules

- No push with compilation errors.
- Every Sprint must be stable.
- One Sprint = one completed feature.

## Branches & environments (v2.0 development)

- **`main`** → source for **`production`** branch (deployed to `lokum-web`,
  port 8080, public via Tailscale Funnel). Everyday content work (photos,
  menu.json, events.json) happens directly here.
- **`production`** → what the live `lokum-web` container actually deploys
  from. Kept in sync with `main` (fast-forward only):
  ```bash
  git checkout production
  git merge main --ff-only
  git push origin production
  git checkout main
  ```
- **`test`** → v2.0/2.1 development branch (Admin panel, later full order
  flow). Deployed to a **separate** container `lokum-web-v2` (port 8081),
  reachable only from devices on the tailnet - never through Funnel/Caddy.

### Keeping `test` from falling behind on content

Never merge `test` → `main`/`production` until a version is ready to ship.
Only pull forward, `main` → `test`, as often as needed:
```bash
git checkout test
git merge main
git push origin test
```

### Server setup for the `test` environment (one-time)

`lokum-web-v2`'s Docker build context is a separate `git worktree` checked
out to `test`, living as a sibling directory next to the main repo - same
`.git` object store, no second full clone:
```bash
cd /project/lokum
git worktree add ../lokum-test test
```
After that, `docker compose up -d --build lokum-web-v2` picks up whatever
is currently on `test` from `../lokum-test`. To pick up a new `test` commit,
`cd ../lokum-test && git pull`, then rebuild `lokum-web-v2`.
