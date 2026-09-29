import SwiftUI

/// The status vocabulary is FIXED and exhaustive. Do not add cases without
/// updating the Figma `TripStatusChip` component set to match.
public enum TripStatus: String, CaseIterable, Codable {
    case waitingForHost, upcoming, ongoing, paymentPending, completed, declined, cancelled

    public var label: String {
        switch self {
        case .waitingForHost: "Waiting for host"
        case .upcoming:       "Upcoming"
        case .ongoing:        "Riding now"
        case .paymentPending: "Payment needed"
        case .completed:      "Completed"
        case .declined:       "Declined"
        case .cancelled:      "Cancelled"
        }
    }

    /// honey = riding right now, gold = new or upcoming.
    public var tint: Color {
        switch self {
        case .waitingForHost, .upcoming: Theme.accentAmber
        case .ongoing:                   Theme.accentHoney
        case .completed:                 Theme.inkSoft
        case .declined, .cancelled, .paymentPending:      Theme.danger
        }
    }
}

