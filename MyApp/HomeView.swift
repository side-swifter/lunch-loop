import SwiftUI

struct HomeView: View {
    @Environment(LunchStore.self) private var store
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    todayCard
                    weekSection
                    voteSection
                }
                .padding()
            }
            .navigationTitle("Lunch Loop")
            .navigationSubtitle(Date.now.formatted(date: .complete, time: .omitted))
            .toolbar {
                Button("Settings", systemImage: "gearshape") {
                    showingSettings = true
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // Today's meal: dish names on the left, a plain symbol on the right
    private var todayCard: some View {
        let menu = store.today
        let sides = menu.sides.map(\.name).joined(separator: ", ")

        return VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.title3.bold())

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(menu.main.name)
                        .font(.title2.bold())
                    Text("with \(sides)")
                        .foregroundStyle(.secondary)
                    Text("\(menu.totalCalories) cal")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                Spacer()
                Image(systemName: menu.main.symbol)
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // One small card per school day, scrolling sideways
    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.title3.bold())

            // Starts centered on today, then snaps card to card as you scroll
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(store.days.indices, id: \.self) { index in
                            let day = store.days[index]
                            let isToday = index == LunchStore.todayIndex

                            VStack(alignment: .leading, spacing: 6) {
                                Text(isToday ? "Today" : day.shortName)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(isToday ? Color.accentColor : Color.secondary)
                                Text(day.main.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer(minLength: 0)
                                Text("\(day.main.calories) cal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(width: 140, height: 120, alignment: .leading)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                            .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .onAppear {
                    proxy.scrollTo(LunchStore.todayIndex, anchor: .center)
                }
            }
        }
    }

    // Top three options with a bar for each, so the standings are readable at a glance
    private var voteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Week's Vote")
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 12) {
                ForEach(store.polls) { poll in
                    HStack {
                        Text(poll.shortName)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .leading)
                        Text(poll.summaryText)
                        Spacer()
                        if poll.myVoteID != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        } else if !poll.isOpen {
                            Text("Closed")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
