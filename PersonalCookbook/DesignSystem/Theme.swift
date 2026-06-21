import SwiftUI

/// Design tokens. Premium dark, the way Apple's own dark apps (Music, News,
/// App Store) do it: a near-black canvas, real Liquid Glass cards, ONE confident
/// accent, and everything else monochrome so it never looks like a rainbow.
/// No imagery anywhere.
enum Theme {
    /// The one accent — a warm coral-red. Appetising, high-contrast with white
    /// button text. Used sparingly; everything else is white/grey.
    static let accent = Color(red: 0.95, green: 0.36, blue: 0.32)

    // Semantic tokens repointed to neutral grey (they adapt in dark mode). Names
    // are kept only so call sites compile — the palette stays restrained.
    static let neutral = Color(.secondaryLabel)
    static let green  = Color(.secondaryLabel)
    static let teal   = Color(.secondaryLabel)
    static let sky    = Color(.secondaryLabel)
    static let amber  = Color(.secondaryLabel)
    static let coral  = Color(.secondaryLabel)
    static let violet = Color(.secondaryLabel)
    static let slate  = Color(.secondaryLabel)

    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 18
}

// MARK: - Background

/// Clean near-black canvas with two whisper-faint glows so Liquid Glass surfaces
/// have something to refract. Subtle enough to read as "premium dark", not brown.
struct CookbookBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.055, blue: 0.065)

            RadialGradient(
                colors: [Theme.accent.opacity(0.12), .clear],
                center: UnitPoint(x: 0.95, y: -0.05),
                startRadius: 0, endRadius: 480
            )
            RadialGradient(
                colors: [Color(red: 0.25, green: 0.30, blue: 0.45).opacity(0.18), .clear],
                center: UnitPoint(x: 0.0, y: 1.05),
                startRadius: 0, endRadius: 560
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Surfaces

extension View {
    /// A Liquid Glass card.
    func glassCard(cornerRadius: CGFloat = Theme.cardRadius, padding: CGFloat = 18) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .padding(padding)
            .glassEffect(.regular, in: shape)
            .contentShape(shape)
    }

    /// Glass background for a small control (chip, stepper). `tint` fills it
    /// (selected state). `contentShape` makes the whole surface tappable.
    func glassControl<S: Shape>(_ shape: S, tint: Color? = nil, interactive: Bool = true) -> some View {
        Group {
            if let tint {
                self.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
            } else {
                self.glassEffect(.regular.interactive(interactive), in: shape)
            }
        }
        .contentShape(shape)
    }

    func cookbookBackground() -> some View {
        background(CookbookBackground())
    }
}
