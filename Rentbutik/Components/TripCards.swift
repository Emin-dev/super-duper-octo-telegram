import SwiftUI

struct PaymentRecoveryCard: View {
    let total: Decimal
    let onPayment: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ride ended · payment needed", systemImage: "creditcard.trianglebadge.exclamationmark")
                .font(Theme.Font.headline).foregroundStyle(Theme.danger)
            Text(total, format: .currency(code: Currency.code))
                .font(Theme.Font.largeTitle).foregroundStyle(Theme.ink)
            Text("The meter has stopped. Your total will not increase while you update payment.")
                .font(Theme.Font.body).foregroundStyle(Theme.inkSoft)
            Button("Payment methods", action: onPayment)
                .buttonStyle(.rentbutik).buttonBorderShape(.capsule).controlSize(.large)
            Button("Retry payment", action: onRetry)
                .buttonStyle(.rentbutik).buttonBorderShape(.capsule).controlSize(.large)
        }
        .padding(20).glassMapCard()
    }
}

/// A live record, shared by every module. Time, return place and next action lead.
struct ActiveTripCard: View {
    let trip: Trip
    let store: Store
    let onOpen: () -> Void
    let onSupport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: trip.vehicleKind.symbol)
                    .font(.title2).foregroundStyle(Theme.goldText)
                    .frame(width: 48, height: 48).background(Theme.brandTint, in: .rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 5) {
                    Text(trip.vehicleName).font(Theme.Font.title3)
                    StatusChip(LocalizedStringKey(trip.status.label), tone: trip.status == .paymentPending ? .danger : .success)
                }
                Spacer(minLength: 0)
            }
            if trip.status == .paymentPending {
                Text("Ride ended. The meter is stopped.").font(Theme.Font.body)
            } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trip.vehicleKind == .golfCart ? "Time remaining" : "Elapsed")
                                .font(Theme.Font.subheadlineRegular).foregroundStyle(Theme.inkSoft)
                            if trip.vehicleKind == .golfCart {
                                Text(timerInterval: context.date...max(context.date, trip.endDate), countsDown: true)
                                    .font(Theme.Font.title1).monospacedDigit()
                            } else {
                                Text(trip.startDate, style: .timer).font(Theme.Font.title1).monospacedDigit()
                            }
                        }
                        Spacer()
                        Text(store.rideCost(trip, at: context.date), format: .currency(code: Currency.code))
                            .font(Theme.Font.title2).monospacedDigit()
                    }
                }
                Label(trip.returnPlace, systemImage: "mappin.and.ellipse")
                    .font(Theme.Font.body).foregroundStyle(Theme.inkSoft)
                if trip.tariff != .minute || trip.vehicleKind == .golfCart {
                    Text("Return by \(trip.endDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(Theme.Font.subheadlineSemibold)
                }
            }
            HStack {
                Button(trip.status == .paymentPending ? "Settle payment" : trip.vehicleKind == .golfCart ? "Return cart" : "Open ride", action: onOpen)
                    .frame(maxWidth: .infinity)
                Button("Support", systemImage: "message.fill", action: onSupport)
            }
            .buttonStyle(.rentbutik).buttonBorderShape(.capsule).controlSize(.large)
        }
        .foregroundStyle(Theme.ink).padding(20).glassCard()
        .accessibilityElement(children: .contain)
    }
}

struct TripReceiptSheet: View {
    let record: TripRecord
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(record.title).font(.headline)
                    Text(record.status)
                    ForEach(record.rows) { row in LabeledContent(row.label, value: row.value) }
                    if let note = record.note { Text(note).foregroundStyle(.secondary) }
                }
                Section("Amount") {
                    switch record.amount {
                    case .money(let amount): Text(amount, format: .currency(code: Currency.code))
                    case .refunded(let amount): LabeledContent("Refunded", value: amount.formatted(.currency(code: Currency.code)))
                    case .noCharge: Text("No charge")
                    }
                }
            }
            .navigationTitle("Trip details").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
