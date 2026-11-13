import SwiftUI

// Small pieces used on more than one screen

// A food photo that fills its frame and crops the edges, so every photo lines up.
// Photos live in Assets, named after the food: "Cheese Pizza" uses "cheese-pizza".
struct FoodPhoto: View {
    let foodName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 12

    init(_ foodName: String, height: CGFloat, cornerRadius: CGFloat = 12) {
        self.foodName = foodName
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                Image(foodName.lowercased().replacingOccurrences(of: " ", with: "-"))
                    .resizable()
                    .scaledToFill()
                    // The zoomed photo spills past its frame. The spill is hidden, but
                    // without this it would still block taps on whatever sits above or below.
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Taps count inside the visible photo, so it still works inside a button
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// Diet labels like "Vegetarian" in small pills
struct DietTagsRow: View {
    let tags: [DietTag]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Label(tag.rawValue, systemImage: tag.symbol)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
        }
    }
}

// A sideways row of school days, opened on the selected day.
// Starts with about three months back. The "Earlier" chip adds three more each tap.
struct DateStrip: View {
    let daysAhead: Int
    @Binding var selection: Date
    @State private var daysBack = 90

    private var dates: [Date] {
        LunchStore.schoolDays(daysBack: daysBack, daysAhead: daysAhead)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    Button {
                        daysBack += 90
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Earlier")
                                .font(.caption2)
                        }
                        .frame(width: 56, height: 64)
                        .foregroundStyle(.tint)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    ForEach(dates, id: \.self) { date in
                        DayChip(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selection)) {
                            selection = date
                        }
                        .id(date)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
            // Follow along when something else picks the day, like the Today button
            .onChange(of: selection) {
                withAnimation { proxy.scrollTo(selection, anchor: .center) }
            }
        }
    }
}

// One day in the strip: weekday, date number, and month or "Today"
struct DayChip: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption.weight(.semibold))
                Text(date.formatted(.dateTime.day()))
                    .font(.title3.weight(.semibold))
                Text(isToday ? "Today" : date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
            }
            .frame(width: 56)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// Pins the page's main button to the bottom of the screen
extension View {
    func bottomBar(@ViewBuilder _ content: () -> some View) -> some View {
        safeAreaInset(edge: .bottom) {
            content()
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
        }
    }
}

// The big button at the bottom of a page. Always solid so it's easy to read.
// Orange when tapping it does something. Dark when it's telling you what to do first.
struct MainButton: View {
    let title: String
    let systemImage: String
    let isReady: Bool
    var isBusy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Label(title, systemImage: systemImage)
                    .fontWeight(.semibold)
                    // White on orange. On the dark button, the page color, so it flips in dark mode.
                    .foregroundStyle(isReady ? Color.white : Color(.systemBackground))
                    .opacity(isBusy ? 0 : 1)
                if isBusy {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(isReady || isBusy ? Color.accentColor : Color.primary)
        // Not tappable until it's ready, but not grayed out either
        .allowsHitTesting(isReady && !isBusy)
    }
}

// A searchable list of schools. Tapping one picks it and goes back.
struct SchoolPicker: View {
    let schools: [School]
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var results: [School] {
        search.isEmpty ? schools : schools.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List(results) { school in
            Button {
                selection = school.id
                dismiss()
            } label: {
                HStack {
                    Text(school.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    if school.id == selection {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Search schools")
        .overlay {
            if results.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
        .navigationTitle("Choose School")
        .navigationBarTitleDisplayMode(.inline)
    }
}
