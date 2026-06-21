import SwiftUI

/// Top-level tab shell. Two everyday tabs (Library, Shopping). The JSON debug
/// screen is intentionally kept out of this flow — reach it from the Library
/// toolbar's overflow menu.
struct RootView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Recipes", systemImage: "book.closed.fill") }

            ShoppingListView()
                .tabItem { Label("Shopping", systemImage: "cart.fill") }
        }
    }
}

#Preview {
    RootView()
        .environment(RecipeStore())
        .preferredColorScheme(.dark)
}
