import Testing
@testable import AppChangelog

private let sample = """
# Changelog

Etwas einleitender Fliesstext, der ignoriert wird.

## [Unreleased]

## [0.2.0] – 2026-07-22
### Hinzugefügt
- Projekte als Einstieg
- Vollbild beim Start
### Geändert
- Harter Modus ist Standard
### Behoben
- Migration für Bestandsinstallationen

## [0.1.0] - 2026-06-26
### Added
- Flow-Engine mit Sicherheitsanker

[Unreleased]: https://example.com/compare/v0.2.0...main
[0.2.0]: https://example.com/compare/v0.1.0...v0.2.0
"""

@Suite("ChangelogParser")
struct ChangelogParserTests {

    @Test("Erkennt alle Versionsbloecke inklusive Unreleased")
    func parsesAllReleases() {
        let log = ChangelogParser.parse(sample)
        #expect(log.releases.count == 3)
        #expect(log.releases.map(\.rawVersion) == ["Unreleased", "0.2.0", "0.1.0"])
    }

    @Test("Leeres Unreleased zaehlt nicht als veroeffentlicht")
    func publishedReleasesSkipEmptyUnreleased() {
        let log = ChangelogParser.parse(sample)
        #expect(log.publishedReleases.map(\.rawVersion) == ["0.2.0", "0.1.0"])
    }

    @Test("Parst Datum und trennt es von der Versionsnummer")
    func parsesDate() {
        let log = ChangelogParser.parse(sample)
        let v020 = log.releases.first { $0.rawVersion == "0.2.0" }
        #expect(v020?.date == "2026-07-22")
        #expect(v020?.version == SemanticVersion(major: 0, minor: 2, patch: 0))
    }

    @Test("Rubriken und Eintraege werden korrekt zugeordnet")
    func parsesSections() {
        let log = ChangelogParser.parse(sample)
        let v020 = log.releases.first { $0.rawVersion == "0.2.0" }
        #expect(v020?.sections.count == 3)
        let added = v020?.sections.first { $0.kind == .added }
        #expect(added?.items == ["Projekte als Einstieg", "Vollbild beim Start"])
        #expect(v020?.sections.first { $0.kind == .fixed }?.items == ["Migration für Bestandsinstallationen"])
    }

    @Test("Englische Rubriken werden ebenfalls erkannt")
    func parsesEnglishHeadings() {
        let log = ChangelogParser.parse(sample)
        let v010 = log.releases.first { $0.rawVersion == "0.1.0" }
        #expect(v010?.sections.first?.kind == .added)
    }

    @Test("releases(newerThan:) liefert nur neuere Versionen")
    func filtersNewerReleases() {
        let log = ChangelogParser.parse(sample)
        let newer = log.releases(newerThan: SemanticVersion(major: 0, minor: 1, patch: 0))
        #expect(newer.map(\.rawVersion) == ["0.2.0"])
    }
}

@Suite("Umbrochene Eintraege")
struct UmbrocheneEintraegeTests {

    /// Keep-a-Changelog-Dateien brechen lange Punkte um. Frueher endete ein
    /// Eintrag an der ersten Umbruchstelle, in der App standen halbe Saetze.
    @Test("Fortsetzungszeilen gehoeren zum selben Eintrag")
    func fortsetzungszeilen() {
        let markdown = """
        ## [1.1.0] – 2026-07-26

        ### Behoben
        - Die Komplikation aktualisiert sich jetzt von selbst. Bisher zeigte sie
          den Stand des letzten Besuchs, oft stundenalt.
        - Ein zweiter Punkt.
        """

        let changelog = ChangelogParser.parse(markdown)
        let items = changelog.releases.first?.sections.first?.items ?? []

        #expect(items.count == 2)
        #expect(items.first?.hasSuffix("oft stundenalt.") == true)
        #expect(items.last == "Ein zweiter Punkt.")
    }

    /// Fliesstext ausserhalb einer Rubrik darf nicht an einen Eintrag geraten.
    @Test("Text vor der ersten Rubrik bleibt draussen")
    func fliesstextBleibtDraussen() {
        let markdown = """
        # Changelog

        Alle nennenswerten Aenderungen.

        ## [1.0.0] – 2026-01-01

        ### Hinzugefügt
        - Erste Fassung.
        """

        let changelog = ChangelogParser.parse(markdown)
        #expect(changelog.releases.first?.sections.first?.items == ["Erste Fassung."])
    }
}
