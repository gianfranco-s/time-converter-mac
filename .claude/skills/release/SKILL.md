---
name: release
description: Tag a ZoneGrid release, push it, then build and relaunch the app. Use as /release X.Y.Z, or /release with no version to only rebuild and relaunch the current build.
disable-model-invocation: true
argument-hint: "[X.Y.Z]"
---

Release and run ZoneGrid. The app version comes from the latest git tag (`scripts/build-app.sh`
reads `git describe --tags`), so the tag must exist **before** building.

Argument: `$ARGUMENTS` (a version like `1.2.0`, optional).

## If a version was given

1. **Checks** (stop and report if any fails):
   - On branch `main`; `git fetch` shows it isn't behind `origin/main`.
   - `CHANGELOG.md` has a heading starting `## X.Y.Z`. If not, offer to draft the entry from
     `git log` since the last tag (features only, not history) and add it.
   - Tag `vX.Y.Z` does not already exist.
   - Version is higher than the latest tag (`git tag --sort=-v:refname | head -1`).
2. **Commit** any uncommitted changes (show `git status` first). Message: `Release X.Y.Z: <short summary>`.
3. **Tag and push**: `git tag -a vX.Y.Z -m "X.Y.Z"` then `git push origin main --tags`.

## Always (with or without a version)

4. **Build and relaunch**:
   ```sh
   pkill -x ZoneGrid; ./scripts/build-app.sh && open build/ZoneGrid.app
   ```
5. **Verify**: `/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" build/ZoneGrid.app/Contents/Info.plist`
   matches the tag, and `pgrep -lx ZoneGrid` shows it running.
6. Report the version, commit, and whether the push succeeded. Do not copy to `/Applications`
   unless asked.

If no version was given, skip steps 1–3 and say the build is from the current tag
(it will not match a newer unreleased commit).
