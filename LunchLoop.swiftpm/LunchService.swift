import Foundation

// A Wake County high school students can pick when they sign up
struct School: Identifiable, Hashable {
    let name: String

    var id: String { name }
}

// Stand-in for the lunch server. Every call waits a moment like a real request,
// so the app already handles loading. Swap these bodies for real API calls later.
struct LunchService {
    private let defaults = UserDefaults.standard

    func fetchSchools() async throws -> [School] {
        try await delay()
        return Self.schools
    }

    func signIn(email: String) async throws {
        try await delay()
    }

    // The student's saved votes, keyed by day like "2026-11-12"
    func fetchMyVotes(schoolID: String) async throws -> [String: String] {
        try await delay()
        return savedVotes(schoolID: schoolID)
    }

    // Saves the student's pick for a day. Pass nil to remove it.
    func submitVote(schoolID: String, dayKey: String, option: String?) async throws {
        try await delay()
        var saved = savedVotes(schoolID: schoolID)
        saved[dayKey] = option
        defaults.set(saved, forKey: "votes.\(schoolID)")
    }

    // Menu for any school day. The same day and school always get the same dishes.
    func menu(on date: Date, schoolID: String) -> DayMenu {
        let number = Self.dayNumber(date) + Self.offset(for: schoolID)
        return DayMenu(date: date, items: Self.menus[number % Self.menus.count])
    }

    // Vote for any school day, with made-up counts that stay the same for that day
    func poll(on date: Date, schoolID: String, myVote: String?) -> DayPoll {
        let number = Self.dayNumber(date) + Self.offset(for: schoolID)
        let notOpenYet = Date.now < date.at(hour: 7)

        var options = Self.choices[number % Self.choices.count]
        for index in options.indices {
            options[index].votes = notOpenYet ? 0 : options[index].votes + (number * 7 + index * 3) % 9
        }

        // Past days get a fake history so "Your vote" shows up now and then
        let isPast = date < Calendar.current.startOfDay(for: .now)
        let pick = myVote ?? (isPast && number % 3 == 0 ? options[1].name : nil)
        if let myVote, let index = options.firstIndex(where: { $0.name == myVote }) {
            options[index].votes += 1
        }
        return DayPoll(date: date, options: options, myVoteID: pick)
    }

    private func savedVotes(schoolID: String) -> [String: String] {
        defaults.dictionary(forKey: "votes.\(schoolID)") as? [String: String] ?? [:]
    }

    private func delay() async throws {
        try await Task.sleep(for: .milliseconds(600))
    }

    private static func offset(for schoolID: String) -> Int {
        schools.firstIndex { $0.id == schoolID } ?? 0
    }

    // Days since 2001, so every date maps to a fixed spot in the menu rotation
    private static func dayNumber(_ date: Date) -> Int {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        return Calendar.current.dateComponents([.day], from: start, to: date).day ?? 0
    }
}

// The data the fake server hands out
extension LunchService {
    // High schools in Wake County, NC
    static let schools = [
        "Apex Friendship High School",
        "Apex High School",
        "Athens Drive High School",
        "Broughton High School",
        "Cary High School",
        "Crossroads FLEX High School",
        "East Wake High School",
        "Enloe High School",
        "Fuquay-Varina High School",
        "Garner Magnet High School",
        "Green Hope High School",
        "Green Level High School",
        "Heritage High School",
        "Holly Springs High School",
        "Knightdale High School",
        "Leesville Road High School",
        "Middle Creek High School",
        "Millbrook High School",
        "North Wake College and Career Academy",
        "Panther Creek High School",
        "Phillips High School",
        "Rolesville High School",
        "Sanderson High School",
        "South Garner High School",
        "Wake Early College of Health and Sciences",
        "Wake Forest High School",
        "Wake STEM Early College High School",
        "Wake Young Men's Leadership Academy",
        "Wake Young Women's Leadership Academy",
        "Wakefield High School",
        "Willow Spring High School"
    ].map(School.init)

    // Main dish first, then two sides
    static let menus: [[LunchItem]] = [
        [
            LunchItem(name: "Cheese Pizza", calories: 520, tags: [.vegetarian, .dairy]),
            LunchItem(name: "Garden Salad", calories: 90),
            LunchItem(name: "Apple Slices", calories: 60)
        ],
        [
            LunchItem(name: "Chicken Tacos", calories: 480, tags: [.chicken, .glutenFree, .spicy]),
            LunchItem(name: "Rice and Beans", calories: 210),
            LunchItem(name: "Orange", calories: 70)
        ],
        [
            LunchItem(name: "Spaghetti and Meatballs", calories: 560, tags: [.beef, .dairy]),
            LunchItem(name: "Garlic Bread", calories: 180),
            LunchItem(name: "Steamed Broccoli", calories: 50)
        ],
        [
            LunchItem(name: "Chicken and Brussels", calories: 485, tags: [.chicken, .glutenFree]),
            LunchItem(name: "Roasted Sweet Potato", calories: 150),
            LunchItem(name: "Fruit Cup", calories: 80)
        ],
        [
            LunchItem(name: "Fish Sticks", calories: 410, tags: [.fish]),
            LunchItem(name: "Tomato Soup", calories: 160),
            LunchItem(name: "Chocolate Chip Cookie", calories: 190)
        ]
    ]

    // Four choices per vote. Rounds rotate through these.
    static let choices: [[PollOption]] = [
        [
            PollOption(name: "Pizza", votes: 14),
            PollOption(name: "Chicken Tacos", votes: 9),
            PollOption(name: "Pasta", votes: 4),
            PollOption(name: "Veggie Burgers", votes: 2)
        ],
        [
            PollOption(name: "Burrito Bowls", votes: 11),
            PollOption(name: "Grilled Cheese", votes: 8),
            PollOption(name: "Chicken Tenders", votes: 7),
            PollOption(name: "Salad Bar", votes: 3)
        ],
        [
            PollOption(name: "Spaghetti", votes: 12),
            PollOption(name: "Stir Fry", votes: 9),
            PollOption(name: "Sloppy Joes", votes: 6),
            PollOption(name: "Quesadillas", votes: 5)
        ],
        [
            PollOption(name: "Chicken Tenders", votes: 18),
            PollOption(name: "Mac and Cheese", votes: 12),
            PollOption(name: "Fish Tacos", votes: 5),
            PollOption(name: "Soup and Sandwich", votes: 4)
        ],
        [
            PollOption(name: "Pizza", votes: 10),
            PollOption(name: "Nachos", votes: 9),
            PollOption(name: "Hot Dogs", votes: 4),
            PollOption(name: "Pasta Salad", votes: 2)
        ]
    ]
}
