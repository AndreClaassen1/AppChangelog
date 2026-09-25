import Foundation

/// Merkt sich die zuletzt vom Nutzer gesehene Version, um nach einem
/// Versionssprung einmalig die neuen Aenderungen anzuzeigen.
///
/// Persistiert wird nur die Marketing-Version als String in `UserDefaults`.
public struct WhatsNewState {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "AppChangelog.lastSeenVersion") {
        self.defaults = defaults
        self.key = key
    }

    /// Die zuletzt gesehene Version, oder `nil` beim allerersten Start.
    public var lastSeenVersion: SemanticVersion? {
        defaults.string(forKey: key).flatMap(SemanticVersion.init)
    }

    /// Merkt die aktuelle Version als gesehen.
    public func markSeen(_ version: SemanticVersion) {
        defaults.set(version.description, forKey: key)
    }

    /// Ob nach einem Versionssprung ein "Was ist neu"-Hinweis faellig ist:
    /// nur wenn schon einmal eine aeltere Version gesehen wurde und der
    /// Changelog dazwischenliegende Versionen kennt. Beim Erststart (keine
    /// gemerkte Version) wird bewusst nichts gezeigt.
    ///
    /// Nur ein Teilschritt: Wer den Hinweis praesentiert, nimmt
    /// `consumePending(for:in:)` — das merkt die Version gleich mit.
    func pendingReleases(for current: SemanticVersion, in changelog: Changelog) -> [ChangelogRelease] {
        guard let last = lastSeenVersion, last < current else { return [] }
        return releases(since: last, upTo: current, in: changelog)
    }

    /// Die Versionen zwischen zwei bekannten Staenden. Nimmt die Vorversion als
    /// Argument, damit `consumePending` sie nicht ein zweites Mal aus den
    /// `UserDefaults` lesen muss.
    private func releases(
        since last: SemanticVersion,
        upTo current: SemanticVersion,
        in changelog: Changelog
    ) -> [ChangelogRelease] {
        changelog.releases(newerThan: last).filter {
            guard let v = $0.version else { return false }
            return v <= current
        }
    }

    /// Ermittelt die faelligen Aenderungen und merkt die aktuelle Version in
    /// einem Schritt als gesehen. Liefert `nil`, wenn nichts zu zeigen ist.
    ///
    /// Das ist die vollstaendige Regel "ist ein Was-ist-neu faellig" und der
    /// einzige Weg, sie anzuwenden — auch dann, wenn der Hinweis nicht als
    /// Sheet erscheint, sondern als eigenes Fenster (siehe README).
    ///
    /// Gemerkt wird auch, wenn nichts angezeigt wird: so bleibt der Erststart
    /// still, der naechste Sprung greift trotzdem, und nach einem Downgrade
    /// zeigt ein spaeteres Update die uebersprungenen Versionen erneut.
    ///
    /// `changelog` ist eine Autoclosure: ohne Sprung nach vorn wird das
    /// Markdown gar nicht erst gelesen, und das ist der Regelfall beim Start.
    public func consumePending(
        for current: SemanticVersion,
        in changelog: @autoclosure () -> Changelog
    ) -> WhatsNewPayload? {
        let previous = lastSeenVersion

        // Schon einmal mit genau dieser Version gestartet: denselben Wert nicht
        // erneut schreiben.
        guard previous != current else { return nil }
        markSeen(current)

        // Erststart und Downgrade zeigen nichts — und lassen den Changelog zu.
        guard let previous, previous < current else { return nil }

        let pending = releases(since: previous, upTo: current, in: changelog())
        guard !pending.isEmpty else { return nil }
        return WhatsNewPayload(previous: previous, releases: pending)
    }
}

/// Die seit der zuletzt gesehenen Version dazugekommenen Aenderungen, samt der
/// Version, von der aus gesprungen wurde.
///
/// `Identifiable` fuer `sheet(item:)`: Inhalt und Praesentation bleiben dadurch
/// ein Wert und koennen nicht auseinanderlaufen.
public struct WhatsNewPayload: Identifiable, Sendable {
    public let id = UUID()
    /// Die zuvor gesehene Version, `nil` wenn es keine gab.
    public let previous: SemanticVersion?
    /// Die neuen Versionen, neueste zuerst.
    public let releases: [ChangelogRelease]

    public init(previous: SemanticVersion?, releases: [ChangelogRelease]) {
        self.previous = previous
        self.releases = releases
    }
}
