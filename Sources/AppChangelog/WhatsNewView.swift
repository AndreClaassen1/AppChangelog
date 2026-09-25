import SwiftUI

/// Kompaktes "Was ist neu"-Sheet, das nach einem Versionssprung nur die seither
/// hinzugekommenen Aenderungen zeigt. Bietet einen Weg zum vollen Verlauf und
/// zum Schliessen.
public struct WhatsNewView: View {
    let appName: String
    let currentVersion: SemanticVersion
    let previousVersion: SemanticVersion?
    let releases: [ChangelogRelease]
    let onShowAll: () -> Void
    let onClose: () -> Void

    public init(
        appName: String,
        currentVersion: SemanticVersion,
        previousVersion: SemanticVersion?,
        releases: [ChangelogRelease],
        onShowAll: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.appName = appName
        self.currentVersion = currentVersion
        self.previousVersion = previousVersion
        self.releases = releases
        self.onShowAll = onShowAll
        self.onClose = onClose
    }

    /// Alle Rubriken der neuen Versionen, nach Art zusammengefasst und in der
    /// kanonischen Reihenfolge von `ChangelogSectionKind`.
    private var mergedSections: [ChangelogSection] {
        let allSections = releases.flatMap(\.sections)
        return ChangelogSectionKind.allCases.compactMap { kind in
            let items = allSections.filter { $0.kind == kind }.flatMap(\.items)
            return items.isEmpty ? nil : ChangelogSection(kind: kind, items: items)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Label("Neu in \(appName) \(currentVersion.description)", systemImage: "sparkles")
                    .font(.title3.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                if let previousVersion {
                    Text("seit deiner Version \(previousVersion.description)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding([.top, .horizontal])
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(mergedSections) { section in
                        ChangelogSectionView(section: section)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }

            Divider()

            HStack {
                Button("Alle Änderungen ansehen", action: onShowAll)
                    .buttonStyle(.borderless)
                    .tint(.accentColor)
                Spacer()
                Button("Schließen", action: onClose)
                    // Siehe ChangelogView: auf watchOS nicht verfuegbar.
                    #if !os(watchOS)
                    .keyboardShortcut(.defaultAction)
                    #endif
            }
            .padding()
        }
        .frame(minWidth: 340, minHeight: 300)
    }
}
