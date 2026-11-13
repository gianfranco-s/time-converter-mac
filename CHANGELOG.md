# Changelog

## 1.1.0 - 2026-11-13

### Added
- Right-click menu shows the app version in small, non-clickable text.

### Changed
- Right-click menu is simpler: no icon or keyboard shortcut next to Quit.

### Fixed
- Dragging a city by its ≡ handle now works. The SwiftUI drag gesture did not fire inside the
  menu bar popover, so the handle reads mouse events directly (AppKit).

## 1.0.0 - 2026-11-13

### Added
- **Day separation:** a divider in each city's strip marks where that city's date changes,
  so hours read `22, 23 | 0, 1, 2`.
- **UTC clock** in the header, left of "Now", showing the selected moment in UTC.
- **Home city:** a house button on each city row sets it as home. Home is pinned at the top
  and is the reference zone for the selected hour, offsets and day markers. The previous home
  becomes a regular, removable city. Saved across launches (defaults to the system timezone).
- **Reorder cities:** drag the ≡ handle to move a city up or down; order is saved.
  Home always stays first.
- **Add city behind a "+" button** that reveals a search field, collapsing after a city is added.
- **Quit via right-click** on the menu bar icon (the power button was removed).

### Changed
- **Selectable reference city:** click the city name in the header ("… in Buenos Aires") to pick
  which saved city the time refers to. That row is marked "selected"; every other city shows its
  converted time, offset and day marker relative to it. Switching keeps the same moment selected.
- **Manual time entry:** click the time in the header ("When it's HH:mm in …") to type any
  time (`14:30`, `930`, `9`); Enter applies it, Esc cancels. Clicking an hour in a strip
  returns to a whole-hour selection.
- **Slider removed:** click any hour cell in a city's 24-hour strip to select that time
  (all rows stay aligned to the same instant). "Now" still jumps to the current time.
- Menu bar shell moved from `MenuBarExtra` to `NSStatusItem` + popover to support right-click.
- Header text ("When it's HH:mm in …") is no longer bold.
- Window widened to 820 pt so all row information fits.

### Fixed
- Time and 24-hour strip are correct on DST transition days (built from calendar
  components instead of adding seconds).
- Half-hour and 45-minute offsets display correctly (`+5:30`, `+5:45`) instead of being truncated.

## Initial version
- Menu bar timezone planner: selected hour for the selected time, matching time per saved city,
  24-hour strip per city (work hours / awake / night), day-offset markers, city search.
