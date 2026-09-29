import SwiftUI

/// `Rentbutik / Date range calendar` (295:2097) — R01a, G01a, EV day tariff.
///
/// Month row (title + ‹ › circles on surface/fill), weekday row, a 7-column
/// grid of 40 pt rows. Range start and end are 38 pt brand/solid circles with
/// text/on-gold digits; the days between sit on a brand/tint band; past days
/// are text/secondary and can't be tapped; today is text/gold. Pick-up and
/// Return tiles follow. First tap sets pick-up, the next sets return.
struct RangeCalendar: View {
    @Binding var dates: RentalDates
    /// A ride that starts now (EV day tariff): pick-up stays put and taps
    /// choose the return day only.
    var startLocked = false

    @Environment(\.calendar) private var calendar
    @State private var month: Date = .now
    @State private var pickingReturn = false
    @State private var taps = 0

    private let rowHeight: CGFloat = 40
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                monthRow
                weekdayRow
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(gridDays, id: \.self) { day in
                        DayCell(day: day,
                                inMonth: calendar.isDate(day, equalTo: month, toGranularity: .month),
                                isPast: day < calendar.startOfDay(for: .now),
                                isToday: calendar.isDateInToday(day),
                                role: role(of: day),
                                height: rowHeight) { tap(day) }
                    }
                }
                .animation(Theme.snappy, value: dates)
            }

            HStack(spacing: 10) {
                TimeField(label: "Pick-up", date: $dates.pickUp)
                    .disabled(startLocked)
                TimeField(label: "Return", date: $dates.dropOff)
            }
        }
        .onAppear { month = calendar.startOfMonth(for: dates.pickUp) }
        .sensoryFeedback(.selection, trigger: taps)
    }

    // MARK: Rows

    private var monthRow: some View {
        HStack {
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .contentTransition(.opacity)
            Spacer()
            HStack(spacing: 8) {
                stepButton("chevron.left", by: -1)
                    .disabled(calendar.isDate(month, equalTo: .now, toGranularity: .month))
                stepButton("chevron.right", by: 1)
            }
        }
        .frame(height: 36)
    }

    private func stepButton(_ symbol: String, by months: Int) -> some View {
        Button {
            withAnimation(Theme.smooth) {
                month = calendar.date(byAdding: .month, value: months, to: month) ?? month
            }
        } label: {
            Image(systemName: symbol)
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.ink)
                .frame(width: 32, height: 32)
                .background(Theme.fill, in: .circle)
        }
        .buttonStyle(PressScale(haptic: .click))
        .accessibilityLabel(months < 0 ? "Previous month" : "Next month")
    }

    private var weekdayRow: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        let ordered = Array(symbols[first...] + symbols[..<first])
        return HStack(spacing: 0) {
            ForEach(Array(ordered.enumerated()), id: \.offset) { _, s in
                Text(s)
                    .font(Theme.Font.captionSemibold)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 16)
    }

    // MARK: Days

    /// Whole weeks covering the month, including the dim neighbour days.
    private var gridDays: [Date] {
        let start = calendar.startOfMonth(for: month)
        let weekday = calendar.component(.weekday, from: start)
        let lead = (weekday - calendar.firstWeekday + 7) % 7
        let first = calendar.date(byAdding: .day, value: -lead, to: start) ?? start
        let daysInMonth = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let cells = Int(((Double(lead + daysInMonth)) / 7).rounded(.up)) * 7
        return (0..<cells).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
    }

    private func role(of day: Date) -> DayCell.Role {
        let a = calendar.startOfDay(for: dates.pickUp)
        let b = calendar.startOfDay(for: dates.dropOff)
        if day == a && day == b { return .single }
        if day == a { return .start }
        if day == b { return .end }
        if day > a && day < b { return .between }
        return .none
    }

    private func tap(_ day: Date) {
        taps += 1
        let keepTime = { (src: Date) in
            calendar.date(bySettingHour: calendar.component(.hour, from: src),
                          minute: calendar.component(.minute, from: src), second: 0, of: day) ?? day
        }
        let pickUpDay = calendar.startOfDay(for: dates.pickUp)
        if startLocked || (pickingReturn && day > pickUpDay) {
            guard day >= pickUpDay else { return }
            dates.dropOff = max(keepTime(dates.dropOff), dates.pickUp.addingTimeInterval(3600))
            pickingReturn = false
        } else {
            dates.pickUp = keepTime(dates.pickUp)
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            dates.dropOff = calendar.date(bySettingHour: calendar.component(.hour, from: dates.dropOff),
                                          minute: calendar.component(.minute, from: dates.dropOff),
                                          second: 0, of: next) ?? next
            pickingReturn = true
        }
    }
}

private struct DayCell: View {
    enum Role { case none, start, end, single, between }

    let day: Date
    let inMonth: Bool
    let isPast: Bool
    let isToday: Bool
    let role: Role
    let height: CGFloat
    let action: () -> Void

    @Environment(\.calendar) private var calendar

    private var isEdge: Bool { role == .start || role == .end || role == .single }

    var body: some View {
        Button(action: action) {
            Text(day.formatted(.dateTime.day()))
                .font(isEdge || isToday ? Theme.Font.headline : Theme.Font.body)
                .foregroundStyle(foreground)
                .frame(width: 38, height: 38)
                .background {
                    if isEdge { Circle().fill(Theme.brandSolid) }
                }
                .frame(maxWidth: .infinity, minHeight: height)
                .background { band }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isPast)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(isEdge ? .isSelected : [])
    }

    private var foreground: Color {
        if isEdge { return Theme.onGold }
        if !inMonth { return Theme.inkSoft.opacity(0.45) }
        if isPast { return Theme.inkSoft }
        if isToday { return Theme.goldText }
        return Theme.ink
    }

    /// The brand/tint band joining start and end.
    @ViewBuilder private var band: some View {
        switch role {
        case .between:
            Theme.brandTint.frame(height: 38)
        case .start:
            HStack(spacing: 0) { Color.clear; Theme.brandTint }.frame(height: 38)
        case .end:
            HStack(spacing: 0) { Theme.brandTint; Color.clear }.frame(height: 38)
        default:
            EmptyView()
        }
    }
}

/// "Pick-up · Mon 28 · 10:00" — day label and a compact native time picker.
private struct TimeField: View {
    let label: LocalizedStringKey
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day()))
                    .font(Theme.Font.subheadlineSemibold)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .fixedSize()
                Text(verbatim: "·").foregroundStyle(Theme.inkSoft)
                DatePicker(label, selection: $date, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .controlSize(.mini)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fill, in: .rect(cornerRadius: 14))
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}

