import SwiftUI

// MARK: - Recipe

/// A single cookable recipe. Decoded directly from bundled JSON via `Codable`.
/// All fields except the core identity ones are optional-tolerant so the JSON
/// can grow over time without breaking older recipes.
struct Recipe: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var description: String
    var whyCookThis: String
    var category: String
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var difficulty: Difficulty
    var energyLevel: EnergyLevel
    var batchFriendly: Bool
    var vegetarian: Bool
    var highProtein: Bool
    var tags: [String]
    var ingredientGroups: [IngredientGroup]
    var steps: [CookingStep]
    var tasteFixes: [TasteFix]
    var easyUpgrades: [String]
    var batchNotes: String
    var safetyNotes: [String]

    var totalTimeMinutes: Int { prepTimeMinutes + cookTimeMinutes }

    /// Every ingredient across all groups, flattened.
    var allIngredients: [Ingredient] { ingredientGroups.flatMap(\.ingredients) }

    // Tolerant decoding: missing arrays/strings default to empty rather than failing.
    enum CodingKeys: String, CodingKey {
        case id, name, description, whyCookThis, category
        case prepTimeMinutes, cookTimeMinutes, servings
        case difficulty, energyLevel, batchFriendly, vegetarian, highProtein
        case tags, ingredientGroups, steps, tasteFixes, easyUpgrades, batchNotes, safetyNotes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        whyCookThis = try c.decodeIfPresent(String.self, forKey: .whyCookThis) ?? ""
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "Other"
        prepTimeMinutes = try c.decodeIfPresent(Int.self, forKey: .prepTimeMinutes) ?? 0
        cookTimeMinutes = try c.decodeIfPresent(Int.self, forKey: .cookTimeMinutes) ?? 0
        servings = try c.decodeIfPresent(Int.self, forKey: .servings) ?? 1
        difficulty = try c.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? .easy
        energyLevel = try c.decodeIfPresent(EnergyLevel.self, forKey: .energyLevel) ?? .medium
        batchFriendly = try c.decodeIfPresent(Bool.self, forKey: .batchFriendly) ?? false
        vegetarian = try c.decodeIfPresent(Bool.self, forKey: .vegetarian) ?? false
        highProtein = try c.decodeIfPresent(Bool.self, forKey: .highProtein) ?? false
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        ingredientGroups = try c.decodeIfPresent([IngredientGroup].self, forKey: .ingredientGroups) ?? []
        steps = try c.decodeIfPresent([CookingStep].self, forKey: .steps) ?? []
        tasteFixes = try c.decodeIfPresent([TasteFix].self, forKey: .tasteFixes) ?? []
        easyUpgrades = try c.decodeIfPresent([String].self, forKey: .easyUpgrades) ?? []
        batchNotes = try c.decodeIfPresent(String.self, forKey: .batchNotes) ?? ""
        safetyNotes = try c.decodeIfPresent([String].self, forKey: .safetyNotes) ?? []
    }
}

// MARK: - Ingredient grouping

struct IngredientGroup: Codable, Identifiable, Hashable {
    var name: String
    var ingredients: [Ingredient]
    var id: String { name }
}

struct Ingredient: Codable, Identifiable, Hashable {
    var name: String
    var amount: Double?
    var unit: String?
    var note: String?
    var optional: Bool
    var shoppingCategory: ShoppingCategory

    var id: String { "\(name)|\(unit ?? "")|\(note ?? "")" }

    enum CodingKeys: String, CodingKey {
        case name, amount, unit, note, optional, shoppingCategory
    }

    init(name: String, amount: Double? = nil, unit: String? = nil,
         note: String? = nil, optional: Bool = false,
         shoppingCategory: ShoppingCategory = .other) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.note = note
        self.optional = optional
        self.shoppingCategory = shoppingCategory
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        amount = try c.decodeIfPresent(Double.self, forKey: .amount)
        unit = try c.decodeIfPresent(String.self, forKey: .unit)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        optional = try c.decodeIfPresent(Bool.self, forKey: .optional) ?? false
        shoppingCategory = try c.decodeIfPresent(ShoppingCategory.self, forKey: .shoppingCategory) ?? .other
    }
}

// MARK: - Steps & fixes

struct CookingStep: Codable, Identifiable, Hashable {
    var title: String
    var instruction: String
    var durationMinutes: Int?
    var ingredients: [String]
    var tips: [String]
    var id: String { title + instruction }

    enum CodingKeys: String, CodingKey {
        case title, instruction, durationMinutes, ingredients, tips
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decode(String.self, forKey: .title)
        instruction = try c.decodeIfPresent(String.self, forKey: .instruction) ?? ""
        durationMinutes = try c.decodeIfPresent(Int.self, forKey: .durationMinutes)
        ingredients = try c.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        tips = try c.decodeIfPresent([String].self, forKey: .tips) ?? []
    }
}

struct TasteFix: Codable, Identifiable, Hashable {
    var problem: String
    var fix: String
    var id: String { problem }
}

// MARK: - Enums

enum Difficulty: String, Codable, CaseIterable, Identifiable, Hashable {
    case easy, medium, hard
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .easy: "circle.fill"
        case .medium: "circle.lefthalf.filled"
        case .hard: "circle.grid.2x2.fill"
        }
    }
    var tint: Color {
        switch self {
        case .easy: Theme.green
        case .medium: Theme.amber
        case .hard: Theme.coral
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable, Identifiable, Hashable {
    case low, medium, high
    var id: String { rawValue }
    var label: String { rawValue.capitalized + " energy" }
    var shortLabel: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .low: "moon.fill"
        case .medium: "bolt.fill"
        case .high: "flame.fill"
        }
    }
    var tint: Color {
        switch self {
        case .low: Theme.teal
        case .medium: Theme.amber
        case .high: Theme.coral
        }
    }
}

/// Aisle groupings for the shopping list. `order` drives display order.
enum ShoppingCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case produce = "Produce"
    case protein = "Protein"
    case pantry = "Pantry"
    case dairy = "Dairy"
    case frozen = "Frozen"
    case spices = "Spices"
    case other = "Other"

    var id: String { rawValue }
    var label: String { rawValue }
    var order: Int { Self.allCases.firstIndex(of: self) ?? 99 }
    var symbol: String {
        switch self {
        case .produce: "leaf.fill"
        case .protein: "fish.fill"
        case .pantry: "shippingbox.fill"
        case .dairy: "drop.fill"
        case .frozen: "snowflake"
        case .spices: "sparkles"
        case .other: "bag.fill"
        }
    }
    var tint: Color {
        switch self {
        case .produce: Theme.green
        case .protein: Theme.coral
        case .pantry: Theme.amber
        case .dairy: Theme.sky
        case .frozen: Theme.teal
        case .spices: Theme.violet
        case .other: Theme.slate
        }
    }
}
