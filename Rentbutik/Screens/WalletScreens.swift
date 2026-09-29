import SwiftUI
import PassKit

// MARK: - Data

struct WalletActivity: Identifiable, Equatable, Codable {
    enum Kind: String, CaseIterable, Identifiable, Codable {
        case all, rides, topUps, refunds
        var id: String { rawValue }
        var label: LocalizedStringKey {
            switch self {
            case .all:     "All"
            case .rides:   "Rides"
            case .topUps:  "Top-ups"
            case .refunds: "Refunds"
            }
        }
    }
    let id: String
    let kind: Kind
    let symbol: String
    let title: String
    let detail: String
    let amount: Decimal
}

struct PaymentMethod: Identifiable, Equatable {
    let id: String
    let symbol: String
    let title: String
    let detail: String
}

/// Copy verbatim from W02 / W03 in Design-flow.
enum WalletCatalog {
    static let activity: [WalletActivity] = [
        .init(id: "a1", kind: .rides,   symbol: "bolt.car.fill",       title: "EV ride",          detail: "18 Sep · 60 min", amount: -16),
        .init(id: "a2", kind: .topUps,  symbol: "plus.circle.fill",    title: "Top up · Visa",    detail: "18 Sep",          amount: 50),
        .init(id: "a3", kind: .rides,   symbol: "steeringwheel",       title: "Golf cart 4",      detail: "14 Sep · 2 hours", amount: -32),
        .init(id: "a4", kind: .refunds, symbol: "arrow.clockwise",     title: "Refund · Porsche", detail: "8 Sep",           amount: 460),
        .init(id: "a5", kind: .rides,   symbol: "car.side.fill",       title: "Mercedes-AMG GT",  detail: "1 Sep · 1 day",   amount: -499),
    ]

    static let methods: [PaymentMethod] = [
        .init(id: "applepay", symbol: "apple.logo",        title: "Apple Pay",           detail: "Face ID"),
        .init(id: "visa",     symbol: "creditcard.fill",   title: "Visa •••• 4242",      detail: "Default · expires 08/29"),
        .init(id: "mc",       symbol: "creditcard.fill",   title: "Mastercard •••• 0780", detail: "Expires 03/28"),
        .init(id: "mpay",     symbol: "wallet.bifold.fill", title: "MPay",               detail: "Mobile wallet · top-ups"),
        .init(id: "million",  symbol: "banknote.fill",     title: "Million",             detail: "Cash top-up at a Million terminal"),
    ]
}

enum WalletRoute: Hashable { case methods, addCard, history }

private func money(_ v: Decimal, _ digits: Int = 0) -> String {
    v.formatted(.currency(code: Currency.code).precision(.fractionLength(digits)))
}

// MARK: - W01 · Wallet (sheet with its own NavigationStack)

struct WalletSheet: View {
    let store: Store
    var initialRoute: WalletRoute? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var path: [WalletRoute] = []
    @State private var addingMoney = false
    @State private var amount: Decimal = 50
    @State private var showPromo = false
    @State private var promoCode = ""
    @State private var topUps = 0
    /// A payment "in flight" — the bank round-trip takes a couple of seconds.
    @State private var processing = false
    @State private var promoResult: PromoResult?

    enum PromoResult: Identifiable {
        case added(Decimal), invalid
        var id: String { if case .added = self { "added" } else { "invalid" } }
    }

    /// Top-ups settle after a realistic delay, then the balance ticks up.
    private func topUp(_ value: Decimal) {
        guard !processing, AppConfiguration.isDemo, value >= 5, value <= 2000 else { return }
        withAnimation(Theme.snappy) { processing = true }
        Task {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.0...3.2)))
            topUps += 1
            withAnimation(Theme.smooth) {
                store.credit(value, label: String(localized: "Top up · \(store.defaultCard)"))
                processing = false
            }
        }
    }

    private func applyPromo() {
        let code = promoCode.trimmingCharacters(in: .whitespaces).uppercased()
        promoCode = ""
        guard !code.isEmpty, AppConfiguration.isDemo, !store.redeemedPromos.contains(code) else { promoResult = .invalid; return }
        withAnimation(Theme.snappy) { processing = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(Theme.snappy) { processing = false }
            if ["WELCOME", "RENTBUTIK"].contains(code) && !store.redeemedPromos.contains(code) {
                store.redeemedPromos.insert(code)
                topUps += 1
                withAnimation(Theme.smooth) { store.credit(10, label: String(localized: "Promo code \(code)"), symbol: "gift.fill") }
                promoResult = .added(10)
            } else {
                promoResult = .invalid
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    Text(store.walletBalance, format: .currency(code: Currency.code).precision(.fractionLength(2)))
                        .accessibilityIdentifier("wallet.balance")
                        .font(Theme.Font.largeTitle)
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())

                    if addingMoney {
                        AddMoneyPanel(amount: $amount, paymentLabel: store.defaultCard,
                                      onBack: { withAnimation(Theme.smooth) { addingMoney = false } },
                                      onPayWith: { path.append(.methods) },
                                      onAdd: {
                                          withAnimation(Theme.smooth) { addingMoney = false }
                                          topUp(amount)
                                      })
                        .transition(.blurReplace)
                    } else {
                        WalletActions(onAddMoney: { withAnimation(Theme.smooth) { addingMoney = true } },
                                      onCards: { path.append(.methods) },
                                      onPromo: { showPromo = true },
                                      onHistory: { path.append(.history) })
                            .transition(.blurReplace)

                        if processing {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Processing payment…")
                                    .font(Theme.Font.headline)
                                    .foregroundStyle(Theme.ink)
                            }
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.button)
                            .glassCard(Theme.Radius.card)
                            .transition(.blurReplace)
                        } else {
                            // Native Apple Pay button — black, as W01 draws it.
                            PayWithApplePayButton(.topUp) { topUp(50) }
                                .payWithApplePayButtonStyle(.black)
                                .frame(height: Theme.Size.button)
                                .clipShape(.capsule)
                                .transition(.blurReplace)

                            RentbutikPrimaryButton("Top up \(money(50)) again", symbol: "arrow.clockwise") {
                                topUp(50)
                            }
                            .transition(.blurReplace)
                        }
                    }
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, Theme.Space.noTabBarClearance)
            }
            .background(Theme.background)
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.goldText)
                }
            }
            .navigationDestination(for: WalletRoute.self) { route in
                switch route {
                case .methods: PaymentMethodsScreen(store: store) { path.append(.addCard) }
                case .addCard: AddCardScreen { path.removeLast() }
                case .history: WalletHistoryScreen(store: store)
                }
            }
            .alert("Promo code", isPresented: $showPromo) {
                TextField("Code", text: $promoCode)
                    .textInputAutocapitalization(.characters)
                Button("Apply", action: applyPromo)
                Button("Cancel", role: .cancel) { promoCode = "" }
            } message: {
                Text("Enter a code to add credit to your Wallet.")
            }
            .alert(promoResult.map { if case .added = $0 { String(localized: "Code applied") } else { String(localized: "Code not valid") } } ?? "",
                   item: $promoResult) { _ in
                Button("OK", role: .cancel) {}
            } message: { result in
                switch result {
                case .added(let v): Text("\(money(v)) was added to your Wallet.")
                case .invalid: Text("Check the code and try again.")
                }
            }
        }
        .onAppear { if let initialRoute, path.isEmpty { path = [initialRoute] } }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.increase, trigger: topUps)
    }
}

/// Four circular actions with labels under them.
private struct WalletActions: View {
    let onAddMoney: () -> Void
    let onCards: () -> Void
    let onPromo: () -> Void
    let onHistory: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            action("plus", "Add money", prominent: true, onAddMoney)
            action("creditcard.fill", "Cards", prominent: false, onCards)
            action("gift.fill", "Promo", prominent: false, onPromo)
            action("clock.fill", "History", prominent: false, onHistory)
        }
    }

    private func action(_ symbol: String, _ label: LocalizedStringKey, prominent: Bool,
                        _ run: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Button(action: run) {
                Image(systemName: symbol)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
            }
            // W01: Add money is the white circle; the rest sit on surface/fill.
            .buttonStyle(prominent ? .rentbutik : .glass(.regular.tint(Theme.fill)))
            .buttonBorderShape(.circle)
            Text(label)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
    }
}

/// W01a — amount chips, pay-with row and Add, in place of the actions.
private struct AddMoneyPanel: View {
    @Binding var amount: Decimal
    let paymentLabel: String
    let onBack: () -> Void
    let onPayWith: () -> Void
    let onAdd: () -> Void

    private let presets: [Decimal] = [20, 50, 200, 500]
    @State private var askOther = false
    @State private var otherText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").foregroundStyle(Theme.goldText)
                    Text("Add money").foregroundStyle(Theme.ink)
                }
                .font(Theme.Font.headline)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { value in
                    RentbutikChip(LocalizedStringKey(money(value)), isSelected: amount == value, style: .tint) {
                        amount = value
                    }
                }
                RentbutikChip("Other", isSelected: !presets.contains(amount), style: .tint) { askOther = true }
            }

            Button(action: onPayWith) {
                HStack {
                    Text("Pay with").foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(verbatim: paymentLabel).foregroundStyle(Theme.ink)
                    Image(systemName: "chevron.right")
                        .font(Theme.Font.footnote)
                        .foregroundStyle(Theme.inkFaint)
                }
                .font(Theme.Font.body)
                .padding(.horizontal, 16)
                .frame(minHeight: Theme.Size.groupedRow)
                .glassCard(Theme.Radius.group)
            }
            .buttonStyle(.plain)

            RentbutikPrimaryButton("Add \(money(amount))", haptic: .gain, action: onAdd)
        }
        .alert("Other amount", isPresented: $askOther) {
            TextField("Amount in ₼", text: $otherText)
                .keyboardType(.decimalPad)
            Button("Use amount") {
                if let v = Decimal(string: otherText.replacingOccurrences(of: ",", with: ".")), v >= 5, v <= 2000 {
                    amount = v
                }
                otherText = ""
            }
            Button("Cancel", role: .cancel) { otherText = "" }
        } message: {
            Text("Between ₼5 and ₼2,000.")
        }
    }
}

// MARK: - W02 · Payment methods

private struct PaymentMethodsScreen: View {
    let store: Store
    let onAddCard: () -> Void
    private var selected: String { WalletCatalog.methods.first { $0.title == store.defaultCard }?.id ?? "visa" }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                GroupedCard {
                    ForEach(WalletCatalog.methods.filter { ["visa", "mc"].contains($0.id) }) { method in
                        Button {
                            guard AppConfiguration.isDemo else { return }
                            store.defaultCard = method.title
                            store.cardDeclines = false
                            store.saveSnapshot()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: method.symbol)
                                    .font(Theme.Font.subheadlineSemibold)
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 32, height: 32)
                                    .background(Theme.fill, in: .circle)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(method.title)
                                        .font(Theme.Font.headline)
                                        .foregroundStyle(Theme.ink)
                                    Text(method.detail)
                                        .font(Theme.Font.footnoteRegular)
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                if selected == method.id {
                                    Image(systemName: "checkmark")
                                        .font(Theme.Font.headline)
                                        .foregroundStyle(Theme.goldText)
                                }
                            }
                            .padding(.vertical, 8)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("payment.method.\(method.id)")
                    }
                }
                Text("Demo cards only. Real card setup requires a connected payment service.")
                    .font(Theme.Font.footnoteRegular).foregroundStyle(Theme.inkSoft)
                Text("Select a demo card for your next payment.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Theme.Space.screen)
        }
        .background(Theme.background)
        .navigationTitle("Payment methods")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: selected)
    }
}

// MARK: - W02a · Add card

private struct AddCardScreen: View {
    let onSaved: () -> Void
    @State private var number = ""
    @State private var expiry = ""
    @State private var cvc = ""

    private var isValid: Bool {
        number.filter(\.isNumber).count >= 15 && expiry.count >= 4 && cvc.count >= 3
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.brandSolid)
                Text("Visa, Mastercard or a local card")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)

                GroupedCard {
                    field("Card number", "•••• •••• •••• ••••", $number, .numberPad, .creditCardNumber)
                    field("Expiry", "MM/YY", $expiry, .numberPad, .creditCardExpiration)
                    field("Security code", "CVC", $cvc, .numberPad, .creditCardSecurityCode, last: true)
                }

                RentbutikPrimaryButton("Save card", haptic: .click, action: onSaved)
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
            }
            .padding(.horizontal, Theme.Space.screen)
        }
        .background(Theme.background)
        .navigationTitle("Add card")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func field(_ label: LocalizedStringKey, _ placeholder: LocalizedStringKey,
                       _ text: Binding<String>, _ keyboard: UIKeyboardType,
                       _ content: UITextContentType, last: Bool = false) -> some View {
        GroupedRow(label: label, labelColor: Theme.inkSoft, showsDivider: !last) {
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)
                .textContentType(content)
                .font(Theme.Font.body)
        }
    }
}

// MARK: - W03 · History

private struct WalletHistoryScreen: View {
    let store: Store
    @State private var filter: WalletActivity.Kind = .all

    /// Newest first — every charge, refund and top-up lands in `store.ledger` (K1).
    private var rows: [WalletActivity] {
        filter == .all ? store.ledger : store.ledger.filter { $0.kind == filter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Filter", selection: $filter) {
                    ForEach(WalletActivity.Kind.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("September")
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)

                GroupedCard {
                    ForEach(rows) { row in
                        HStack(spacing: 12) {
                            Image(systemName: row.symbol)
                                .font(Theme.Font.subheadlineSemibold)
                                .foregroundStyle(Theme.ink)
                                .frame(width: 32, height: 32)
                                .background(Theme.fill, in: .circle)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(row.title).font(Theme.Font.headline).foregroundStyle(Theme.ink)
                                Text(row.detail).font(Theme.Font.footnoteRegular).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            Text(row.amount > 0 ? "+\(money(row.amount, 2))" : "−\(money(-row.amount, 2))")
                                .font(Theme.Font.headline)
                                .foregroundStyle(row.amount > 0 ? Theme.success : Theme.ink)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .animation(Theme.smooth, value: filter)

                Text("Tap a row to see its receipt.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.horizontal, Theme.Space.screen)
        }
        .background(Theme.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: filter)
    }
}

#Preview("W01 · Wallet") {
    WalletSheet(store: .seeded())
}

#Preview("W03 · History") {
    let store = Store.seeded()
    store.charge(12, label: "EV ride", symbol: "bolt.car.fill")
    return NavigationStack { WalletHistoryScreen(store: store) }
}

