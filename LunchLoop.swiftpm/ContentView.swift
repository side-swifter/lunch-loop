import SwiftUI

struct ContentView: View {
    @Environment(LunchStore.self) private var store
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("schoolID") private var schoolID = ""

    var body: some View {
        if isSignedIn {
            // ZStack keeps one .task alive while the loading screen swaps for the tabs
            ZStack {
                if store.hasLoaded {
                    tabs
                } else if let error = store.errorMessage {
                    ContentUnavailableView {
                        Label("Can't Load Lunch", systemImage: "wifi.slash")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try Again") {
                            Task { await store.load(schoolID: schoolID) }
                        }
                    }
                } else {
                    ProgressView("Loading menu")
                }
            }
            // Runs on launch and again whenever the school changes
            .task(id: schoolID) {
                await store.load(schoolID: schoolID)
            }
        } else {
            OnboardingView()
        }
    }

    private var tabs: some View {
        @Bindable var store = store
        return TabView(selection: $store.selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                HomeView()
            }
            Tab("Vote", systemImage: "hand.thumbsup", value: AppTab.vote) {
                VoteView()
            }
            Tab("Menu", systemImage: "fork.knife", value: AppTab.menu) {
                MenuView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(LunchStore())
}
