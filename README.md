# SwiftTime

SwiftUI menu bar app for comparing local time with a small set of world clocks and previewing other hours for planning.

## Notes

- This version is intentionally minimal: one Swift source file plus this README.
- The menu bar icon is a clock symbol only.
- The world clock list is hardcoded in source for now. Edit `SwiftTime.swift` to change the tracked locations.
- The app supports two planning flows:
  - move a slider to preview whole-hour offsets from your local current time
  - use `Set Hour` on any location row to pin the planner to an exact hour in that timezone
- The per-location hour picker is hour-granularity by design. It sets minutes and seconds to `00`.
- Germany uses `Europe/Berlin` rather than a fixed `CET` offset so daylight saving transitions are handled correctly.

## Build

```bash
git clone <your-repo-url>
cd SwiftTime
swiftc -parse-as-library -framework SwiftUI -framework AppKit -o SwiftTime SwiftTime.swift
```

## Run

```bash
./SwiftTime
```

The app lives in the macOS menu bar and updates continuously while open.
