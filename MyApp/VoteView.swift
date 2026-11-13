import SwiftUI

// Scroll to any school day to see its vote. Today's vote is the one you can change.
struct VoteView: View {
    @Environment(LunchStore.self) private var store
    // The option tapped but not sent yet
    @State private var pickedID: String?
    @State private var isSending = false
    @State private var sentCount = 0
    @State private var showingError = false
    @State private var errorMessage = ""

    private var poll: DayPoll {
        store.poll(on: store.selectedVoteDate)
    }

    // What shows as selected: a fresh tap, or the vote already sent
    private var currentPick: String? {
        pickedID ?? poll.myVoteID
    }

    private var pickedOption: PollOption? {
        poll.options.first { $0.id == pickedID }
    }

    // True once a new dish is picked on an open vote
    private var canSend: Bool {
        poll.isOpen && pickedOption != nil && pickedID != poll.myVoteID
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DateStrip(daysAhead: 14, selection: $store.selectedVoteDate)
                    header
                    options
                }
                .padding()
            }
            .refreshable {
                await store.reload()
            }
            .bottomBar {
                voteButton
            }
            .navigationTitle("Vote")
            .navigationSubtitle(poll.lunchText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Today") {
                    store.selectedVoteDate = LunchStore.voteToday
                }
            }
            // Clear a half-made pick when switching days
            .onChange(of: store.selectedVoteDate) {
                pickedID = nil
            }
            // Small tap on the phone when a vote goes through
            .sensoryFeedback(.success, trigger: sentCount)
            .alert("Vote didn't go through", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // Date and vote count, then when voting ends or opens
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(poll.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.title2.bold())
                Spacer()
                Text(poll.headline)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Label(poll.deadlineText, systemImage: "clock")
                .font(.footnote.weight(.medium))
                .foregroundStyle(poll.isOpen ? Color.accentColor : Color.secondary)
        }
    }

    // Two columns of photo cards, one per choice
    private var options: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(poll.options) { option in
                Button {
                    if poll.isOpen { pickedID = option.id }
                } label: {
                    optionCard(option)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // Photo, name, share of the vote and a bar. The picked card gets an orange outline and a check.
    private func optionCard(_ option: PollOption) -> some View {
        let isPicked = option.id == currentPick
        let isWinner = !poll.isOpen && !poll.isUpcoming && option.id == poll.leader?.id

        return VStack(alignment: .leading, spacing: 8) {
            FoodPhoto(option.name, height: 110)
                .overlay(alignment: .topTrailing) {
                    if isPicked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, Color.accentColor)
                            .padding(8)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if isWinner || option.id == poll.myVoteID {
                        Text(isWinner ? "Winner" : "Your vote")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.regularMaterial, in: Capsule())
                            .padding(8)
                    }
                }

            Text(option.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            // No numbers yet for a vote that hasn't opened
            if poll.isUpcoming {
                Text("Not open yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Text("\(poll.percent(for: option))%")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(option.votesText)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                ProgressView(value: Double(option.votes), total: Double(max(poll.totalVotes, 1)))
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPicked ? Color.accentColor : Color.clear, lineWidth: 2)
        }
    }

    // The one main action on this page, plus a way to take your vote back
    private var voteButton: some View {
        VStack(spacing: 8) {
            MainButton(title: buttonTitle, systemImage: buttonSymbol,
                       isReady: canSend, isBusy: isSending, action: sendVote)

            if poll.isOpen, poll.myVoteID != nil, pickedID == nil {
                Button("Remove My Vote", role: .destructive, action: removeVote)
                    .font(.footnote)
                    .disabled(isSending)
            }
        }
    }

    private var buttonTitle: String {
        if poll.isUpcoming { return poll.deadlineText }
        if !poll.isOpen { return "Voting Closed" }
        if canSend, let pickedOption { return "Vote for \(pickedOption.name)" }
        if let myVote = poll.myVote { return "You Voted for \(myVote.name)" }
        return "Tap a Dish to Vote"
    }

    private var buttonSymbol: String {
        if poll.isUpcoming { return "clock.fill" }
        if !poll.isOpen { return "lock.fill" }
        if canSend { return "hand.thumbsup.fill" }
        if poll.myVote != nil { return "checkmark.circle.fill" }
        return "hand.tap.fill"
    }

    private func sendVote() {
        guard let option = pickedOption else { return }
        let date = poll.date
        send { try await store.vote(for: option, on: date) }
    }

    private func removeVote() {
        let date = poll.date
        send { try await store.removeVote(on: date) }
    }

    // Shows the spinner while the request runs, and an alert if it fails
    private func send(_ action: @escaping () async throws -> Void) {
        isSending = true
        Task {
            do {
                try await action()
                pickedID = nil
                sentCount += 1
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isSending = false
        }
    }
}
