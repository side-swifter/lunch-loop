import SwiftUI

@main struct MyApp: App {
    @State private var store = LunchStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                // App-wide brand color, defined once in Assets
                .tint(Color("AccentColor"))
        }
    }
}
