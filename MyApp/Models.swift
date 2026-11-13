import Foundation

// Diet and allergy labels shown on a dish
enum DietTag: String {
    case vegetarian = "Vegetarian"
    case glutenFree = "Gluten Free"
    case dairy = "Dairy"
    case chicken = "Chicken"
    case beef = "Beef"
    case fish = "Fish"
    case spicy = "Spicy"

    var symbol: String {
        switch self {
        case .vegetarian: "leaf"
        case .glutenFree: "checkmark.seal"
        case .dairy: "drop"
        case .chicken: "bird"
        case .beef: "fork.knife"
        case .fish: "fish"
        case .spicy: "flame"
        }
    }
}

// One food item on the menu
struct LunchItem: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    var tags: [DietTag] = []
}

// Everything served on one school day. The first item is the main dish.
struct DayMenu: Identifiable {
    let date: Date
    let items: [LunchItem]

    var id: Date { date }

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
    let name: String
    var votes: Int

    var id: String { name }

    var votesText: String {
        votes == 1 ? "1 vote" : "\(votes) votes"
    }
}

// The vote held on one school day. It runs from 7 AM to 10 PM that day
// and picks the lunch served one week later.
struct DayPoll: Identifiable {
    let date: Date
    let options: [PollOption]
    let myVoteID: String?

    var id: Date { date }

    var opensAt: Date { date.at(hour: 7) }
    var closesAt: Date { date.at(hour: 22) }
    var lunchDate: Date { Calendar.current.date(byAdding: .day, value: 7, to: date) ?? date }

    var isUpcoming: Bool { Date.now < opensAt }
    var isOpen: Bool { !isUpcoming && Date.now < closesAt }

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

    // Vote count next to the day name
    var headline: String {
        if isUpcoming { return "\(options.count) choices" }
        return isOpen ? "\(totalVotes) votes so far" : "\(totalVotes) votes, final"
    }

    // "Ends today at 10 PM", "Opens tomorrow at 7 AM", "Closed yesterday at 10 PM"
    var deadlineText: String {
        if isUpcoming { return "Opens \(opensAt.friendly)" }
        if isOpen { return "Ends \(closesAt.friendly)" }
        return "Closed \(closesAt.friendly)"
    }

    // "For lunch on Thu, Nov 19"
    var lunchText: String {
        "For lunch on \(lunchDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))"
    }

    // One-line summary for the Home screen
    var summaryText: String {
        if isUpcoming { return "Opens at 7 AM" }
        if let leader, !isOpen { return "\(leader.name) won" }
        if let myVote { return "You picked \(myVote.name)" }
        return "Not voted yet"
    }
}

extension Date {
    // This day at a given hour, like 10 PM
    func at(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: self) ?? self
    }

    // "2026-11-12", used to save votes by day
    var dayKey: String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    // Says "today" or "tomorrow" when it can, otherwise the date
    var friendly: String {
        let calendar = Calendar.current
        let time = formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(self) { return "today at \(time)" }
        if calendar.isDateInTomorrow(self) { return "tomorrow at \(time)" }
        if calendar.isDateInYesterday(self) { return "yesterday at \(time)" }
        return "\(formatted(.dateTime.month(.abbreviated).day())) at \(time)"
    }
}
