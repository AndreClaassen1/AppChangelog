import Foundation

extension Changelog {

    /// Laedt und parst eine CHANGELOG.md aus einem Bundle. Liefert einen leeren
    /// Changelog, wenn die Ressource fehlt oder nicht lesbar ist.
    public static func load(
        resource: String = "CHANGELOG",
        withExtension ext: String = "md",
        in bundle: Bundle = .main
    ) -> Changelog {
        guard
            let url = bundle.url(forResource: resource, withExtension: ext),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return Changelog(releases: [])
        }
        return ChangelogParser.parse(text)
    }

    /// Veroeffentlichte Versionen, die neuer als `version` sind (aufsteigend
    /// gefiltert, Reihenfolge bleibt neueste-zuerst). Basis fuer "Was ist neu".
    public func releases(newerThan version: SemanticVersion?) -> [ChangelogRelease] {
        guard let version else { return publishedReleases }
        return publishedReleases.filter { release in
            guard let v = release.version else { return false }
            return v > version
        }
    }
}
