# ZoneGrid

A small macOS menu bar app for planning across timezones. Pick a time in your home
timezone by clicking an hour and see what time it will be in every saved city, plus a
24-hour strip per city (green = work hours, yellow = awake, gray = night).
A local replacement for worldtimebuddy.com.

## Build and run

Requires macOS 13+ and the Xcode command line tools (`xcode-select --install`).

### Quick run (development)

```sh
swift run
```

Builds a debug binary and launches it. A clock icon appears in the menu bar (no Dock icon).

### Build the app bundle

```sh
./scripts/build-app.sh
open build/ZoneGrid.app
```

What the script does:

1. `swift build -c release` compiles the Swift package (`Package.swift`, sources in
   `Sources/ZoneGrid/`) into a single executable at `.build/release/ZoneGrid`.
2. Creates the bundle layout `build/ZoneGrid.app/Contents/MacOS/` and copies the executable in.
3. Writes `Contents/Info.plist` with the bundle ID (`com.codesmiths.zonegrid`), the version, and
   `LSUIElement` so the app lives in the menu bar only (no Dock icon).
4. Ad-hoc signs the bundle (`codesign --sign -`) so macOS will launch it on this machine.

The app version is the latest git tag (`v1.1.0` becomes `1.1.0`), read by the script at build time.
To release: update `CHANGELOG.md`, commit, then `git tag -a vX.Y.Z -m "X.Y.Z"` and `git push --tags`
before building. The right-click menu shows this version.

### Keep it across restarts

```sh
cp -R build/ZoneGrid.app /Applications/
```

Then add `/Applications/ZoneGrid.app` in System Settings → General → Login Items & Extensions
(Open at Login). To update, rebuild and copy the new app over the old one (quit the running copy
first: right-click the menu bar icon → Quit).

The app is not notarized, so on another Mac you must right-click → Open the first time.

### Controls

- Click an hour in any city's strip to select that time; click the time in the header to type one.
- Click the city name in the header to choose which city the time refers to.
- House button sets a city as home (always first); drag the ≡ handle to reorder; **+** adds a city.
- Right-click the menu bar icon to quit.

## Notes

- City search uses Apple's timezone identifiers, so search "New York" rather than "Boston".
- The city list is saved in `UserDefaults`.

## Ideas

- City aliases (Boston → America/New_York)
- Copy selected times as text
- 12h/24h toggle
- Launch-at-login toggle inside the app (`SMAppService`)
- Developer ID signing and notarization
