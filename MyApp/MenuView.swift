import SwiftUI

// Scroll back to any past school day to see what was served. Stops at today.
struct MenuView: View {
    @Environment(LunchStore.self) private var store

    private var day: DayMenu {
        store.menu(on: store.selectedMenuDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DateStrip(daysAhead: 0, selection: $store.selectedMenuDate)
                    mainDish
                    sides
                }
                .padding()
            }
            .refreshable {
                await store.reload()
            }
            .bottomBar {
                Button {
                    store.selectedVoteDate = LunchStore.voteToday
                    store.selectedTab = .vote
                } label: {
                    Text("Vote on Next Week")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Menu")
            .navigationSubtitle(isToday ? "Today's lunch" : "Past lunch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Today") {
                    store.selectedMenuDate = LunchStore.menuToday
                }
            }
        }
    }

    // Big photo of the main dish with its name, calories and diet labels
    private var mainDish: some View {
        VStack(alignment: .leading, spacing: 12) {
            FoodPhoto(day.main.name, height: 170, cornerRadius: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(day.date.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                Text(day.main.name)
                    .font(.title2.bold())
                Text("\(day.main.calories) cal. \(day.totalCalories) cal with sides.")
                    .foregroundStyle(.secondary)
            }
            DietTagsRow(tags: day.main.tags)
        }
    }

    // Sides in one card, each with a small photo, split by thin lines
    private var sides: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sides")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(day.sides) { item in
                    if item.id != day.sides.first?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                    HStack(spacing: 14) {
                        FoodPhoto(item.name, height: 48, cornerRadius: 10)
                            .frame(width: 48)
                        Text(item.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(item.calories) cal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
