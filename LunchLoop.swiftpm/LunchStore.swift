import Foundation
import Observation

enum AppTab {
    case home, vote, menu
}

// Holds the app's data and talks to the server
@Observable
class LunchStore {
    var schools: [School] = []
    var hasLoaded = false
    var errorMessage: String?
    var lastUpdated: Date?
    private(set) var schoolID = ""

    // The student's own votes, keyed by day like "2026-11-12"
    private var myVotes: [String: String] = [:]

    // The logo animation at launch. Reset App turns it back on.
    var showingSplash = true
    // Before onboarding the splash waits for a swipe up. Signed-in launches skip that.
    var splashWaitsForSwipe = !UserDefaults.standard.bool(forKey: "isSignedIn")

    // Which tab and which days are showing
    var selectedTab = AppTab.home
    var selectedVoteDate = LunchStore.voteToday
    var selectedMenuDate = LunchStore.menuToday

    private let service = LunchService()

    var school: School? {
        schools.first { $0.id == schoolID }
    }

    // MARK: School days

    // Today on a school day. On a weekend: Monday's vote, and Friday's menu.
    static var voteToday: Date {
        schoolDays(daysBack: 0, daysAhead: 7).first ?? .now
    }

    static var menuToday: Date {
        schoolDays(daysBack: 7, daysAhead: 0).last ?? .now
    }

    // Weekdays from some days back to some days ahead of today
    static func schoolDays(daysBack: Int, daysAhead: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (-daysBack...daysAhead)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
            .filter { !calendar.isDateInWeekend($0) }
    }

    // MARK: Menus and votes

    func menu(on date: Date) -> DayMenu {
        service.menu(on: date, schoolID: schoolID)
    }

    func poll(on date: Date) -> DayPoll {
        service.poll(on: date, schoolID: schoolID, myVote: myVotes[date.dayKey])
    }

    var todayMenu: DayMenu {
        menu(on: Self.menuToday)
    }

    // The last five school days up to today, oldest first, for Home
    var recentMenus: [DayMenu] {
        Self.schoolDays(daysBack: 14, daysAhead: 0).suffix(5).map { menu(on: $0) }
    }

    // Today's vote and the four before it, newest first, for Home
    var recentPolls: [DayPoll] {
        Self.schoolDays(daysBack: 14, daysAhead: 7).filter { $0 <= Self.voteToday }.suffix(5).reversed().map { poll(on: $0) }
    }

    // MARK: Server calls

    func loadSchools() async {
        guard schools.isEmpty else { return }
        schools = (try? await service.fetchSchools()) ?? []
    }

    // Fetches the school list and this student's votes at the same time
    func load(schoolID: String) async {
        self.schoolID = schoolID
        errorMessage = nil
        do {
            async let schoolList = service.fetchSchools()
            async let votes = service.fetchMyVotes(schoolID: schoolID)
            (schools, myVotes) = try await (schoolList, votes)
            lastUpdated = .now
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Pull to refresh on every page calls this
    func reload() async {
        await load(schoolID: schoolID)
    }

    func signIn(email: String) async throws {
        try await service.signIn(email: email)
    }

    func vote(for option: PollOption, on date: Date) async throws {
        try await service.submitVote(schoolID: schoolID, dayKey: date.dayKey, option: option.name)
        myVotes[date.dayKey] = option.name
    }

    // Erases everything saved on this phone and goes back to the first launch
    func resetApp() {
        if let id = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: id)
        }
        myVotes = [:]
        hasLoaded = false
        lastUpdated = nil
        selectedTab = .home
        selectedVoteDate = Self.voteToday
        selectedMenuDate = Self.menuToday
        splashWaitsForSwipe = true
        showingSplash = true
    }

    func removeVote(on date: Date) async throws {
        try await service.submitVote(schoolID: schoolID, dayKey: date.dayKey, option: nil)
        myVotes[date.dayKey] = nil
    }
}
