import SwiftUI

struct ContentView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false

    var body: some View {
        if isSignedIn {
            TabView {
                Tab("Home", systemImage: "house") {
                    HomeView()
                }
                Tab("Vote", systemImage: "hand.thumbsup") {
                    VoteView()
                }
                Tab("Menu", systemImage: "fork.knife") {
                    MenuView()
                }
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .environment(LunchStore())
}
