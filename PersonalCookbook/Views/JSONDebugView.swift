import SwiftUI

/// Developer-only screen to inspect, import, and export the recipe JSON, and to
/// surface Codable validation errors. Reached from the Library overflow menu —
/// intentionally out of the main flow.
struct JSONDebugView: View {
    @Environment(RecipeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var validation: Validation = .idle

    enum Validation: Equatable {
        case idle, ok(Int), error(String)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                statusBanner

                TextEditor(text: $text)
                    .font(.system(.footnote, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .glassCard(cornerRadius: 18, padding: 0)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                controls
            }
            .padding(16)
            .cookbookBackground()
            .navigationTitle("JSON Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear { if text.isEmpty { text = store.exportJSON() } }
        }
    }

    private var statusBanner: some View {
        Group {
            switch validation {
            case .idle:
                banner("\(store.recipes.count) recipes currently loaded", icon: "info.circle", tint: Theme.slate)
            case .ok(let n):
                banner("Valid · \(n) recipes parsed", icon: "checkmark.seal.fill", tint: Theme.green)
            case .error(let msg):
                banner(msg, icon: "exclamationmark.triangle.fill", tint: Theme.coral)
            }
        }
    }

    private func banner(_ message: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(message).font(.footnote).foregroundStyle(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(tint.opacity(0.28), lineWidth: 0.8))
    }

    private var controls: some View {
        HStack(spacing: 10) {
            actionButton("Validate", icon: "checkmark.circle", tint: Theme.sky) { validate() }
            actionButton("Import", icon: "square.and.arrow.down", tint: Theme.green) {
                if let err = store.importJSON(text) { validation = .error(err) }
                else { validation = .ok(store.recipes.count) }
            }
            actionButton("Reload", icon: "arrow.clockwise", tint: Theme.amber) {
                store.load()
                text = store.exportJSON()
                validation = store.loadError.map(Validation.error) ?? .ok(store.recipes.count)
            }
        }
    }

    private func actionButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.headline)
                Text(title).font(.caption.weight(.semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassControl(RoundedRectangle(cornerRadius: 16, style: .continuous), tint: nil)
        }
        .buttonStyle(.plain)
    }

    private func validate() {
        guard let data = text.data(using: .utf8) else {
            validation = .error("Text is not valid UTF-8."); return
        }
        do {
            let recipes = try JSONDecoder().decode([Recipe].self, from: data)
            validation = .ok(recipes.count)
        } catch {
            validation = .error(RecipeStore.describe(error))
        }
    }
}
