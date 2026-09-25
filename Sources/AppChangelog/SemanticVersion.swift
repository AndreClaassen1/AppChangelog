import Foundation

/// Eine dreiteilige Marketing-Version (major.minor.patch) nach SemVer.
///
/// Build-Nummern sind bewusst kein Bestandteil: der Changelog gruppiert nur
/// nach Marketing-Version. Ein optionaler vierter Bestandteil im String (etwa
/// "1.2.3.45") wird toleriert, aber ignoriert.
public struct SemanticVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parst "1.2.3", "v1.2" oder "1" (fehlende Stellen werden 0). Gibt `nil`
    /// zurueck, wenn keine fuehrende Zahl gefunden wird (z.B. "Unreleased").
    public init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespaces)
        if text.first == "v" || text.first == "V" { text.removeFirst() }
        let parts = text.split(separator: ".")
        guard let first = parts.first, let major = Int(first) else { return nil }
        self.major = major
        self.minor = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        self.patch = parts.count > 2 ? Int(parts[2]) ?? 0 : 0
    }

    public var description: String { "\(major).\(minor).\(patch)" }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
