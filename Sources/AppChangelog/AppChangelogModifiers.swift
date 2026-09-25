import SwiftUI

/// Praesentiert die vollstaendige Changelog-Ansicht in einem Sheet. Fuer den
/// jederzeit erreichbaren "Was ist neu"-Link (etwa in der Build-Fusszeile).
public struct ChangelogSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let changelog: Changelog
    let currentVersion: SemanticVersion?

    public func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            ChangelogView(changelog: changelog, currentVersion: currentVersion) {
                isPresented = false
            }
            .frame(minWidth: 420, minHeight: 460)
        }
    }
}

/// Zeigt nach einem Versionssprung einmalig ein "Was ist neu"-Sheet und
/// verlinkt von dort in den vollen Verlauf. Merkt die aktuelle Version als
/// gesehen, damit der Hinweis nur einmal erscheint. Beim Erststart bleibt es
/// still.
public struct WhatsNewLaunchModifier: ViewModifier {
    let appName: String
    let currentVersion: SemanticVersion
    let changelog: Changelog
    let state: WhatsNewState

    /// Inhalt und Praesentation als EIN Wert: `sheet(item:)` traegt seine Daten
    /// selbst und kann nicht mit dem Zustand auseinanderlaufen, der ihn zeigt.
    @State private var whatsNew: WhatsNewPayload?
    @State private var showFullChangelog = false

    public func body(content: Content) -> some View {
        content
            .onAppear {
                // Merkt die Version gleich mit: ein zweiter onAppear-Durchlauf
                // liefert dann nil und zeigt nichts erneut.
                whatsNew = state.consumePending(for: currentVersion, in: changelog)
            }
            .sheet(item: $whatsNew) { payload in
                WhatsNewView(
                    appName: appName,
                    currentVersion: currentVersion,
                    previousVersion: payload.previous,
                    releases: payload.releases,
                    onShowAll: {
                        whatsNew = nil
                        showFullChangelog = true
                    },
                    onClose: { whatsNew = nil }
                )
            }
            .modifier(ChangelogSheetModifier(
                isPresented: $showFullChangelog,
                changelog: changelog,
                currentVersion: currentVersion
            ))
    }
}

public extension View {
    /// Praesentiert den vollen Changelog in einem Sheet, gesteuert ueber
    /// `isPresented` (z.B. von einem Link in der Fusszeile).
    func changelogSheet(
        isPresented: Binding<Bool>,
        changelog: Changelog,
        currentVersion: SemanticVersion?
    ) -> some View {
        modifier(ChangelogSheetModifier(isPresented: isPresented, changelog: changelog, currentVersion: currentVersion))
    }

    /// Zeigt nach einem Versionssprung einmalig ein "Was ist neu"-Sheet. Ist
    /// `currentVersion` nil (etwa bei Dev-Builds ohne Marketing-Version),
    /// passiert nichts.
    @ViewBuilder
    func whatsNewOnLaunch(
        appName: String,
        currentVersion: SemanticVersion?,
        changelog: Changelog,
        state: WhatsNewState = WhatsNewState()
    ) -> some View {
        if let currentVersion {
            modifier(WhatsNewLaunchModifier(appName: appName, currentVersion: currentVersion, changelog: changelog, state: state))
        } else {
            self
        }
    }
}
