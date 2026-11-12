import Foundation
import Observation

// One food item on the menu
struct LunchItem: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let calories: Int
}

// Everything served on one school day. The first item is the main dish.
struct DayMenu: Identifiable {
    let id = UUID()
    let name: String
    let items: [LunchItem]

    var shortName: String {
        String(name.prefix(3))
    }

    var main: LunchItem {
        items[0]
    }

    var sides: [LunchItem] {
        Array(items.dropFirst())
    }

    var totalCalories: Int {
        items.reduce(0) { $0 + $1.calories }
    }
}

// A lunch choice students can vote for
struct PollOption: Identifiable {
    let id = UUID()
    let name: String
    var votes: Int

    var votesText: String {
        votes == 1 ? "1 vote" : "\(votes) votes"
    }
}

// The vote for one day of next week
struct DayPoll: Identifiable {
    let id = UUID()
    let dayName: String
    var options: [PollOption]
    var isOpen: Bool
    var myVoteID: UUID?

    var shortName: String {
        String(dayName.prefix(3))
    }

    var totalVotes: Int {
        options.reduce(0) { $0 + $1.votes }
    }

    var myVote: PollOption? {
        options.first { $0.id == myVoteID }
    }

    // The option with the most votes
    var leader: PollOption? {
        options.max { $0.votes < $1.votes }
    }

    func percent(for option: PollOption) -> Int {
        guard totalVotes > 0 else { return 0 }
        return Int((Double(option.votes) / Double(totalVotes) * 100).rounded())
    }

    // 1 for the option with the most votes, 2 for the next, and so on
    func rank(of option: PollOption) -> Int {
        let sorted = options.sorted { $0.votes > $1.votes }
        return (sorted.firstIndex { $0.id == option.id } ?? 0) + 1
    }

    // Short label for the day selector
    var statusText: String {
        if !isOpen { return "Closed" }
        return myVoteID == nil ? "Open" : "Voted"
    }

    // Line under the day name
    var headline: String {
        isOpen ? "Voting open. \(totalVotes) votes so far." : "Results are in. \(totalVotes) votes."
    }

    // Line under the options
    var footerText: String {
        if let leader, !isOpen {
            let winner = "\(leader.name) won with \(percent(for: leader))% of the vote."
            if let myVote {
                return winner + " You voted for \(myVote.name)."
            }
            return winner
        }
        if let myVote {
            return "You voted for \(myVote.name). Tap another option to change it."
        }
        return "Tap an option to vote."
    }

    // One-line summary for the Home screen
    var summaryText: String {
        if let leader, !isOpen { return "\(leader.name) won" }
        if let myVote { return "You picked \(myVote.name)" }
        return "Not voted yet"
    }

    mutating func vote(for option: PollOption) {
        guard isOpen, option.id != myVoteID else { return }
        // Take back the previous vote, if there was one
        if let previous = options.firstIndex(where: { $0.id == myVoteID }) {
            options[previous].votes -= 1
        }
        if let chosen = options.firstIndex(where: { $0.id == option.id }) {
            options[chosen].votes += 1
        }
        myVoteID = option.id
    }

    mutating func removeVote() {
        guard isOpen, let previous = options.firstIndex(where: { $0.id == myVoteID }) else { return }
        options[previous].votes -= 1
        myVoteID = nil
    }
}

// Holds the app's data
@Observable
class LunchStore {
    var days = LunchStore.sampleWeek
    var polls = LunchStore.samplePolls
    var selectedDayIndex = LunchStore.todayIndex
    var selectedPollIndex = 0

    var today: DayMenu {
        days[LunchStore.todayIndex]
    }

    var selectedPoll: DayPoll {
        polls[selectedPollIndex]
    }

    func vote(for option: PollOption) {
        polls[selectedPollIndex].vote(for: option)
    }

    func removeVote() {
        polls[selectedPollIndex].removeVote()
    }

    // Calendar date for a school day this week. Index 0 is Monday.
    func date(forDayIndex index: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let monday = calendar.date(byAdding: .day, value: 2 - weekday, to: today) ?? today
        return calendar.date(byAdding: .day, value: index, to: monday) ?? monday
    }
}

// Fake data until the app talks to a real server
extension LunchStore {
    static let sampleWeek: [DayMenu] = [
        DayMenu(name: "Monday", items: [
            LunchItem(name: "Cheese Pizza", symbol: "fork.knife", calories: 520),
            LunchItem(name: "Garden Salad", symbol: "leaf", calories: 90),
            LunchItem(name: "Apple Slices", symbol: "basket", calories: 60)
        ]),
        DayMenu(name: "Tuesday", items: [
            LunchItem(name: "Chicken Tacos", symbol: "takeoutbag.and.cup.and.straw", calories: 480),
            LunchItem(name: "Rice and Beans", symbol: "frying.pan", calories: 210),
            LunchItem(name: "Orange", symbol: "basket", calories: 70)
        ]),
        DayMenu(name: "Wednesday", items: [
            LunchItem(name: "Spaghetti and Meatballs", symbol: "fork.knife", calories: 560),
            LunchItem(name: "Garlic Bread", symbol: "frying.pan", calories: 180),
            LunchItem(name: "Steamed Broccoli", symbol: "leaf", calories: 50)
        ]),
        DayMenu(name: "Thursday", items: [
            LunchItem(name: "Chicken and Brussels", symbol: "fork.knife", calories: 485),
            LunchItem(name: "Roasted Sweet Potato", symbol: "carrot", calories: 150),
            LunchItem(name: "Fruit Cup", symbol: "basket", calories: 80)
        ]),
        DayMenu(name: "Friday", items: [
            LunchItem(name: "Fish Sticks", symbol: "fish", calories: 410),
            LunchItem(name: "Tomato Soup", symbol: "cup.and.saucer", calories: 160),
            LunchItem(name: "Chocolate Chip Cookie", symbol: "birthday.cake", calories: 190)
        ])
    ]

    static let samplePolls: [DayPoll] = {
        // Monday is pre-voted so the "Voted" state shows up in the demo
        let monday = [
            PollOption(name: "Pizza", votes: 14),
            PollOption(name: "Chicken Tacos", votes: 9),
            PollOption(name: "Pasta", votes: 4),
            PollOption(name: "Veggie Burgers", votes: 2)
        ]
        return [
            DayPoll(dayName: "Monday", options: monday, isOpen: true, myVoteID: monday[0].id),
            DayPoll(dayName: "Tuesday", options: [
                PollOption(name: "Burrito Bowls", votes: 11),
                PollOption(name: "Grilled Cheese", votes: 8),
                PollOption(name: "Chicken Tenders", votes: 7),
                PollOption(name: "Salad Bar", votes: 3)
            ], isOpen: true),
            DayPoll(dayName: "Wednesday", options: [
                PollOption(name: "Spaghetti", votes: 12),
                PollOption(name: "Stir Fry", votes: 9),
                PollOption(name: "Sloppy Joes", votes: 6),
                PollOption(name: "Quesadillas", votes: 5)
            ], isOpen: true),
            // Thursday is closed so the results state shows up in the demo
            DayPoll(dayName: "Thursday", options: [
                PollOption(name: "Chicken Tenders", votes: 18),
                PollOption(name: "Mac and Cheese", votes: 12),
                PollOption(name: "Fish Tacos", votes: 5),
                PollOption(name: "Soup and Sandwich", votes: 4)
            ], isOpen: false),
            DayPoll(dayName: "Friday", options: [
                PollOption(name: "Pizza", votes: 10),
                PollOption(name: "Nachos", votes: 9),
                PollOption(name: "Hot Dogs", votes: 4),
                PollOption(name: "Pasta Salad", votes: 2)
            ], isOpen: true)
        ]
    }()

    // Index into sampleWeek for today. Falls back to Monday on weekends.
    static var todayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: .now)
        return (2...6).contains(weekday) ? weekday - 2 : 0
    }
}
