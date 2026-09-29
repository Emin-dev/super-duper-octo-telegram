import Foundation

enum RideTariff: String, Codable, CaseIterable {
    case minute, hour, day
}

struct RideQuote: Equatable {
    let total: Decimal
    let planMinutes: Int
}

/// Shared by the live meter, checkout and settlement. Currency uses Decimal.
enum RidePricing {
    static let unlock: Decimal = 1
    static let minute: Decimal = Decimal(string: "0.25")!
    static let hour: Decimal = 15
    static let day: Decimal = 60

    static func quote(tariff: RideTariff, elapsed: TimeInterval,
                      booked: TimeInterval = 0, availableMinutes: Int = 0) -> RideQuote {
        let seconds = max(0, elapsed)
        if tariff == .minute {
            let minutes = max(1, Int(ceil(seconds / 60)))
            let covered = min(minutes, max(0, availableMinutes))
            return RideQuote(total: unlock + Decimal(minutes - covered) * minute,
                             planMinutes: covered)
        }
        let hours = max(1, Int(ceil(max(seconds, booked) / 3600)))
        return RideQuote(total: unlock + cappedHours(hours, hourly: hour, daily: day), planMinutes: 0)
    }

    /// Full 24-hour periods plus the remaining hours, capped at one day rate.
    static func cappedHours(_ hours: Int, hourly: Decimal, daily: Decimal) -> Decimal {
        let hours = max(0, hours)
        return Decimal(hours / 24) * daily + min(Decimal(hours % 24) * hourly, daily)
    }

    static func rentalDays(duration: TimeInterval) -> Int {
        let hours = max(0, duration) / 3600
        let fullDays = Int(hours / 24)
        let remainder = hours - Double(fullDays * 24)
        return max(1, fullDays + (remainder > 2 ? 1 : 0))
    }
}
