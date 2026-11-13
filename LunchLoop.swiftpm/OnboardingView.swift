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

// Three swipeable pages, each a big food photo with a short line about the app
struct IntroView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @State private var page = 0

    private struct Page {
        let photo: String
        let label: String
        let title: String
        let text: String
    }

    private let pages = [
        Page(photo: "Chicken Tacos", label: "Menu", title: "See what's for lunch",
             text: "Today's tray up front, with every side and every past menu a swipe away."),
        Page(photo: "Pizza", label: "Vote", title: "Vote every school day",
             text: "Each day's vote runs until 10 PM and picks the lunch served a week later."),
        Page(photo: "Burrito Bowls", label: "Results", title: "See what won",
             text: "Scroll back through old votes to see the percentages and what you picked.")
    ]

    private var isLastPage: Bool {
        page == pages.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // The logo on the left, Skip on the right
            HStack {
                LogoView(size: 26)
                Spacer()
                if !isLastPage {
                    Button("Skip") { hasSeenIntro = true }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        FoodPhoto(pages[index].photo, height: 340, cornerRadius: 24)
                        Text(pages[index].label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tint)
                            .padding(.top, 16)
                        Text(pages[index].title)
                            .font(.largeTitle)
                        Text(pages[index].text)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page dots. The page you're on is orange.
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 12)
            .animation(.default, value: page)
        }
        .bottomBar {
            Button {
                if isLastPage {
                    hasSeenIntro = true
                } else {
                    withAnimation { page += 1 }
                }
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// Create an account or log in
struct SignUpView: View {
    @Environment(LunchStore.self) private var store
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userGrade") private var userGrade = 9
    @AppStorage("schoolID") private var savedSchoolID = ""

    @State private var isNewAccount = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var grade = 9
    @State private var schoolID = ""
    @State private var isSending = false

    private var canSubmit: Bool {
        let hasName = !isNewAccount || !name.trimmingCharacters(in: .whitespaces).isEmpty
        return hasName && !schoolID.isEmpty && email.contains("@") && password.count >= 4
    }

    // Tells the student the next thing to fill in
    private var buttonTitle: String {
        if schoolID.isEmpty { return "Choose Your School" }
        if isNewAccount && name.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter Your Name" }
        if !email.contains("@") { return "Enter Your School Email" }
        if password.count < 4 { return "Password Needs 4+ Characters" }
        return isNewAccount ? "Create Account" : "Log In"
    }

    var body: some View {
        Form {
            Section {
                NavigationLink {
                    SchoolPicker(schools: store.schools, selection: $schoolID)
                } label: {
                    LabeledContent("School", value: store.schools.first { $0.id == schoolID }?.name ?? "Choose")
                }
            } header: {
                Text("Your School")
            } footer: {
                if store.schools.isEmpty {
                    Text("Loading schools...")
                }
            }

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
            } header: {
                Text("Account")
            } footer: {
                Text("Use your school email. Passwords need at least 4 characters.")
            }

            Section {
                Button(isNewAccount ? "Already have an account? Log In" : "New here? Create an Account") {
                    isNewAccount.toggle()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(isNewAccount ? "Create Account" : "Welcome Back")
        // Same solid bottom button as Vote. Until the form is done, it says what's missing.
        .bottomBar {
            MainButton(title: buttonTitle, systemImage: canSubmit ? "arrow.right.circle.fill" : "pencil",
                       isReady: canSubmit, isBusy: isSending, action: submit)
        }
        .task {
            await store.loadSchools()
        }
    }

    private func submit() {
        isSending = true
        Task {
            try? await store.signIn(email: email)
            if isNewAccount {
                userName = name.trimmingCharacters(in: .whitespaces)
                userGrade = grade
            } else if userName.isEmpty {
                // Use the part before the @ until the server sends a real name
                userName = String(email.prefix { $0 != "@" })
            }
            userEmail = email
            savedSchoolID = schoolID
            isSending = false
            isSignedIn = true
        }
    }
}
