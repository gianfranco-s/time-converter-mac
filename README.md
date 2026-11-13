# ZoneGrid

A small macOS menu bar app for planning across timezones. Pick a time in your home
timezone with the slider and see what time it will be in every saved city, plus a
24-hour strip per city (green = work hours, yellow = awake, gray = night).
A local replacement for worldtimebuddy.com.

## Run

Requires macOS 13+ and the Xcode command line tools (`xcode-select --install`).

```sh
swift run
```

or build once and run the binary:

```sh
swift build -c release
.build/release/ZoneGrid &
```

A clock icon appears in the menu bar (no Dock icon).

## Notes

- City search uses Apple's timezone identifiers, so search "New York" rather than "Boston".
- The city list is saved in `UserDefaults`.
- Start at login: System Settings → General → Login Items (a proper `.app` bundle is a TODO).

## Ideas

- City aliases (Boston → America/New_York)
- Copy selected times as text
- 12h/24h toggle
- `.app` bundle with launch-at-login
