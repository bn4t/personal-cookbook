import Foundation

/// Pure functions for scaling ingredient amounts by a serving target and for
/// formatting amounts into clean, kitchen-friendly text (fractions, no trailing
/// zeros). Kept free of UI so they're trivially testable and reusable.
enum ScalingHelpers {

    /// Scale factor from a recipe's base servings to a desired serving count.
    static func factor(base: Int, target: Int) -> Double {
        guard base > 0 else { return 1 }
        return Double(target) / Double(base)
    }

    /// Returns a copy of the ingredient with its numeric amount scaled.
    static func scaled(_ ingredient: Ingredient, factor: Double) -> Ingredient {
        guard let amount = ingredient.amount else { return ingredient }
        var copy = ingredient
        copy.amount = amount * factor
        return copy
    }

    /// A display string like "1½ cups · chopped" for an ingredient.
    static func amountText(_ ingredient: Ingredient, factor: Double = 1) -> String {
        guard let amount = ingredient.amount else {
            // No numeric amount — fall back to the unit ("to taste", "a pinch", etc.)
            return ingredient.unit ?? ""
        }
        let value = format(amount * factor)
        if let unit = ingredient.unit, !unit.isEmpty {
            return "\(value) \(unit)"
        }
        return value
    }

    /// Format a Double as a tidy amount using common kitchen fractions.
    static func format(_ value: Double) -> String {
        guard value > 0 else { return "0" }
        let whole = Int(value)
        let frac = value - Double(whole)

        // Snap to the nearest common fraction within a small tolerance.
        let fractions: [(Double, String)] = [
            (0.0, ""), (0.125, "⅛"), (0.25, "¼"), (0.333, "⅓"),
            (0.5, "½"), (0.666, "⅔"), (0.75, "¾"), (1.0, "")
        ]
        let nearest = fractions.min { abs($0.0 - frac) < abs($1.0 - frac) }!

        if nearest.0 >= 1.0 {
            return "\(whole + 1)"
        }
        if nearest.1.isEmpty {
            // No clean fraction match → show up to 2 decimals, trimmed.
            if abs(frac) < 0.05 { return "\(whole)" }
            return trimmed(value)
        }
        return whole > 0 ? "\(whole)\(nearest.1)" : nearest.1
    }

    private static func trimmed(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() { return "\(Int(rounded))" }
        return String(format: "%g", rounded)
    }
}
