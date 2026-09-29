import SwiftUI

/// Status chip — Production › 00 Reusable assets.
///
/// Caption 1 / Semibold with a leading dot, on a 12 % tint of its own colour.
/// Four families, read from T01's bindings:
/// - `.pending` — `brand/tint` + `text/gold` (Verifying documents, Waiting
///   for host, Waiting for driver, Reserved)
/// - `.success` — `tint/status-success-12` + `status/success` (Booked, Ongoing)
/// - `.danger`  — `tint/status-danger-12` + `status/danger` (Declined, Cancelled)
/// - `.neutral` — `tint/text-secondary-12` + `text/secondary` (Completed)
struct StatusChip: View {
    enum Tone: String, Codable { case pending, success, danger, neutral, onPhoto }

    let label: LocalizedStringKey
    let tone: Tone

    init(_ label: LocalizedStringKey, tone: Tone) {
        self.label = label
        self.tone = tone
    }

    private var foreground: Color {
        switch tone {
        case .pending:  Theme.goldText
        case .success, .onPhoto: Theme.success
        case .danger:   Theme.danger
        case .neutral:  Theme.inkSoft
        }
    }

    private var background: Color {
        switch tone {
        case .pending:  Theme.brandTint
        case .success:  Theme.success.opacity(0.12)
        case .danger:   Theme.danger.opacity(0.12)
        case .neutral:  Theme.inkSoft.opacity(0.12)
        // tint/surface-card-92 — the chip that sits on a photo.
        case .onPhoto:  Theme.card.opacity(0.92)
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(foreground)
                .frame(width: 6, height: 6)
            Text(label)
                .font(tone == .onPhoto ? Theme.Font.footnote : Theme.Font.captionSemibold)
                .foregroundStyle(foreground)
                .lineLimit(1)
        }
        .padding(.horizontal, tone == .onPhoto ? 10 : 8)
        .padding(.vertical, tone == .onPhoto ? 5 : 3)
        // A status is a label, not a control, so it takes the flat 12 % tint
        // T01 binds — glass is kept for things you can tap.
        .background(background, in: .capsule)
    }
}

