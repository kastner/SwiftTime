# SwiftTime

SwiftUI menu bar app for comparing local time with a small set of world clocks and pinning exact hours for planning.

> [!CAUTION]
> This app was "vibe coded" with Codex/GPT-5.4. Do not use it as is, do not trust this code!

## Notes

- This version is intentionally minimal: one Swift source file plus this README.
- The menu bar icon is a clock symbol only.
- The world clock list is hardcoded in source for now. Edit `SwiftTime.swift` to change the tracked locations.
- The app uses a single planning flow: use `Set Hour` on local time or any world clock row to pin the planner to an exact hour in that timezone.
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

## Launch At Startup

Because this project is a bare executable rather than a bundled `.app`, the simplest startup option is a per-user `launchd` agent managed by the included script.

1. Build the binary:

```bash
swiftc -parse-as-library -framework SwiftUI -framework AppKit -o SwiftTime SwiftTime.swift
```

2. Add it to startup:

```bash
./startup.sh add
```

3. If you rebuild the binary later, reload the login item:

```bash
./startup.sh update
```

4. To remove it from startup:

```bash
./startup.sh remove
```

The script writes `~/Library/LaunchAgents/com.kastner.swifttime.plist` pointing at the `SwiftTime` binary in this checkout. If you move the checkout, run `./startup.sh update`.
