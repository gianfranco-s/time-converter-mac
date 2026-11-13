# Changelog

## Unreleased

### Added
- **Home city:** a house button on each city row sets it as home. Home is pinned at the top
  and is the reference zone for the slider, offsets and day markers. The previous home
  becomes a regular, removable city. Saved across launches (defaults to the system timezone).
- **Reorder cities:** drag the ≡ handle to move a city up or down; order is saved.
  Home always stays first.
- **Add city behind a "+" button** that reveals a search field, collapsing after a city is added.
- **Quit via right-click** on the menu bar icon (the power button was removed).

### Changed
- Menu bar shell moved from `MenuBarExtra` to `NSStatusItem` + popover to support right-click.
- Window widened to 820 pt so all row information fits.

### Fixed
- Time and 24-hour strip are correct on DST transition days (built from calendar
  components instead of adding seconds).
- Half-hour and 45-minute offsets display correctly (`+5:30`, `+5:45`) instead of being truncated.

## Initial version
- Menu bar timezone planner: slider for the selected time, matching time per saved city,
  24-hour strip per city (work hours / awake / night), day-offset markers, city search.
