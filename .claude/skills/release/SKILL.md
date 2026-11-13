---
name: release
description: Tag a ZoneGrid release, push it, then build and relaunch the app. Use as /release X.Y.Z, or /release with no version to get a proposed next version (or just rebuild and relaunch).
disable-model-invocation: true
argument-hint: "[X.Y.Z]"
---

Release and run ZoneGrid. The app version comes from the latest git tag (`scripts/build-app.sh`
reads `git describe --tags`), so the tag must exist **before** building.

Argument: `$ARGUMENTS` (a version like `1.2.0`, optional).

## If no version was given: propose one

1. Find the last tag (`git tag --sort=-v:refname | head -1`) and review what changed since it
   (`git log <tag>..HEAD --oneline`, `git diff <tag> --stat`, and any `CHANGELOG.md` entries
   newer than the tag).
2. Pick the bump using semver:
   - **patch** (1.1.0 -> 1.1.1): only fixes or internal changes.
   - **minor** (1.1.0 -> 1.2.0): new user-visible features, backwards compatible.
   - **major** (1.1.0 -> 2.0.0): breaking changes (e.g. saved settings no longer readable).
   - If nothing changed since the tag, say so and propose no release.
3. Ask the user (AskUserQuestion) with the recommended version first, marked "(Recommended)",
   plus the other two bumps, and a "Just rebuild and relaunch" option. Include a one-line
   reason for the recommendation. Then continue with the chosen version below.

## Releasing a version (given or chosen)

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

If the user chose "Just rebuild and relaunch", skip steps 1–3 and say the build is from the
current tag (it will not match a newer unreleased commit).
