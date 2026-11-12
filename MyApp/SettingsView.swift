import SwiftUI

// Profile, notifications, app info and sign out, shown as a sheet from Home
struct SettingsView: View {
    @AppStorage("isSignedIn") private var isSignedIn = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userGrade") private var userGrade = 9
    @AppStorage("voteReminders") private var voteReminders = true
    @Environment(\.dismiss) private var dismiss

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
                    Toggle("Vote Reminders", isOn: $voteReminders)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get a reminder the day before voting closes.")
                }

                Section("About") {
                    LabeledContent("School", value: "Lincoln High School")
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        isSignedIn = false
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
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
}

#Preview {
    SettingsView()
}
