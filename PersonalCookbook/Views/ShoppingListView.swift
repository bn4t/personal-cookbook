import SwiftUI

struct ShoppingListView: View {
    @Environment(RecipeStore.self) private var store
    @Environment(ShoppingList.self) private var shopping
    @State private var showPicker = false

    private var selectedRecipes: [Recipe] {
        store.recipes.filter { shopping.contains($0.id) }
    }
    private var sections: [ShoppingSection] {
        let pairs = selectedRecipes.map { (recipe: $0, servings: shopping.selection[$0.id] ?? $0.servings) }
        return ShoppingListHelpers.build(from: pairs)
    }
    private var totalItems: Int { sections.reduce(0) { $0 + $1.items.count } }
    private var checkedCount: Int { sections.flatMap(\.items).filter { shopping.checked.contains($0.id) }.count }

    var body: some View {
        NavigationStack {
            Group {
                if selectedRecipes.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .cookbookBackground()
            .navigationTitle("Shopping")
            .toolbar {
                if !selectedRecipes.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: shopping.shareText(sections: sections)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                if !shopping.checked.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Uncheck all") { withAnimation { shopping.checked.removeAll() } }
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                RecipePicker(recipes: store.recipes)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            EmptyStateView(title: "Your list is empty",
                           message: "Choose a few recipes and we'll combine their ingredients into one tidy, aisle-by-aisle list.",
                           systemImage: "cart")
            Button {
                showPicker = true
            } label: {
                Label("Choose recipes", systemImage: "plus")
                    .font(.headline).padding(.horizontal, 8).padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
            .controlSize(.large)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Progress + source recipes live here — the single place to manage the list.
                if totalItems > 0 {
                    HStack {
                        Text("\(checkedCount) of \(totalItems) gathered")
                            .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                }

                sourceChips

                ForEach(sections) { section in sectionCard(section) }
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollContentBackground(.hidden)
    }

    // Removable recipe chips + an Add chip — manages selection inline, no duplicate controls.
    private var sourceChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(selectedRecipes) { recipe in
                    // Tap the body to edit (opens picker); tap × to remove.
                    HStack(spacing: 8) {
                        Button { showPicker = true } label: {
                            HStack(spacing: 7) {
                                Text(recipe.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                                HStack(spacing: 3) {
                                    Image(systemName: "person.2.fill").font(.caption2)
                                    Text("\(shopping.selection[recipe.id] ?? recipe.servings)").font(.caption.weight(.bold))
                                }
                                .foregroundStyle(Theme.accent)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Button {
                            withAnimation(.snappy(duration: 0.2)) { shopping.remove(recipe.id) }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .glassControl(Capsule())
                }
                Button { showPicker = true } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .glassControl(Capsule(), tint: Theme.accent.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 2).padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    private func sectionCard(_ section: ShoppingSection) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: section.category.symbol).foregroundStyle(section.category.tint)
                Text(section.category.label).font(.headline)
                Spacer()
                Text("\(section.items.count)")
                    .font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(.white.opacity(0.10)))
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 6)

            ForEach(section.items) { item in itemRow(item) }
        }
        .glassCard(padding: 6)
    }

    private func itemRow(_ item: ShoppingItem) -> some View {
        let isChecked = shopping.checked.contains(item.id)
        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                if isChecked { shopping.checked.remove(item.id) } else { shopping.checked.insert(item.id) }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Theme.accent : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body.weight(.medium))
                        .strikethrough(isChecked, color: .secondary)
                        .foregroundStyle(isChecked ? .secondary : .primary)
                    if item.fromRecipes.count > 1 {
                        Text(item.fromRecipes.joined(separator: ", "))
                            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                if !item.amountText.isEmpty {
                    Text(item.amountText)
                        .font(.callout.weight(.semibold).monospacedDigit())
                        .foregroundStyle(isChecked ? Theme.slate.opacity(0.6) : Theme.accent)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recipe picker sheet

private struct RecipePicker: View {
    let recipes: [Recipe]
    @Environment(ShoppingList.self) private var shopping
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(recipes) { recipe in row(recipe) }
                }
                .padding(18)
            }
            .scrollContentBackground(.hidden)
            .cookbookBackground()
            .navigationTitle("Add recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func row(_ recipe: Recipe) -> some View {
        let isOn = shopping.contains(recipe.id)
        let servings = shopping.selection[recipe.id] ?? recipe.servings
        return VStack(spacing: 12) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { shopping.toggle(recipe) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.title3).foregroundStyle(isOn ? Theme.accent : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.name).font(.headline).foregroundStyle(.primary)
                        Text("\(recipe.category) · \(recipe.totalTimeMinutes) min").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOn {
                Divider().overlay(.white.opacity(0.08))
                HStack {
                    Text("Servings").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 16) {
                        pickerStepper("minus") { shopping.selection[recipe.id] = max(1, servings - 1) }
                        Text("\(servings)").font(.headline.monospacedDigit()).frame(minWidth: 26)
                            .contentTransition(.numericText())
                        pickerStepper("plus") { shopping.selection[recipe.id] = min(40, servings + 1) }
                    }
                }
            }
        }
        .glassCard(padding: 16)
    }

    private func pickerStepper(_ icon: String, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.snappy) { action() } } label: {
            Image(systemName: icon).font(.body.weight(.bold)).foregroundStyle(Theme.accent)
                .frame(width: 34, height: 34)
                .glassControl(Circle())
        }
        .buttonStyle(.plain)
    }
}
