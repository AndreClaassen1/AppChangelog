import Testing
@testable import AppChangelog

@Suite("SemanticVersion")
struct SemanticVersionTests {

    @Test("Parst dreiteilige Versionen")
    func parsesFullVersion() {
        #expect(SemanticVersion("1.2.3") == SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    @Test("Fuellt fehlende Stellen mit Null und toleriert v-Praefix")
    func parsesPartialAndPrefixed() {
        #expect(SemanticVersion("2") == SemanticVersion(major: 2, minor: 0, patch: 0))
        #expect(SemanticVersion("v1.4") == SemanticVersion(major: 1, minor: 4, patch: 0))
    }

    @Test("Ignoriert eine angehaengte Build-Nummer")
    func ignoresBuildNumber() {
        #expect(SemanticVersion("1.2.3.45") == SemanticVersion(major: 1, minor: 2, patch: 3))
    }

    @Test("Nicht-numerische Namen ergeben nil")
    func rejectsNonNumeric() {
        #expect(SemanticVersion("Unreleased") == nil)
    }

    @Test("Vergleich ordnet nach major, minor, patch")
    func comparesCorrectly() {
        #expect(SemanticVersion("1.0.0")! < SemanticVersion("1.0.1")!)
        #expect(SemanticVersion("1.2.0")! < SemanticVersion("2.0.0")!)
        #expect(SemanticVersion("0.2.0")! > SemanticVersion("0.1.9")!)
    }
}
