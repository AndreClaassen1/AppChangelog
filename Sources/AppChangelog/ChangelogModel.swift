import SwiftUI

/// Art einer Changelog-Rubrik nach "Keep a Changelog". Erkennt deutsche und
/// englische Ueberschriften und liefert Anzeigelabel plus semantische Farbe.
public enum ChangelogSectionKind: String, Sendable, CaseIterable {
    case added
    case changed
    case deprecated
    case removed
    case fixed
    case security
    case other

    /// Ordnet eine Rubriken-Ueberschrift (ohne "### ") einer Art zu.
    public init(heading: String) {
        switch heading.trimmingCharacters(in: .whitespaces).lowercased() {
        case "added", "hinzugefügt", "hinzugefuegt", "neu":
            self = .added
        case "changed", "geändert", "geaendert":
            self = .changed
        case "deprecated", "veraltet":
            self = .deprecated
        case "removed", "entfernt":
            self = .removed
        case "fixed", "behoben", "fixes", "bugfixes":
            self = .fixed
        case "security", "sicherheit":
            self = .security
        default:
            self = .other
        }
    }

    /// Deutsches Anzeigelabel der Rubrik.
    public var label: String {
        switch self {
        case .added:      return "Hinzugefügt"
        case .changed:    return "Geändert"
        case .deprecated: return "Veraltet"
        case .removed:    return "Entfernt"
        case .fixed:      return "Behoben"
        case .security:   return "Sicherheit"
        case .other:      return "Sonstiges"
        }
    }

    /// Semantische Farbe fuer Label und Marker. Grün = Hinzugefügt,
    /// Blau = Geändert, Rot = Behoben; die uebrigen in abgestuften Toenen.
    public var color: Color {
        switch self {
        case .added:      return .green
        case .changed:    return .blue
        case .fixed:      return .red
        case .security:   return .purple
        case .deprecated: return .orange
        case .removed:    return .orange
        case .other:      return .secondary
        }
    }
}

/// Eine Rubrik innerhalb einer Version mit ihren Eintraegen.
public struct ChangelogSection: Identifiable, Sendable {
    public let id = UUID()
    public let kind: ChangelogSectionKind
    public let items: [String]

    public init(kind: ChangelogSectionKind, items: [String]) {
        self.kind = kind
        self.items = items
    }

    /// Ob die Rubrik Eintraege enthaelt (leere Rubriken werden ausgeblendet).
    public var hasItems: Bool { !items.isEmpty }
}

/// Eine Version im Changelog mit Datum und Rubriken.
public struct ChangelogRelease: Identifiable, Sendable {
    public let id = UUID()
    /// Roher Versionsname aus der Ueberschrift, z.B. "0.2.0" oder "Unreleased".
    public let rawVersion: String
    /// Geparste Version; `nil` fuer "Unreleased".
    public let version: SemanticVersion?
    /// Datum als roher String aus der Ueberschrift, z.B. "2026-07-22".
    public let date: String?
    public let sections: [ChangelogSection]

    public init(rawVersion: String, version: SemanticVersion?, date: String?, sections: [ChangelogSection]) {
        self.rawVersion = rawVersion
        self.version = version
        self.date = date
        self.sections = sections
    }

    /// Ob die Version echte Eintraege enthaelt (leere "Unreleased"-Bloecke
    /// werden in der Anzeige ausgeblendet).
    public var hasContent: Bool {
        sections.contains(where: \.hasItems)
    }
}

/// Der geparste Changelog: eine geordnete Liste von Versionen, neueste zuerst.
public struct Changelog: Sendable {
    public let releases: [ChangelogRelease]

    public init(releases: [ChangelogRelease]) {
        self.releases = releases
    }

    /// Nur veroeffentlichte Versionen mit Inhalt (ohne leere "Unreleased").
    public var publishedReleases: [ChangelogRelease] {
        releases.filter { $0.version != nil && $0.hasContent }
    }
}
