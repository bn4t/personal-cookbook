import Foundation

/// A merged line item in the shopping list.
struct ShoppingItem: Identifiable, Hashable {
    let id: String
    var name: String
    var amount: Double?
    var unit: String?
    var category: ShoppingCategory
    var fromRecipes: [String]

    /// Display amount, e.g. "2 cups" or "" when not quantified.
    var amountText: String {
        guard let amount else { return "" }
        let value = ScalingHelpers.format(amount)
        if let unit, !unit.isEmpty { return "\(value) \(unit)" }
        return value
    }
}

/// A section of the shopping list for one aisle/category.
struct ShoppingSection: Identifiable {
    let category: ShoppingCategory
    var items: [ShoppingItem]
    var id: String { category.id }
}

enum ShoppingListHelpers {

    /// Build a grouped, de-duplicated shopping list from selected recipes and
    /// their desired serving counts. Optional ingredients are included but
    /// quantities scale to each recipe's target servings.
    static func build(from selections: [(recipe: Recipe, servings: Int)]) -> [ShoppingSection] {
        var merged: [String: ShoppingItem] = [:]

        for selection in selections {
            let factor = ScalingHelpers.factor(base: selection.recipe.servings, target: selection.servings)
            for ingredient in selection.recipe.allIngredients {
                let scaled = ScalingHelpers.scaled(ingredient, factor: factor)
                let key = mergeKey(scaled)

                if var existing = merged[key] {
                    // Same item + unit → sum amounts.
                    if let a = existing.amount, let b = scaled.amount {
                        existing.amount = a + b
                    } else if existing.amount == nil {
                        existing.amount = scaled.amount
                    }
                    if !existing.fromRecipes.contains(selection.recipe.name) {
                        existing.fromRecipes.append(selection.recipe.name)
                    }
                    merged[key] = existing
                } else {
                    merged[key] = ShoppingItem(
                        id: key,
                        name: scaled.name,
                        amount: scaled.amount,
                        unit: scaled.unit,
                        category: scaled.shoppingCategory,
                        fromRecipes: [selection.recipe.name]
                    )
                }
            }
        }

        // Group by category, preserving canonical aisle order.
        let grouped = Dictionary(grouping: merged.values, by: \.category)
        return ShoppingCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let sorted = items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return ShoppingSection(category: category, items: sorted)
        }
    }

    /// Items merge when their normalized name + unit match. Differing units stay
    /// separate (you can't add "2 cloves" to "1 tbsp").
    private static func mergeKey(_ ingredient: Ingredient) -> String {
        let name = ingredient.name.lowercased().trimmingCharacters(in: .whitespaces)
        let unit = (ingredient.unit ?? "").lowercased().trimmingCharacters(in: .whitespaces)
        return "\(name)#\(unit)"
    }
}
