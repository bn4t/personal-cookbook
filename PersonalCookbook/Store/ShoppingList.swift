import SwiftUI
import Observation

/// Shared, session-scoped shopping selection so recipes can be added to the list
/// from anywhere (the recipe detail or the Shopping tab) and stay in sync.
@Observable
final class ShoppingList {
    /// recipeID -> chosen servings. Presence means "on the list".
    var selection: [String: Int] = [:]
    /// IDs of shopping items the user has ticked off.
    var checked: Set<String> = []

    func contains(_ recipeID: String) -> Bool { selection[recipeID] != nil }

    /// Add a recipe at a given serving count (defaults to its base servings).
    func add(_ recipe: Recipe, servings: Int? = nil) {
        selection[recipe.id] = servings ?? recipe.servings
    }

    func remove(_ recipeID: String) {
        selection[recipeID] = nil
    }

    func toggle(_ recipe: Recipe, servings: Int? = nil) {
        if contains(recipe.id) { remove(recipe.id) }
        else { add(recipe, servings: servings) }
    }

    var isEmpty: Bool { selection.isEmpty }
    var recipeCount: Int { selection.count }

    /// Plain-text version of the list for sharing.
    func shareText(sections: [ShoppingSection]) -> String {
        var lines = ["Shopping list"]
        for section in sections {
            lines.append("")
            lines.append(section.category.label.uppercased())
            for item in section.items {
                let amount = item.amountText.isEmpty ? "" : " — \(item.amountText)"
                lines.append("• \(item.name)\(amount)")
            }
        }
        return lines.joined(separator: "\n")
    }
}
