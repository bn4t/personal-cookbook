import SwiftUI

struct DetailView: View {
    let recipe: Recipe

    enum Section: String, CaseIterable, Identifiable {
        case overview = "Overview", ingredients = "Ingredients", steps = "Steps", notes = "Notes"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .overview: "square.text.square"
            case .ingredients: "list.bullet"
            case .steps: "figure.walk"
            case .notes: "note.text"
            }
        }
    }

    @Environment(ShoppingList.self) private var shopping
    @State private var section: Section = .overview
    @State private var targetServings: Int
    @State private var startCooking = false
    @Namespace private var segGeo

    init(recipe: Recipe) {
        self.recipe = recipe
        _targetServings = State(initialValue: recipe.servings)
    }

    private var factor: Double {
        ScalingHelpers.factor(base: recipe.servings, target: targetServings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                picker

                switch section {
                case .overview: OverviewSection(recipe: recipe)
                case .ingredients: IngredientsSection(recipe: recipe, targetServings: $targetServings, factor: factor)
                case .steps: StepsSection(recipe: recipe)
                case .notes: NotesSection(recipe: recipe)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 120)
            .animation(.snappy(duration: 0.25), value: section)
        }
        .scrollContentBackground(.hidden)
        .cookbookBackground()
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                let added = shopping.contains(recipe.id)
                Button {
                    withAnimation(.snappy) { shopping.toggle(recipe, servings: targetServings) }
                } label: {
                    Label(added ? "On shopping list" : "Add to shopping list",
                          systemImage: added ? "cart.fill" : "cart.badge.plus")
                }
                .tint(added ? Theme.accent : nil)
            }
        }
        .safeAreaInset(edge: .bottom) { cookButton }
        .fullScreenCover(isPresented: $startCooking) {
            CookingModeView(recipe: recipe)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.category.uppercased())
                .font(.caption.weight(.bold)).tracking(1.2)
                .foregroundStyle(Theme.accent)
            Text(recipe.name)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(recipe.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // Glass segmented control with a sliding accent selection.
    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(Section.allCases) { s in
                Button {
                    withAnimation(.snappy(duration: 0.3)) { section = s }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: s.icon).font(.subheadline.weight(.semibold))
                        Text(s.rawValue).font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(section == s ? Color.white : .primary)
                    .background {
                        if section == s {
                            Capsule(style: .continuous)
                                .fill(Theme.accent)
                                .matchedGeometryEffect(id: "seg", in: segGeo)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .glassControl(RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: false)
    }

    private var cookButton: some View {
        Button {
            startCooking = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                Text("Start Cooking").fontWeight(.semibold)
                if !recipe.steps.isEmpty {
                    Text("· \(recipe.steps.count) steps").opacity(0.6)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.accent)
        .controlSize(.large)
        .disabled(recipe.steps.isEmpty)
        .opacity(recipe.steps.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }
}

// MARK: - Overview

private struct OverviewSection: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            StatTileRow(recipe: recipe)

            HStack(spacing: 12) {
                timeChip("Prep", recipe.prepTimeMinutes, "timer")
                timeChip("Cook", recipe.cookTimeMinutes, "flame")
            }

            if !recipe.whyCookThis.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Why cook this", systemImage: "sparkles")
                    Text(recipe.whyCookThis)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }

            if !recipe.tags.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Tags", systemImage: "tag")
                    FlowLayout(spacing: 8) {
                        ForEach(recipe.tags, id: \.self) { Pill(text: $0, tint: Theme.violet) }
                    }
                }
            }
        }
    }

    private func timeChip(_ label: String, _ minutes: Int, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Theme.accent).font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text("\(minutes) min").font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 18, padding: 14)
    }
}

private struct StatTileRow: View {
    let recipe: Recipe
    var body: some View {
        let tiles = HStack(spacing: 12) {
            StatTile(value: "\(recipe.totalTimeMinutes)m", caption: "total", systemImage: "clock.fill", tint: Theme.sky)
            StatTile(value: "\(recipe.servings)", caption: "servings", systemImage: "person.2.fill", tint: Theme.slate)
            StatTile(value: recipe.difficulty.label, caption: "difficulty", systemImage: recipe.difficulty.symbol, tint: recipe.difficulty.tint)
            StatTile(value: recipe.energyLevel.shortLabel, caption: "energy", systemImage: recipe.energyLevel.symbol, tint: recipe.energyLevel.tint)
        }
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 12) { tiles }
        } else {
            tiles
        }
    }
}

// MARK: - Ingredients

private struct IngredientsSection: View {
    let recipe: Recipe
    @Binding var targetServings: Int
    let factor: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            servingScaler

            ForEach(recipe.ingredientGroups) { group in
                VStack(alignment: .leading, spacing: 12) {
                    if recipe.ingredientGroups.count > 1 || group.name != "Ingredients" {
                        SectionHeader(title: group.name, systemImage: "circle.grid.2x2")
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(group.ingredients.enumerated()), id: \.element.id) { idx, ing in
                            IngredientRow(ingredient: ing, factor: factor)
                            if idx < group.ingredients.count - 1 {
                                Divider().overlay(.white.opacity(0.08)).padding(.leading, 28)
                            }
                        }
                    }
                    .glassCard(padding: 6)
                }
            }
        }
    }

    private var servingScaler: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Servings").font(.subheadline.weight(.semibold))
                Text(targetServings != recipe.servings ? "scaled from \(recipe.servings)" : "base recipe")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 18) {
                stepper("minus") { if targetServings > 1 { targetServings -= 1 } }
                Text("\(targetServings)")
                    .font(.system(.title2, design: .rounded).weight(.bold)).monospacedDigit()
                    .frame(minWidth: 30)
                    .contentTransition(.numericText())
                stepper("plus") { if targetServings < 40 { targetServings += 1 } }
            }
        }
        .glassCard(cornerRadius: 18, padding: 16)
    }

    private func stepper(_ icon: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: icon)
                .font(.body.weight(.bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 38, height: 38)
                .glassControl(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct IngredientRow: View {
    let ingredient: Ingredient
    var factor: Double = 1

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Circle().fill(ingredient.shoppingCategory.tint).frame(width: 7, height: 7)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 4 }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(ingredient.name).font(.body.weight(.medium))
                    if ingredient.optional {
                        Text("optional").font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(.white.opacity(0.08)))
                    }
                }
                if let note = ingredient.note, !note.isEmpty {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(ScalingHelpers.amountText(ingredient, factor: factor))
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
    }
}

// MARK: - Steps (reading view)

private struct StepsSection: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(recipe.steps.enumerated()), id: \.element.id) { idx, step in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Text("\(idx + 1)")
                            .font(.subheadline.weight(.bold)).foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.accent))
                        Text(step.title).font(.headline)
                        Spacer()
                        if let mins = step.durationMinutes {
                            Pill(text: "\(mins)m", systemImage: "timer", tint: Theme.sky)
                        }
                    }
                    Text(step.instruction).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !step.tips.isEmpty {
                        ForEach(step.tips, id: \.self) { tip in
                            Label(tip, systemImage: "lightbulb.fill")
                                .font(.caption).foregroundStyle(Theme.amber)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            }
        }
    }
}

// MARK: - Notes

private struct NotesSection: View {
    let recipe: Recipe

    private var isEmpty: Bool {
        recipe.tasteFixes.isEmpty && recipe.easyUpgrades.isEmpty
            && recipe.batchNotes.isEmpty && recipe.safetyNotes.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEmpty {
                EmptyStateView(title: "No notes", message: "This recipe has no extra notes yet.", systemImage: "note.text")
                    .frame(maxWidth: .infinity)
            }
            if !recipe.tasteFixes.isEmpty {
                noteCard("Taste fixes", icon: "slider.horizontal.3", tint: Theme.coral) {
                    ForEach(recipe.tasteFixes) { fix in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(fix.problem).font(.subheadline.weight(.semibold))
                            Text(fix.fix).font(.callout).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            if !recipe.easyUpgrades.isEmpty {
                noteCard("Easy upgrades", icon: "wand.and.stars", tint: Theme.violet) {
                    ForEach(recipe.easyUpgrades, id: \.self) { up in
                        Label(up, systemImage: "plus.circle").font(.callout)
                    }
                }
            }
            if !recipe.batchNotes.isEmpty {
                noteCard("Batch notes", icon: "square.stack.3d.up", tint: Theme.amber) {
                    Text(recipe.batchNotes).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !recipe.safetyNotes.isEmpty {
                noteCard("Safety", icon: "checkmark.shield", tint: Theme.green) {
                    ForEach(recipe.safetyNotes, id: \.self) { note in
                        Label(note, systemImage: "exclamationmark.circle").font(.callout)
                    }
                }
            }
        }
    }

    private func noteCard<C: View>(_ title: String, icon: String, tint: Color, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(title).font(.title3.weight(.bold))
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}
