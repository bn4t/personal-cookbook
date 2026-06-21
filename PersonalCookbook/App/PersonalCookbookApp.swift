import SwiftUI

@main
struct PersonalCookbookApp: App {
    @State private var store = RecipeStore()
    @State private var shopping = ShoppingList()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(shopping)
                .preferredColorScheme(.dark) // Premium dark, Apple-style.
                .tint(Theme.accent)
        }
    }
}
