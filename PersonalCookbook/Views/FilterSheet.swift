import SwiftUI

/// Full filter controls, presented as a sheet from the Library.
struct FilterSheet: View {
    @Binding var filter: RecipeFilter
    var categories: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    group("Category", icon: "square.grid.2x2") {
                        FlowLayout(spacing: 8) {
                            choice("All", selected: filter.category == nil) { filter.category = nil }
                            ForEach(categories, id: \.self) { cat in
                                choice(cat, selected: filter.category == cat) { filter.category = cat }
                            }
                        }
                    }
                    group("Total time", icon: "clock") {
                        FlowLayout(spacing: 8) {
                            ForEach(TimeFilter.allCases) { t in
                                choice(t.label, selected: filter.time == t) { filter.time = t }
                            }
                        }
                    }
                    group("Difficulty", icon: "dial.medium") {
                        FlowLayout(spacing: 8) {
                            choice("Any", selected: filter.difficulty == nil) { filter.difficulty = nil }
                            ForEach(Difficulty.allCases) { d in
                                choice(d.label, selected: filter.difficulty == d) { filter.difficulty = d }
                            }
                        }
                    }
                    group("Diet & batch", icon: "fork.knife") {
                        VStack(spacing: 10) {
                            toggleRow("High protein", icon: "bolt.heart.fill", tint: Theme.coral, isOn: $filter.highProtein)
                            toggleRow("Vegetarian", icon: "leaf.fill", tint: Theme.green, isOn: $filter.vegetarian)
                            toggleRow("Batch friendly", icon: "square.stack.3d.up.fill", tint: Theme.amber, isOn: $filter.batchFriendly)
                            toggleRow("Low energy", icon: "moon.stars.fill", tint: Theme.teal, isOn: $filter.lowEnergy)
                        }
                    }
                }
                .padding(20)
            }
            .cookbookBackground()
            .scrollContentBackground(.hidden)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { withAnimation(.snappy) { filter = RecipeFilter(search: filter.search) } }
                        .disabled(filter.activeCount == 0)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func group<Content: View>(_ title: String, icon: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: title, systemImage: icon)
            content()
        }
    }

    private func choice(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.snappy(duration: 0.2)) { action() } } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color.white : .primary)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .glassControl(Capsule(), tint: selected ? Theme.accent : nil)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, icon: String, tint: Color, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 26)
            Text(title).font(.body)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(tint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 16, padding: 8)
    }
}
