import Testing
import Foundation
@testable import AppChangelog

@Suite("WhatsNewState")
struct WhatsNewStateTests {

    private static let sample = """
    # Changelog

    ## [Unreleased]

    ## [0.8.4] – 2026-07-26
    ### Behoben
    - Haekchen je Messwert

    ## [0.8.0] – 2026-07-16
    ### Hinzugefuegt
    - Ersetzen-Knopf

    ## [0.7.0] – 2026-07-13
    ### Hinzugefuegt
    - TabView
    """

    /// Eigene, leere Defaults je Test, damit nichts zwischen Tests haengen bleibt.
    private func makeState(suite: String) -> WhatsNewState {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return WhatsNewState(defaults: defaults)
    }

    private var changelog: Changelog { ChangelogParser.parse(Self.sample) }

    @Test("Erststart bleibt still")
    func firstLaunchIsSilent() throws {
        let state = makeState(suite: "test.firstLaunch")
        let current = try #require(SemanticVersion("0.8.4"))

        #expect(state.lastSeenVersion == nil)
        #expect(state.pendingReleases(for: current, in: changelog).isEmpty)
    }

    @Test("Nach einem Versionssprung kommen genau die Releases dazwischen")
    func reportsReleasesSinceLastSeen() throws {
        let state = makeState(suite: "test.jump")
        let previous = try #require(SemanticVersion("0.7.0"))
        let current = try #require(SemanticVersion("0.8.4"))
        state.markSeen(previous)

        let pending = state.pendingReleases(for: current, in: changelog)

        #expect(pending.map(\.rawVersion) == ["0.8.4", "0.8.0"])
        // Der Inhalt muss mitkommen — genau hier war das Sheet zuvor leer.
        #expect(pending.filter(\.hasContent).count == pending.count)
    }

    @Test("Derselbe Stand meldet nichts mehr")
    func nothingPendingOnSameVersion() throws {
        let state = makeState(suite: "test.same")
        let current = try #require(SemanticVersion("0.8.4"))
        state.markSeen(current)

        #expect(state.pendingReleases(for: current, in: changelog).isEmpty)
    }

    @Test("Eine neuere Version als die laufende wird nicht vorab gezeigt")
    func ignoresReleasesNewerThanCurrent() throws {
        let state = makeState(suite: "test.future")
        state.markSeen(try #require(SemanticVersion("0.7.0")))
        let current = try #require(SemanticVersion("0.8.0"))

        let pending = state.pendingReleases(for: current, in: changelog)

        #expect(pending.map(\.rawVersion) == ["0.8.0"])
    }

    // MARK: - consumePending: Ermitteln und Merken in einem Schritt

    @Test("Kein Sprung: nichts zu zeigen, Changelog wird nicht einmal gelesen")
    func consumeWithoutVersionJump() throws {
        let state = makeState(suite: "test.consume.noJump")
        let current = try #require(SemanticVersion("0.8.4"))
        state.markSeen(current)

        var didReadChangelog = false
        let payload = state.consumePending(for: current, in: {
            didReadChangelog = true
            return changelog
        }())

        #expect(payload == nil)
        #expect(didReadChangelog == false)
        #expect(state.lastSeenVersion == current)
    }

    @Test("Erststart bleibt still, merkt die Version aber")
    func consumeOnFirstLaunchIsSilentButRemembers() throws {
        let state = makeState(suite: "test.consume.firstLaunch")
        let current = try #require(SemanticVersion("0.8.0"))

        // Jede Neuinstallation laeuft hier durch: auch sie darf das Markdown
        // nicht anfassen.
        var didReadChangelog = false
        let payload = state.consumePending(for: current, in: {
            didReadChangelog = true
            return changelog
        }())

        #expect(payload == nil)
        #expect(didReadChangelog == false)
        #expect(state.lastSeenVersion == current)
        // Erst der naechste Sprung zeigt etwas — und dann nur das Neue.
        let next = try #require(SemanticVersion("0.8.4"))
        let following = try #require(state.consumePending(for: next, in: changelog))
        #expect(following.releases.map(\.rawVersion) == ["0.8.4"])
    }

    @Test("Sprung ueber mehrere Versionen liefert alle dazwischen, danach nichts mehr")
    func consumeAcrossMultipleVersions() throws {
        let state = makeState(suite: "test.consume.jump")
        let previous = try #require(SemanticVersion("0.7.0"))
        let current = try #require(SemanticVersion("0.8.4"))
        state.markSeen(previous)

        let payload = try #require(state.consumePending(for: current, in: changelog))

        #expect(payload.previous == previous)
        #expect(payload.releases.map(\.rawVersion) == ["0.8.4", "0.8.0"])
        #expect(payload.releases.filter(\.hasContent).count == payload.releases.count)
        // Gemerkt wird sofort, ein zweiter Durchlauf zeigt nichts erneut.
        #expect(state.lastSeenVersion == current)
        #expect(state.consumePending(for: current, in: changelog) == nil)
    }

    @Test("Downgrade zeigt nichts, merkt aber die aeltere Version")
    func consumeOnDowngrade() throws {
        let state = makeState(suite: "test.consume.downgrade")
        let newer = try #require(SemanticVersion("0.8.4"))
        let older = try #require(SemanticVersion("0.8.0"))
        state.markSeen(newer)

        #expect(state.consumePending(for: older, in: changelog) == nil)
        #expect(state.lastSeenVersion == older)
        // Zurueck auf die neuere Version: der uebersprungene Stand kommt erneut.
        let payload = try #require(state.consumePending(for: newer, in: changelog))
        #expect(payload.releases.map(\.rawVersion) == ["0.8.4"])
    }
}
