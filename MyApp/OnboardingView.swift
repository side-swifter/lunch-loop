import SwiftUI

// Shown instead of the tabs until the student signs in
struct OnboardingView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false

    var body: some View {
        NavigationStack {
            if hasSeenIntro {
                SignUpView()
            } else {
                IntroView()
            }
        }
    }
}

// Three short pages explaining the app
struct IntroView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let text: String
    }

    private let pages = [
        Page(symbol: "fork.knife", title: "See what's for lunch",
             text: "The whole week's menu, with today front and center."),
        Page(symbol: "hand.thumbsup", title: "Vote on next week",
             text: "Pick your favorite for each day. Change your mind any time before voting closes."),
        Page(symbol: "chart.bar", title: "Watch the results",
             text: "See what's winning and what made it onto the menu.")
    ]

    private var isLastPage: Bool {
        page == pages.count - 1
    }

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 16) {
                        Image(systemName: pages[index].symbol)
                            .font(.system(size: 64))
                            .foregroundStyle(.tint)
                            .padding(.bottom, 16)
                        Text(pages[index].title)
                            .font(.title2.bold())
                        Text(pages[index].text)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if isLastPage {
                    hasSeenIntro = true
                } else {
                    withAnimation { page += 1 }
                }
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .navigationTitle("Lunch Loop")
    }
}

// Create an account or log in. Accounts live on this device for now.
struct SignUpView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userGrade") private var userGrade = 9

    @State private var isNewAccount = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var grade = 9

    private var canSubmit: Bool {
        let hasName = !isNewAccount || !name.trimmingCharacters(in: .whitespaces).isEmpty
        return hasName && email.contains("@") && password.count >= 4
    }

    var body: some View {
        Form {
            Section {
                if isNewAccount {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }
                TextField("School Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
                if isNewAccount {
                    Picker("Grade", selection: $grade) {
                        ForEach(6...12, id: \.self) { grade in
                            Text("Grade \(grade)").tag(grade)
                        }
                    }
                }
            }

            Section {
                Button(isNewAccount ? "Create Account" : "Log In", action: submit)
                    .frame(maxWidth: .infinity)
                    .disabled(!canSubmit)
            }

            Section {
                Button(isNewAccount ? "Already have an account? Log In" : "New here? Create an Account") {
                    isNewAccount.toggle()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(isNewAccount ? "Create Account" : "Welcome Back")
    }

    private func submit() {
        if isNewAccount {
            userName = name.trimmingCharacters(in: .whitespaces)
            userGrade = grade
        } else if userName.isEmpty {
            // No server to look the name up from, so use the part before the @
            userName = String(email.prefix { $0 != "@" })
        }
        userEmail = email
        isSignedIn = true
    }
}
