import SwiftUI

// MARK: - Understated metadata item

/// A small symbol + label used in calm metadata rows. Secondary by default so
/// the recipe title stays dominant — restraint is the whole point.
struct MetaItem: View {
    var systemImage: String
    var text: String
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Pill (used on detail surfaces, tastefully)

struct Pill: View {
    var text: String
    var systemImage: String? = nil
    var tint: Color = Theme.slate

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage).font(.caption2.weight(.bold))
            }
            Text(text).font(.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

// MARK: - Glass stat tile

/// A single glass tile for the detail overview: symbol, value, caption.
struct StatTile: View {
    var value: String
    var caption: String
    var systemImage: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 18, padding: 0)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    var title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
        }
    }
}

// MARK: - Flow layout

/// Wrapping layout for pills/tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0, totalHeight: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0; rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 320)
        .padding(.vertical, 36)
        .padding(.horizontal, 28)
        .glassCard()
    }
}
