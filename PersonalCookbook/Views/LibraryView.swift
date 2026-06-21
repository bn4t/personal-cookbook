import SwiftUI

// MARK: - Filter model

enum TimeFilter: String, CaseIterable, Identifiable {
    case any, under15 = "≤15m", under30 = "≤30m", under45 = "≤45m"
    var id: String { rawValue }
    var label: String { self == .any ? "Any time" : rawValue }
    var maxMinutes: Int? {
        switch self {
        case .any: nil
        case .under15: 15
        case .under30: 30
        case .under45: 45
        }
    }
}

struct RecipeFilter {
    var search: String = ""
    var category: String? = nil
    var time: TimeFilter = .any
    var difficulty: Difficulty? = nil
    var highProtein = false
    var vegetarian = false
    var batchFriendly = false
    var lowEnergy = false

    var activeCount: Int {
        var n = 0
        if category != nil { n += 1 }
        if time != .any { n += 1 }
        if difficulty != nil { n += 1 }
        if highProtein { n += 1 }
        if vegetarian { n += 1 }
        if batchFriendly { n += 1 }
        if lowEnergy { n += 1 }
        return n
    }

    func matches(_ r: Recipe) -> Bool {
        if let category, r.category != category { return false }
        if let max = time.maxMinutes, r.totalTimeMinutes > max { return false }
        if let difficulty, r.difficulty != difficulty { return false }
        if highProtein && !r.highProtein { return false }
        if vegetarian && !r.vegetarian { return false }
        if batchFriendly && !r.batchFriendly { return false }
        if lowEnergy && r.energyLevel != .low { return false }
        if !search.isEmpty {
            let q = search.lowercased()
            let hay = ([r.name, r.description, r.category] + r.tags).joined(separator: " ").lowercased()
            if !hay.contains(q) { return false }
        }
        return true
    }
}

// MARK: - Library

struct LibraryView: View {
    @Environment(RecipeStore.self) private var store
    @State private var filter = RecipeFilter()
    @State private var showFilters = false
    @State private var showDebug = false

    private var results: [Recipe] {
        store.recipes.filter(filter.matches)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ChipBar(filter: $filter)
                        .padding(.top, 2)

                    if let error = store.loadError {
                        EmptyStateView(title: "Couldn't load recipes", message: error, systemImage: "exclamationmark.triangle")
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    } else if results.isEmpty {
                        EmptyStateView(title: store.recipes.isEmpty ? "No recipes yet" : "No matches",
                                       message: store.recipes.isEmpty
                                        ? "Add recipes to recipes.json to get started."
                                        : "Try clearing a filter or search term.",
                                       systemImage: "fork.knife")
                            .frame(maxWidth: .infinity).padding(.top, 40)
                    } else {
                        GlassCardStack {
                            ForEach(results) { recipe in
                                NavigationLink(value: recipe) {
                                    RecipeCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .cookbookBackground()
            .navigationTitle("Cookbook")
            .navigationDestination(for: Recipe.self) { DetailView(recipe: $0) }
            .searchable(text: $filter.search, prompt: "Search recipes & tags")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Label("Filters", systemImage: filter.activeCount > 0
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showDebug = true } label: {
                            Label("JSON Debug", systemImage: "curlybraces")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filter: $filter, categories: store.categories)
            }
            .sheet(isPresented: $showDebug) {
                JSONDebugView()
            }
        }
    }
}

/// Wraps cards in a GlassEffectContainer on iOS 26 so the glass blends and
/// performs well; plain VStack fallback below.
private struct GlassCardStack<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 16) { content }
            }
        } else {
            VStack(spacing: 16) { content }
        }
    }
}

// MARK: - Quick filter chips (real glass)

private struct ChipBar: View {
    @Binding var filter: RecipeFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip("High protein", "bolt.heart.fill", isOn: filter.highProtein) { filter.highProtein.toggle() }
                chip("Vegetarian", "leaf.fill", isOn: filter.vegetarian) { filter.vegetarian.toggle() }
                chip("Low energy", "moon.stars.fill", isOn: filter.lowEnergy) { filter.lowEnergy.toggle() }
                chip("Batch", "square.stack.3d.up.fill", isOn: filter.batchFriendly) { filter.batchFriendly.toggle() }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
        }
        .scrollClipDisabled()
    }

    private func chip(_ title: String, _ icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption.weight(.bold))
                Text(title).font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isOn ? Color.white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .glassControl(Capsule(), tint: isOn ? Theme.accent : nil)
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.25), value: isOn)
    }
}

// MARK: - Recipe card

struct RecipeCard: View {
    var recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.category.uppercased())
                        .font(.caption2.weight(.bold)).tracking(1.1)
                        .foregroundStyle(Theme.accent)
                    Text(recipe.name)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }

            Text(recipe.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // One calm, understated metadata line.
            HStack(spacing: 16) {
                MetaItem(systemImage: "clock", text: "\(recipe.totalTimeMinutes) min")
                MetaItem(systemImage: "person.2", text: "\(recipe.servings)")
                MetaItem(systemImage: recipe.difficulty.symbol, text: recipe.difficulty.label, tint: recipe.difficulty.tint)
                MetaItem(systemImage: recipe.energyLevel.symbol, text: recipe.energyLevel.shortLabel, tint: recipe.energyLevel.tint)
            }

            // Dietary indicators only when present — quiet, tinted, no candy.
            if recipe.highProtein || recipe.vegetarian || recipe.batchFriendly {
                HStack(spacing: 16) {
                    if recipe.highProtein { dietary("High protein", "bolt.heart.fill", Theme.coral) }
                    if recipe.vegetarian { dietary("Vegetarian", "leaf.fill", Theme.green) }
                    if recipe.batchFriendly { dietary("Batch", "square.stack.3d.up.fill", Theme.amber) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func dietary(_ text: String, _ icon: String, _ tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2.weight(.bold)).foregroundStyle(tint)
            Text(text).font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }
    }
}
