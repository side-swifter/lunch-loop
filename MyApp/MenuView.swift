import SwiftUI

struct MenuView: View {
    @Environment(LunchStore.self) private var store

    private var day: DayMenu {
        store.days[store.selectedDayIndex]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    daySelector
                    daySection
                }
                .padding()
            }
            .navigationTitle("Menu")
            .navigationSubtitle("This week")
        }
    }

    // One chip per day, showing the date or "Today"
    private var daySelector: some View {
        HStack(spacing: 8) {
            ForEach(store.days.indices, id: \.self) { index in
                let isToday = index == LunchStore.todayIndex
                let date = store.date(forDayIndex: index)

                DayChip(title: store.days[index].shortName,
                        subtitle: isToday ? "Today" : date.formatted(.dateTime.month(.abbreviated).day()),
                        isSelected: index == store.selectedDayIndex) {
                    store.selectedDayIndex = index
                }
            }
        }
    }

    // The selected day: main dish first, then the sides
    private var daySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.name)
                    .font(.title3.bold())
                Text("\(day.items.count) items. \(day.totalCalories) cal total.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Main")
                .font(.headline)
                .padding(.top, 8)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.main.name)
                        .font(.title2.bold())
                    Text("\(day.main.calories) cal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: day.main.symbol)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            Text("Sides")
                .font(.headline)
                .padding(.top, 8)

            ForEach(day.sides) { item in
                HStack {
                    Image(systemName: item.symbol)
                        .foregroundStyle(.secondary)
                        .frame(width: 28)
                    Text(item.name)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(item.calories) cal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
