import SwiftUI

/// Rendert eine Rubrik: farbiges Label und darunter die Eintraege mit farbigem
/// Marker. Gemeinsam genutzt von der vollen Ansicht und dem "Was ist neu"-Sheet.
public struct ChangelogSectionView: View {
    let section: ChangelogSection

    public init(section: ChangelogSection) {
        self.section = section
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.kind.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(section.kind.color)
            ForEach(section.items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Circle()
                        .fill(section.kind.color)
                        .frame(width: 4, height: 4)
                        .padding(.top, 5)
                    Text(item)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Rendert eine einzelne Version: Kopf mit Versionsnummer, Datum und optionaler
/// "aktuell"-Markierung, darunter die Rubriken mit farbigen Labels.
public struct ChangelogReleaseRow: View {
    let release: ChangelogRelease
    let isCurrent: Bool

    public init(release: ChangelogRelease, isCurrent: Bool) {
        self.release = release
        self.isCurrent = isCurrent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(release.rawVersion)
                    .font(.headline)
                if let date = release.date {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if isCurrent {
                    Text("aktuell")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }

            ForEach(release.sections.filter(\.hasItems)) { section in
                ChangelogSectionView(section: section)
            }
        }
    }
}

/// Vollstaendige Changelog-Ansicht: alle veroeffentlichten Versionen, neueste
/// oben und als "aktuell" markiert. Enthaelt einen Kopf mit Titel und
/// Schliessen-Aktion, damit sie direkt in einem Sheet nutzbar ist.
public struct ChangelogView: View {
    let changelog: Changelog
    let currentVersion: SemanticVersion?
    let onClose: (() -> Void)?

    public init(changelog: Changelog, currentVersion: SemanticVersion? = nil, onClose: (() -> Void)? = nil) {
        self.changelog = changelog
        self.currentVersion = currentVersion
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Änderungsverlauf")
                    .font(.title3.weight(.semibold))
                Spacer()
                if let onClose {
                    Button("Fertig", action: onClose)
                        // `keyboardShortcut` gibt es auf watchOS nicht, und das
                        // Paket deklariert watchOS als unterstuetzte Plattform.
                        #if !os(watchOS)
                        .keyboardShortcut(.defaultAction)
                        #endif
                }
            }
            .padding()

            Divider()

            ScrollView {
                let published = changelog.publishedReleases
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(published.enumerated()), id: \.element.id) { index, release in
                        ChangelogReleaseRow(release: release, isCurrent: release.version == currentVersion)
                        if index < published.count - 1 {
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }
}
