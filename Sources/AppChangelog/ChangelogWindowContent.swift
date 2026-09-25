import SwiftUI

/// Inhalt eines Changelog-**Fensters**: zeigt nach einem Versionssprung zuerst
/// die neuen Aenderungen und schaltet auf Wunsch im selben Fenster auf den
/// vollen Verlauf um.
///
/// Fuer Menuebar-Apps: `whatsNewOnLaunch` und `changelogSheet` taugen im Inhalt
/// eines `MenuBarExtra(.window)` nicht, weil das Popover kein Sheet traegt
/// (Begruendung in der README). Ein eigenes `Window`-Scene loest das, und
/// dessen Inhalt ist bis auf App-Name und Schliessen-Aktion immer derselbe.
///
/// Die `Window`-Scene selbst bleibt Sache der App: Fenster-ID, Groesse und der
/// Ausloeser beim Start haengen an ihren eigenen Typen.
public struct ChangelogWindowContent: View {
    let appName: String
    let changelog: Changelog
    let currentVersion: SemanticVersion?
    @Binding var whatsNew: WhatsNewPayload?
    let onClose: () -> Void

    /// - Parameters:
    ///   - whatsNew: Ergebnis von `WhatsNewState.consumePending(for:in:)`.
    ///     Gesetzt = die neuen Aenderungen, `nil` = der volle Verlauf.
    public init(
        appName: String,
        changelog: Changelog,
        currentVersion: SemanticVersion?,
        whatsNew: Binding<WhatsNewPayload?>,
        onClose: @escaping () -> Void
    ) {
        self.appName = appName
        self.changelog = changelog
        self.currentVersion = currentVersion
        self._whatsNew = whatsNew
        self.onClose = onClose
    }

    public var body: some View {
        if let payload = whatsNew, let currentVersion {
            WhatsNewView(
                appName: appName,
                currentVersion: currentVersion,
                previousVersion: payload.previous,
                releases: payload.releases,
                onShowAll: { whatsNew = nil },
                onClose: onClose
            )
            // Raeumt den Hinweis auch ab, wenn das Fenster ueber den roten Knopf
            // oder Cmd+W geht — sonst zeigt ein spaeterer Aufruf des vollen
            // Verlaufs wieder ihn statt des Verlaufs.
            .onDisappear { whatsNew = nil }
        } else {
            ChangelogView(
                changelog: changelog,
                currentVersion: currentVersion,
                onClose: onClose
            )
        }
    }
}
