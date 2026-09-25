# AppChangelog

A small Swift package that shows an app's change history inside the app. It parses a `CHANGELOG.md` in the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format and renders it as a SwiftUI view. On top of that it offers a "What's new" sheet that appears once after a version jump and shows only what changed since the version the user last saw.

Versions are grouped by marketing version (`major.minor.patch`) only, never by build number.

> **Language:** the built-in UI texts ("Was ist neu", "Änderungsverlauf", section titles) are German. The parser understands both German and English section headings.

## Requirements

- iOS 26, macOS 26 or watchOS 26
- Swift 6.2 or later (Xcode 26)

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/AndreClaassen1/AppChangelog.git", from: "0.1.0")
```

Then add `CHANGELOG.md` to your app target as a bundle resource (with XcodeGen: under `sources` with `buildPhase: resources`).

## Usage

```swift
import AppChangelog

let changelog = Changelog.load()                 // reads CHANGELOG.md from the bundle
let version = SemanticVersion(BuildInfo.version) // your app's current marketing version

// Full history behind a link, e.g. in a footer:
@State private var showChangelog = false
// ...
.changelogSheet(isPresented: $showChangelog, changelog: changelog, currentVersion: version)

// One-time "What's new" after a version jump:
.whatsNewOnLaunch(appName: "MyApp", currentVersion: version!, changelog: changelog)
```

The first launch stays quiet; the sheet only appears on later version jumps.

## Menu bar apps: no sheet in the popover

**Do not attach `whatsNewOnLaunch` or `changelogSheet` to the content of a `MenuBarExtra(.window)`.** The popover is a transient, non-activating panel, and a `.sheet` on it misbehaves:

- The sheet disappears with the popover **without ending the presentation**. The `@State` that shows it stays alive (SwiftUI keeps the menu bar content alive while the popover is closed), so the same sheet shows up again the next time, and the notice has to be confirmed several times.
- The first click goes to activating the window, not to the button.

Anchored at the scene root of a regular app (as on iOS), the modifiers behave correctly. Only the popover is the problem.

**Use a dedicated `Window` scene instead.** A window survives the popover closing, activates normally and closes on the first click. The package provides both halves:

- `WhatsNewState.consumePending(for:in:)`: the complete rule "is a What's new due", including remembering the version. Rebuilding it yourself is error-prone, because `markSeen` must run after the lookup, and also when there is nothing to show.
- `ChangelogWindowContent`: the window content, which switches between "What's new" and the full history and clears the notice on close.

```swift
@Observable @MainActor
final class ChangelogCoordinator {
    // Parsed on first access; consumePending does not touch it without a version jump.
    @ObservationIgnored private(set) lazy var changelog = Changelog.load()
    let currentVersion = SemanticVersion(BuildInfo.version)
    var whatsNew: WhatsNewPayload?

    /// `false` = nothing to show, the window stays closed.
    func prepareWhatsNew() -> Bool {
        guard let currentVersion else { return false }
        whatsNew = WhatsNewState().consumePending(for: currentVersion, in: changelog)
        return whatsNew != nil
    }
}

// Window content:
ChangelogWindowContent(
    appName: "MyApp",
    changelog: coordinator.changelog,
    currentVersion: coordinator.currentVersion,
    whatsNew: $coordinator.whatsNew,
    onClose: { dismissWindow(.changelog) }
)
```

On launch, the app calls `prepareWhatsNew()` and opens the window only if it returns `true`; a footer link opens the same window without that call and therefore shows the full history. The `Window` scene itself stays in the app, because window ID, size and trigger are app-specific. Put the launch trigger on the menu bar **label**, not in the popover content: the content does not exist yet at launch.

## Components

| Type | Purpose |
|---|---|
| `SemanticVersion` | Three-part marketing version, comparable; ignores build numbers |
| `ChangelogParser` | Parses Keep a Changelog Markdown (German and English section headings) |
| `Changelog` | Parsed versions; `load(...)` reads from the bundle |
| `WhatsNewState` | Persists the last seen version (`UserDefaults`); `consumePending` is the complete "is a What's new due" rule |
| `WhatsNewPayload` | What to show: the previous version plus the new releases |
| `ChangelogView` | Full view of all versions |
| `WhatsNewView` | Compact view of the new changes |
| `ChangelogWindowContent` | Window content for menu bar apps, switches between both |

## Tests

```bash
swift test
```

## Contributing

Issues and pull requests are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). This is a personal project, so there is no guaranteed support.

## License

MIT, see [LICENSE](LICENSE). The name is not covered by the license.
