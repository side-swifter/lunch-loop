import SwiftUI

// Profile, notifications, app info, sign out and reset, shown as a sheet from Home
struct SettingsView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userGrade") private var userGrade = 9
    @AppStorage("voteReminders") private var voteReminders = true
    @AppStorage("schoolID") private var schoolID = ""
    @Environment(LunchStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false

    // Reads the version number set in the project
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $userName)
                    LabeledContent("Email", value: userEmail)
                    Picker("Grade", selection: $userGrade) {
                        ForEach(6...12, id: \.self) { grade in
                            Text("Grade \(grade)").tag(grade)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        SchoolPicker(schools: store.schools, selection: $schoolID)
                    } label: {
                        LabeledContent("School", value: store.school?.name ?? "Choose")
                    }
                } header: {
                    Text("School")
                } footer: {
                    Text("Changing schools loads that school's menu and votes.")
                }

                Section {
                    Toggle("Vote Reminders", isOn: $voteReminders)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get a reminder before each day's vote closes at 10 PM.")
                }

                Section("About") {
                    if let lastUpdated = store.lastUpdated {
                        LabeledContent("Last Synced", value: lastUpdated.formatted(date: .omitted, time: .shortened))
                    }
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        isSignedIn = false
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }

                Section {
                    Button("Reset App", role: .destructive) {
                        confirmingReset = true
                    }
                    .frame(maxWidth: .infinity)
                } footer: {
                    Text("Erases everything on this phone and starts over from the welcome screen.")
                }
            }
            .confirmationDialog("Reset Lunch Loop?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset App", role: .destructive, action: resetApp)
            } message: {
                Text("This signs you out and erases your votes and settings.")
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // Puts every saved setting back to how a fresh install starts, then replays the first launch
    private func resetApp() {
        store.resetApp()
        isSignedIn = false
        hasSeenIntro = false
        userName = ""
        userEmail = ""
        userGrade = 9
        voteReminders = true
        schoolID = ""
        dismiss()
    }
}

#Preview {
    SettingsView()
        .environment(LunchStore())
}
