import SwiftUI

struct VoteView: View {
    @Environment(LunchStore.self) private var store
    // The option whose sheet is open
    @State private var selectedOption: PollOption?

    private var poll: DayPoll {
        store.selectedPoll
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    daySelector
                    pollSection
                }
                .padding()
            }
            .navigationTitle("Vote")
            .navigationSubtitle("Next week's lunch")
            .sheet(item: $selectedOption) { option in
                VoteSheet(optionID: option.id)
            }        }
    }

    // One chip per day, showing whether it is open, voted, or closed
    private var daySelector: some View {
        HStack(spacing: 8) {
            ForEach(store.polls.indices, id: \.self) { index in
                DayChip(title: store.polls[index].shortName,
                        subtitle: store.polls[index].statusText,
                        isSelected: index == store.selectedPollIndex) {
                    store.selectedPollIndex = index
                }
            }
        }
    }

    // The selected day's options with vote counts and bars
    private var pollSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(poll.dayName)
                    .font(.title3.bold())
                Text(poll.headline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(poll.options) { option in
                Button {
                    selectedOption = option
                } label: {
                    optionRow(option)
                }
                .buttonStyle(.plain)
            }

            Text(poll.footerText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // Your pick is filled with the accent color; everything else stays gray
    private func optionRow(_ option: PollOption) -> some View {
        let isMine = option.id == poll.myVoteID
        let isWinner = !poll.isOpen && option.id == poll.leader?.id

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(option.name)
                    .fontWeight(.medium)
                if isWinner {
                    Text("Winner")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                }
                Spacer()
                if isMine {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("\(option.votesText), \(poll.percent(for: option))%")
                    .font(.subheadline)
                    .foregroundStyle(isMine ? Color.white.opacity(0.8) : Color.secondary)
            }
            ProgressView(value: Double(option.votes), total: Double(max(poll.totalVotes, 1)))
                .tint(isMine ? .white : .accentColor)
        }
        .padding()
        .foregroundStyle(isMine ? Color.white : Color.primary)
        .background(isMine ? Color.accentColor : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16))
    }
}

// Details for one option with the Vote button at the bottom
struct VoteSheet: View {
    let optionID: UUID
    @Environment(LunchStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var poll: DayPoll {
        store.selectedPoll
    }

    // Looked up live so the numbers update after voting
    private var option: PollOption? {
        poll.options.first { $0.id == optionID }
    }

    private var isMine: Bool {
        poll.myVoteID == optionID
    }

    var body: some View {
        NavigationStack {
            if let option {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(poll.dayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(option.name)
                            .font(.largeTitle.bold())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(option.votesText)
                            Spacer()
                            Text("\(poll.percent(for: option))% of \(poll.totalVotes)")
                        }
                        .foregroundStyle(.secondary)
                        ProgressView(value: Double(option.votes), total: Double(max(poll.totalVotes, 1)))
                        Text(poll.rank(of: option) == 1 ? "Leading right now" : "Ranked \(poll.rank(of: option)) of \(poll.options.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !poll.isOpen {
                        Text("Voting for \(poll.dayName) is closed.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    } else if isMine {
                        Button {
                            store.removeVote()
                            dismiss()
                        } label: {
                            Text("Remove Vote")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    } else {
                        Button {
                            store.vote(for: option)
                            dismiss()
                        } label: {
                            Text("Vote for \(option.name)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
