import SwiftUI

// Today's lunch up top, then recent lunches and recent votes.
// Home hides the nav bar and tab bar. The two buttons at the bottom get you around.
struct HomeView: View {
    @Environment(LunchStore.self) private var store
    @State private var showingAccount = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    FoodPhoto(store.todayMenu.main.name, height: 220, cornerRadius: 24)
                    dishInfo
                    itemGrid
                    weekSection
                    voteSection
                    if let lastUpdated = store.lastUpdated {
                        Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .refreshable {
                await store.reload()
            }
            // Header stays pinned at the top, outside the scrolling content
            .safeAreaInset(edge: .top) {
                header
            }
            .bottomBar {
                bottomButtons
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showingAccount) {
            SettingsView()
        }
    }

    // Logo and school on the left, account button on the right
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                LogoView(size: 24)
                Text(store.school?.name ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Account", systemImage: "person.crop.circle") {
                showingAccount = true
            }
            .labelStyle(.iconOnly)
            .font(.title)
            // Bigger tap area than the icon itself
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // Dish name, date and calories, then the diet labels
    private var dishInfo: some View {
        let menu = store.todayMenu
        let date = menu.date.formatted(.dateTime.weekday(.wide).month().day())

        // On a weekend this shows Friday's lunch, so only say "Today" when it is
        return VStack(alignment: .leading, spacing: 8) {
            Text(Calendar.current.isDateInToday(menu.date) ? "Today, \(date)" : date)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
            Text(menu.main.name)
                .font(.largeTitle)
            Text("\(menu.totalCalories) cal for the whole tray")
                .foregroundStyle(.secondary)
            DietTagsRow(tags: menu.main.tags)
                .padding(.top, 8)
        }
    }

    // One photo tile per item on today's tray
    private var itemGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(store.todayMenu.items) { item in
                VStack(alignment: .leading, spacing: 6) {
                    FoodPhoto(item.name, height: 100)
                    Text(item.name)
                        .font(.footnote.weight(.medium))
                        .lineLimit(2, reservesSpace: true)
                    Text("\(item.calories) cal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // The last five school days, ending on today. Tap one to open it on the Menu tab.
    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Lunches")
                .font(.title3.bold())

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(store.recentMenus) { day in
                            let isToday = Calendar.current.isDateInToday(day.date)

                            Button {
                                store.selectedMenuDate = day.date
                                store.selectedTab = .menu
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    FoodPhoto(day.main.name, height: 90)
                                    Text(isToday ? "Today" : day.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(isToday ? Color.accentColor : Color.secondary)
                                    Text(day.main.name)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                }
                                .frame(width: 140)
                            }
                            .buttonStyle(.plain)
                            .id(day.date)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                // Start at the newest day
                .onAppear {
                    proxy.scrollTo(LunchStore.menuToday, anchor: .trailing)
                }
            }
        }
    }

    // Today's vote as its own card with photos of the choices, then past results below
    private var voteSection: some View {
        let polls = store.recentPolls

        return VStack(alignment: .leading, spacing: 12) {
            Text("Votes")
                .font(.title3.bold())

            if let today = polls.first {
                Button {
                    openVote(today)
                } label: {
                    todayVoteCard(today)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(polls.dropFirst()) { poll in
                    if poll.id != polls.dropFirst().first?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                    Button {
                        openVote(poll)
                    } label: {
                        resultRow(poll)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func openVote(_ poll: DayPoll) {
        store.selectedVoteDate = poll.date
        store.selectedTab = .vote
    }

    // Deadline on top, a small photo of each choice, then what you picked
    private func todayVoteCard(_ poll: DayPoll) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Calendar.current.isDateInToday(poll.date) ? "Today's vote" : "Next vote")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                Spacer()
                Label(poll.deadlineText, systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(poll.options) { option in
                    VStack(spacing: 4) {
                        FoodPhoto(option.name, height: 64, cornerRadius: 10)
                            .overlay(alignment: .topTrailing) {
                                if option.id == poll.myVoteID {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.white, Color.accentColor)
                                        .padding(4)
                                }
                            }
                        Text(option.name)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }

            HStack {
                Text(poll.myVote.map { "You picked \($0.name)" } ?? (poll.isOpen ? "Tap to pick your favorite" : poll.summaryText))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    // Photo of the winning dish, the day, what won and by how much
    private func resultRow(_ poll: DayPoll) -> some View {
        HStack(spacing: 12) {
            if let leader = poll.leader {
                FoodPhoto(leader.name, height: 44, cornerRadius: 10)
                    .frame(width: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(poll.date.formatted(.dateTime.weekday(.wide)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(poll.summaryText)
                    .font(.subheadline.weight(.medium))
            }
            Spacer()
            if let leader = poll.leader, !poll.isOpen {
                Text("\(poll.percent(for: leader))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            if poll.myVoteID != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // The main way off Home, since the tab bar is hidden here
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button {
                store.selectedVoteDate = LunchStore.voteToday
                store.selectedTab = .vote
            } label: {
                Text("Vote Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                store.selectedMenuDate = LunchStore.menuToday
                store.selectedTab = .menu
            } label: {
                Text("See Menu")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}
