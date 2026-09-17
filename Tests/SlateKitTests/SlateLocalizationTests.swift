import Foundation
import Testing

@testable import SlateKit

/// The package has two customers and they are not at the same point.
/// **Selector ships German**; Shelf is English until its own Sprint 7. A
/// package that draws nine words of its own therefore has to have all nine in
/// both languages — dropping the German (as 0.3.0 did) takes those words out of
/// a shipping app's own language, and adding an English one without its German
/// puts a tenth word into the middle of a German window.
///
/// Both of those are failures a person only ever finds by running the app in
/// German, which is why they are tests.
@Suite("The package speaks both languages")
struct SlateLocalizationTests {
    /// The package root, from this file's own path. The catalogue is read as a
    /// *file* rather than through `Bundle.module`, because the question is what
    /// the repository holds: a catalogue with a missing translation still builds
    /// into a perfectly valid bundle, falls back to English at runtime, and says
    /// nothing about it.
    private static let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // SlateKitTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // the package

    private static let catalogueURL =
        packageRoot
        .appending(path: "Sources/SlateKit/Resources/Localizable.xcstrings")

    private static func catalogue() throws -> [String: Any] {
        let data = try Data(contentsOf: catalogueURL)
        let json = try JSONSerialization.jsonObject(with: data)
        return json as? [String: Any] ?? [:]
    }

    private static func strings() throws -> [String: Any] {
        try catalogue()["strings"] as? [String: Any] ?? [:]
    }

    /// The German value for a key, or `nil` if there is none worth having.
    private static func german(_ entry: Any) -> String? {
        guard let entry = entry as? [String: Any],
            let localizations = entry["localizations"] as? [String: Any],
            let de = localizations["de"] as? [String: Any],
            let unit = de["stringUnit"] as? [String: Any],
            let value = unit["value"] as? String, !value.isEmpty
        else { return nil }
        // A unit still marked `new` or `needs_review` is a translation somebody
        // meant to come back to, and it ships as English until they do.
        guard (unit["state"] as? String) == "translated" else { return nil }
        return value
    }

    @Test("the catalogue is there at all")
    func catalogueExists() throws {
        #expect(FileManager.default.fileExists(atPath: Self.catalogueURL.path))
        #expect(try Self.catalogue()["sourceLanguage"] as? String == "en")
        #expect(try !Self.strings().isEmpty)
    }

    /// The test the removal in 0.3.0 would have failed.
    @Test("every string in the catalogue has a German translation")
    func everyStringIsTranslated() throws {
        let untranslated = try Self.strings()
            .filter { Self.german($0.value) == nil }
            .keys
            .sorted()
        #expect(untranslated.isEmpty, "no German for: \(untranslated.joined(separator: ", "))")
    }

    /// Every `String(localized: "…", bundle: .module)` in the sources whose key
    /// is a plain literal. The interpolated ones cannot be read off the source
    /// — `\(rating)/5` becomes `%lld/5` only once the compiler knows the type —
    /// so they are named in the test below instead of guessed at here.
    @Test("a string the package draws is a string the catalogue knows")
    func everyDrawnStringIsInTheCatalogue() throws {
        let keys = Set(try Self.strings().keys)
        var missing: [String] = []
        for file in try Self.swiftSources() {
            let text = try String(contentsOf: file, encoding: .utf8)
            for literal in Self.literalKeys(in: text) where !keys.contains(literal) {
                missing.append("\(file.lastPathComponent): \(literal)")
            }
        }
        #expect(missing.isEmpty, "drawn but not in the catalogue: \(missing.joined(separator: ", "))")
    }

    /// The four keys the compiler builds out of an interpolation, spelled out.
    /// If one of these is renamed the call site still compiles and the window
    /// quietly goes back to English, so the list is the only guard there is.
    @Test("the interpolated keys are the ones the compiler produces")
    func interpolatedKeys() throws {
        let keys = Set(try Self.strings().keys)
        for key in ["%lld/5", "%lld of 5", "%1$lld stars (%2$lld)", "Remove %@"] {
            #expect(keys.contains(key), "the catalogue has lost \(key)")
        }
    }

    /// Spot-checked rather than asserted wholesale: a test that repeated every
    /// translation would be the catalogue written twice, and would have to be
    /// edited by whoever changes a wording — which is how a test stops being
    /// read and starts being updated to match.
    @Test("the German is German")
    func germanIsGerman() throws {
        let strings = try Self.strings()
        #expect(Self.german(strings["Unrated"] as Any) == "Ohne Bewertung")
        #expect(Self.german(strings["Remove"] as Any) == "Entfernen")
        #expect(Self.german(strings["Close"] as Any) == "Schließen")
        #expect(Self.german(strings["Rating"] as Any) == "Bewertung")
    }

    // MARK: Reading the sources

    private static func swiftSources() throws -> [URL] {
        let sources = packageRoot.appending(path: "Sources/SlateKit")
        return try FileManager.default
            .contentsOfDirectory(at: sources, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
            .sorted { $0.path < $1.path }
    }

    /// `String(localized: "…"` with nothing interpolated in it.
    ///
    /// Deliberately a small scan rather than a parse: it has one job, it is read
    /// by the person who adds the tenth string, and a regular expression over
    /// nine call sites is easier to be sure about than a syntax tree.
    static func literalKeys(in source: String) -> [String] {
        let marker = "String(localized: \""
        var keys: [String] = []
        var rest = Substring(source)
        while let start = rest.range(of: marker) {
            rest = rest[start.upperBound...]
            guard let end = rest.firstIndex(of: "\"") else { break }
            let key = String(rest[..<end])
            // An interpolation, a comment's prose, or an escape this scan is not
            // clever enough to read back: named in the test above instead.
            if !key.contains("\\("), !key.isEmpty { keys.append(key) }
            rest = rest[end...]
        }
        return keys
    }
}
