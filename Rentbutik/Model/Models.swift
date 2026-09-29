import Foundation

/// Azerbaijani manat. The shipping design had ₦ naira on Wallet / Top up —
/// that was a live bug (see `SCREENS.md`). Format money through this code so
/// the symbol and grouping come from the locale, never from a hardcoded string.
enum Currency {
    static let code = "AZN"
}

// MARK: - Vehicle

enum VehicleKind: String, Equatable, CaseIterable, Codable {
    case car, electric, golfCart

    var symbol: String {
        switch self {
        case .car:      "car.fill"
        case .electric: "bolt.car.fill"
        case .golfCart: "steeringwheel"
        }
    }
}

enum Transmission: String, Equatable {
    case automatic, manual

    var label: LocalizedStringResource {
        switch self {
        case .automatic: "Automatic"
        case .manual:    "Manual"
        }
    }
}

enum FuelType: String, Equatable {
    case petrol, diesel, electric, hybrid

    var label: LocalizedStringResource {
        switch self {
        case .petrol:   "Petrol"
        case .diesel:   "Diesel"
        case .electric: "Electric"
        case .hybrid:   "Hybrid"
        }
    }
}

struct Vehicle: Identifiable, Equatable {
    let id: String
    var name: String
    var kind: VehicleKind
    var seats: Int
    var transmission: Transmission
    var fuel: FuelType
    var rating: Double
    var ratingCount: Int
    var area: String

    /// Cars price by the day; EV and golf carts price by the hour.
    var pricePerDay: Decimal?
    var pricePerHour: Decimal?
    var pricePerMinute: Decimal?

    /// Asset-catalogue name. `nil` renders the placeholder — no photography
    /// has been exported from Figma yet.
    var photoName: String?

    /// EV only.
    var batteryPercent: Int?
    var rangeKm: Int?

    /// Where the vehicle is parked, for map pins. EV and golf only.
    var latitude: Double? = nil
    var longitude: Double? = nil
    /// "1 min walk" on EV01 / G01.
    var walkMinutes: Int? = nil
}

// MARK: - Trip

struct Trip: Identifiable, Equatable, Codable {
    let id: String
    var vehicleName: String
    /// Which Home module this trip belongs to, so that module can carry the
    /// live state instead of a separate banner.
    var vehicleKind: VehicleKind
    var status: TripStatus
    var startDate: Date
    var endDate: Date
    var total: Decimal
    var photoName: String?
    /// The vehicle this trip is on, so Home reopens the right one.
    var vehicleID: String = ""
    var tariff: RideTariff = .hour
    var billingStoppedAt: Date? = nil
    var reservedPlanMinutes = 0
    var depositPaymentID: String? = nil
    var returnPlace: String = "Designated return area"
}

// MARK: - Host

struct Listing: Identifiable, Equatable {
    let id: String
    var vehicleName: String
    var year: Int
    var pricePerDay: Decimal
    var isActive: Bool
    var views: Int
}

// MARK: - Chats

/// Named `MessageThread` rather than `Thread` to avoid colliding with
/// `Foundation.Thread`.
struct MessageThread: Identifiable, Equatable {
    let id: String
    var counterpartName: String
    /// "Host • Tesla Model Y"
    var subtitle: String
    var messages: [Message]
    var isUnread: Bool
    /// C01: the vehicle line under the preview — "Mercedes-AMG GT".
    var vehicle: String? = nil
    /// C01: the orange count badge.
    var unreadCount: Int = 0
    /// C01: Support is the one pinned conversation.
    var isPinned: Bool = false
    /// C02: under the nav title — "Host · usually replies in 10 min".
    var presence: String? = nil

    var initials: String {
        counterpartName.split(separator: " ").prefix(2)
            .compactMap(\.first).map(String.init).joined()
    }
}

struct Message: Identifiable, Equatable {
    let id: String
    var text: String
    var isFromMe: Bool
    var sentAt: Date
    /// A photo, video or document sent with (or instead of) the text.
    var attachment: MessageAttachment? = nil

    /// What the on-device agent reads for this message.
    var promptText: String {
        switch attachment {
        case .photo?: text.isEmpty ? "[The renter sent a photo]" : "[Photo] \(text)"
        case .video?: text.isEmpty ? "[The renter sent a video]" : "[Video] \(text)"
        case .file(let name, _, _)?: "[The renter sent a document: \(name)] \(text)"
        case nil: text
        }
    }
}

/// Chat attachments. Files live in the app's own container, so they
/// survive the picker and open in Quick Look.
enum MessageAttachment: Equatable {
    case photo(URL)
    case video(URL)
    case file(name: String, url: URL, bytes: Int)

    var url: URL {
        switch self {
        case .photo(let u), .video(let u): u
        case .file(_, let u, _): u
        }
    }
}

// MARK: - Home

/// Named `AppNotification` to avoid colliding with `Foundation.Notification`.
struct AppNotification: Identifiable, Equatable {
    let id: String
    var symbol: String
    var title: String
    var detail: String
    var isUnread: Bool
    var date: Date
}

struct NewsItem: Identifiable, Equatable {
    let id: String
    /// The pill over the photo — "Welcome", "Hosting".
    var category: String
    var headline: String
    var photoName: String?
    /// Stands in for the photo until the Figma imagery is exported.
    var symbol: String
}

// MARK: - Wallet

struct Transaction: Identifiable, Equatable {
    let id: String
    var label: String
    /// Negative is spend, positive is earn.
    var amount: Decimal
    var date: Date
}

/// A saved place — L01. `symbol` is an SF Symbol name.
struct SavedPlace: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var address: String
    var symbol: String
    /// Where the pin goes on EV01e and other place pickers.
    var latitude: Double = 40.3777
    var longitude: Double = 49.8395
}

// MARK: - EV08 · EV plan (minute packages)

enum EVPlanPeriod: String, CaseIterable, Identifiable, Codable {
    case weekly, monthly, yearly
    var id: String { rawValue }
    var days: Int {
        switch self { case .weekly: 7; case .monthly: 30; case .yearly: 365 }
    }
}

struct EVPlanOption: Identifiable, Hashable, Codable {
    let period: EVPlanPeriod
    let minutes: Int
    let price: Decimal
    /// Pay-as-you-go price for the same minutes, struck through.
    let list: Decimal
    var id: String { "\(period.rawValue)-\(minutes)" }
    var perMinute: Decimal { price / Decimal(minutes) }
    var saving: Decimal { list - price }

    /// Verbatim from EV08 / EV08b / EV08c.
    static func options(for period: EVPlanPeriod) -> [EVPlanOption] {
        switch period {
        case .weekly:
            [.init(period: .weekly, minutes: 30, price: 7, list: 7.5),
             .init(period: .weekly, minutes: 60, price: 13, list: 15),
             .init(period: .weekly, minutes: 120, price: 25, list: 30),
             .init(period: .weekly, minutes: 180, price: 36, list: 45),
             .init(period: .weekly, minutes: 300, price: 57, list: 75)]
        case .monthly:
            [.init(period: .monthly, minutes: 100, price: 21, list: 25),
             .init(period: .monthly, minutes: 200, price: 40, list: 50),
             .init(period: .monthly, minutes: 400, price: 76, list: 100),
             .init(period: .monthly, minutes: 600, price: 108, list: 150),
             .init(period: .monthly, minutes: 1000, price: 170, list: 250)]
        case .yearly:
            [.init(period: .yearly, minutes: 1000, price: 160, list: 250),
             .init(period: .yearly, minutes: 2000, price: 300, list: 500),
             .init(period: .yearly, minutes: 3000, price: 420, list: 750),
             .init(period: .yearly, minutes: 5000, price: 650, list: 1250),
             .init(period: .yearly, minutes: 10000, price: 1200, list: 2500)]
        }
    }

    /// The package EV08 pre-selects for each period.
    static func suggested(for period: EVPlanPeriod) -> EVPlanOption {
        let all = options(for: period)
        return period == .monthly ? all[3] : all[2]
    }
}

struct EVPlan: Equatable, Codable {
    let option: EVPlanOption
    let until: Date
    var usedMinutes: Int
}

