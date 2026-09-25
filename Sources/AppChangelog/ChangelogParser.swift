import Foundation

/// Parst eine CHANGELOG.md im Format "Keep a Changelog".
///
/// Erkannt werden Versions-Ueberschriften (`## [1.2.0] - 2026-07-22`),
/// Rubriken (`### Hinzugefügt`) und Listeneintraege (`- ...`), auch ueber
/// mehrere Zeilen umbrochen. Link-Referenzen am Dateiende
/// (`[1.2.0]: https://...`) und einleitender Fliesstext werden ignoriert.
public enum ChangelogParser {

    public static func parse(_ markdown: String) -> Changelog {
        var releases: [ChangelogRelease] = []

        var currentRawVersion: String?
        var currentDate: String?
        var currentKind: ChangelogSectionKind?
        var currentItems: [String] = []
        var currentSections: [ChangelogSection] = []

        func flushSection() {
            if let kind = currentKind, !currentItems.isEmpty {
                currentSections.append(ChangelogSection(kind: kind, items: currentItems))
            }
            currentItems = []
            currentKind = nil
        }

        func flushRelease() {
            flushSection()
            if let raw = currentRawVersion {
                releases.append(ChangelogRelease(
                    rawVersion: raw,
                    version: SemanticVersion(raw),
                    date: currentDate,
                    sections: currentSections
                ))
            }
            currentSections = []
            currentDate = nil
            currentRawVersion = nil
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("## ") {
                flushRelease()
                let (name, date) = parseVersionHeading(String(line.dropFirst(3)))
                currentRawVersion = name
                currentDate = date
            } else if line.hasPrefix("### ") {
                flushSection()
                currentKind = ChangelogSectionKind(heading: String(line.dropFirst(4)))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                guard currentKind != nil else { continue }
                currentItems.append(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
            } else if !line.isEmpty, currentKind != nil, !currentItems.isEmpty {
                // Fortsetzungszeile eines umbrochenen Eintrags. Ohne das endet
                // jeder Punkt an der ersten Zeilenumbruchstelle — der Rest fiel
                // still unter den Tisch, und in der App standen halbe Saetze.
                currentItems[currentItems.count - 1] += " " + line
            }
        }
        flushRelease()

        return Changelog(releases: releases)
    }

    /// Zerlegt "[1.2.0] - 2026-07-22" in Versionsname und Datum. Klammern und
    /// diverse Trenner (Bindestrich, Halbgeviert-/Geviertstrich) werden geduldet.
    private static func parseVersionHeading(_ text: String) -> (name: String, date: String?) {
        let separators = CharacterSet(charactersIn: "-–—")
        var name = text
        var date: String?

        if let range = text.rangeOfCharacter(from: separators) {
            name = String(text[..<range.lowerBound])
            date = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if date?.isEmpty == true { date = nil }
        }

        name = name.trimmingCharacters(in: CharacterSet(charactersIn: " []"))
        return (name, date)
    }
}
