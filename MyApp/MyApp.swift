import SwiftUI

@main struct MyApp: App {
    @State private var store = LunchStore()
    @State private var showingApp = false
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("schoolID") private var schoolID = ""

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Built once the logo is drawn, so nothing competes with the animation
                if showingApp {
                    ContentView()
                }
                if store.showingSplash {
                    // Only waits for a swipe on the way into onboarding
                    SplashView(waitsForSwipe: store.splashWaitsForSwipe) {
                        showingApp = true
                    } onFinish: {
                        // The splash already slid itself off screen, so just remove it
                        store.showingSplash = false
                    }
                    // Keep the splash on top so its slide up is visible
                    .zIndex(1)
                }
            }
            .environment(store)
            // Always light mode, even if the phone is set to dark
            .preferredColorScheme(.light)
            // Start loading during the animation, so the app is ready when you swipe up
            .task {
                if isSignedIn {
                    await store.load(schoolID: schoolID)
                }
            }
        }
    }
}
