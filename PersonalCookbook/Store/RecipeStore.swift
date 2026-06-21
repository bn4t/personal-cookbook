import SwiftUI
import Observation

/// Loads recipes from the bundled `recipes.json` and holds them in memory.
/// Local-first: no network, no persistence layer beyond the bundle. Importing
/// JSON from the debug screen replaces the in-memory set for the session.
@Observable
final class RecipeStore {
    private(set) var recipes: [Recipe] = []
    private(set) var loadError: String?

    /// The raw JSON text that backs the current recipe set (for the debug screen).
    private(set) var rawJSON: String = ""

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            loadError = "recipes.json not found in app bundle."
            recipes = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            rawJSON = String(data: data, encoding: .utf8) ?? ""
            recipes = try Self.decoder.decode([Recipe].self, from: data)
            loadError = nil
        } catch {
            loadError = Self.describe(error)
            recipes = []
        }
    }

    /// Replace the in-memory recipes by decoding pasted JSON. Returns nil on
    /// success, or a human-readable validation error message on failure.
    @discardableResult
    func importJSON(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return "Text is not valid UTF-8." }
        do {
            let decoded = try Self.decoder.decode([Recipe].self, from: data)
            recipes = decoded
            rawJSON = text
            loadError = nil
            return nil
        } catch {
            return Self.describe(error)
        }
    }

    /// Current recipes serialized back to pretty JSON, for export/inspection.
    func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(recipes),
              let text = String(data: data, encoding: .utf8) else {
            return "// Unable to encode recipes."
        }
        return text
    }

    func recipe(id: String) -> Recipe? { recipes.first { $0.id == id } }

    var categories: [String] {
        Array(Set(recipes.map(\.category))).sorted()
    }

    // MARK: - Helpers

    private static let decoder = JSONDecoder()

    /// Turns a Codable error into a readable, location-aware message.
    static func describe(_ error: Error) -> String {
        switch error {
        case let DecodingError.keyNotFound(key, ctx):
            return "Missing key '\(key.stringValue)' at \(path(ctx))."
        case let DecodingError.typeMismatch(_, ctx):
            return "Type mismatch at \(path(ctx)): \(ctx.debugDescription)"
        case let DecodingError.valueNotFound(_, ctx):
            return "Missing value at \(path(ctx)): \(ctx.debugDescription)"
        case let DecodingError.dataCorrupted(ctx):
            return "Corrupted data at \(path(ctx)): \(ctx.debugDescription)"
        default:
            return error.localizedDescription
        }
    }

    private static func path(_ ctx: DecodingError.Context) -> String {
        let p = ctx.codingPath.map(\.stringValue).joined(separator: " › ")
        return p.isEmpty ? "root" : p
    }
}
