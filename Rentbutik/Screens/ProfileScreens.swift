import SwiftUI

// MARK: - P01 · Profile

/// Tab root: eight equal tiles (176 × 120), each opening a sheet, a native
/// menu, or — for Hosting — a push. Measured from Design-flow `26:52`.
struct ProfileScreen: View {
    let store: Store
    let session: Session
    let router: AppRouter

    @State private var language: AppLanguage = .english
    @State private var appearance: AppAppearance = .system
    @State private var notifications: Set<NotificationChannel> = [.push, .tripUpdates]
    @State private var sheet: ProfileSheet?
    @State private var alert: ProfileAlert?

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Space.gap),
        GridItem(.flexible(), spacing: Theme.Space.gap),
    ]

    private var notificationSummary: String {
        let order: [NotificationChannel] = [.push, .tripUpdates, .email]
        let names = order.filter(notifications.contains).map(\.short)
        return names.isEmpty ? String(localized: "Off") : names.joined(separator: " · ")
    }

    var body: some View {
        ScrollView {
            // Same title block as Trips and Chats: Large Title at y 100,
            // content 12 pt below — P01.
            Text("Profile")
                .font(Theme.Font.largeTitle)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Space.screen)
                .padding(.top, Theme.Space.gap)
                .padding(.bottom, 12)
            LazyVGrid(columns: columns, spacing: 12) {
                ProfileTile(symbol: "person.fill",
                            title: session.hasAccount
                                ? (session.displayName.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "Account"))
                                : String(localized: "Sign in"),
                            value: session.canRide ? String(localized: "Verified · MyGov")
                                                   : String(localized: "Book faster with an account")) {
                    if session.hasAccount { sheet = .account } else { router.auth = AuthRequest() }
                }
                ProfileTile(symbol: "gift.fill", title: String(localized: "Invite friends"),
                            value: "Get \(money(10)) each") { sheet = .invite }

                // P02–P04 are native menus anchored to the tile.
                Menu {
                    Picker("Language", selection: $language) {
                        ForEach(AppLanguage.allCases) { $0.label.tag($0) }
                    }
                } label: {
                    ProfileTileLabel(symbol: "globe.europe.africa.fill",
                                     title: String(localized: "Language"),
                                     value: String(localized: language.resource))
                }
                .sensoryFeedback(.selection, trigger: language)

                Menu {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { $0.label.tag($0) }
                    }
                } label: {
                    ProfileTileLabel(symbol: "circle.lefthalf.filled",
                                     title: String(localized: "Appearance"),
                                     value: String(localized: appearance.resource))
                }
                .sensoryFeedback(.selection, trigger: appearance)

                Menu {
                    ForEach(NotificationChannel.allCases) { channel in
                        Toggle(isOn: Binding(
                            get: { notifications.contains(channel) },
                            set: { on in
                                if on { notifications.insert(channel) } else { notifications.remove(channel) }
                            })) { Text(channel.label) }
                    }
                } label: {
                    ProfileTileLabel(symbol: "bell.fill",
                                     title: String(localized: "Notifications"),
                                     value: notificationSummary)
                }
                .menuActionDismissBehavior(.disabled)   // multi-select stays open

                ProfileTile(symbol: "questionmark.circle.fill", title: String(localized: "Help"),
                            value: String(localized: "We answer fast")) { sheet = .help }

                ProfileTile(symbol: "wallet.bifold.fill", title: String(localized: "Wallet"),
                            value: store.walletBalance.formatted(
                                .currency(code: Currency.code).precision(.fractionLength(2)))) {
                    sheet = .wallet
                }
                .accessibilityIdentifier("profile.wallet")
                ProfileTile(symbol: "key.fill", title: String(localized: "Hosting"),
                            value: String(localized: "Earn with your car")) {
                    router.push(.becomeHost)
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .background(Theme.background)
        .navigationTitle("Profile")
        .toolbarVisibility(.hidden, for: .navigationBar)
        .preferredColorScheme(appearance.scheme)
        .sheet(item: $sheet) { which in
            switch which {
            case .account: AccountSheet(session: session).fittedSheet()
            case .invite:  InviteSheet().fittedSheet()
            case .help:
                HelpSheet(hasAccount: session.hasAccount,
                          onAlert: { alert = $0 },
                          onSupport: { router.tab = .chats; router.push(.thread(threadID: "thr-support")) })
                    .fittedSheet()
            case .wallet:  WalletSheet(store: store)
            }
        }
        // P06 / P07 — native alerts.
        .alert(alert?.title ?? "", item: $alert) { which in
            Button(which.confirm, role: .destructive) {
                if which == .signOut { session.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: { which in
            Text(which.message)
        }
    }

    private func money(_ v: Decimal) -> String {
        v.formatted(.currency(code: Currency.code).precision(.fractionLength(0)))
    }
}

enum ProfileSheet: String, Identifiable {
    case account, invite, help, wallet
    var id: String { rawValue }
}

enum ProfileAlert: Hashable {
    case signOut, deleteAccount
    var title: LocalizedStringKey { self == .signOut ? "Sign out?" : "Delete account?" }
    var confirm: LocalizedStringKey { self == .signOut ? "Sign out" : "Delete" }
    var message: LocalizedStringKey {
        self == .signOut
            ? "You can sign in again with MyGov or your phone number."
            : "Deleting your account is permanent. Finish active trips and settle payments first."
    }
}

// MARK: - Tile

/// Profile tile — 176 × 120, radius 26, 44 pt circle badge, Headline title,
/// Subheadline value in text/secondary. Glass, per Emin's decision.
private struct ProfileTileLabel: View {
    let symbol: String
    let title: String
    let value: String

    @ScaledMetric private var height: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RentbutikBadge(symbol: symbol, size: .tile)
                .padding(.bottom, 10)
            Text(title)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(value)
                .font(Theme.Font.subheadlineRegular)
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 2)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: height, alignment: .topLeading)
        .glassCard(Theme.Radius.tile)
        .contentShape(.rect(cornerRadius: Theme.Radius.tile))
    }
}

private struct ProfileTile: View {
    let symbol: String
    let title: String
    let value: String
    let action: () -> Void

    @State private var taps = 0

    var body: some View {
        Button { taps += 1; action() } label: {
            ProfileTileLabel(symbol: symbol, title: title, value: value)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: taps)
    }
}

// MARK: - Settings enums

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, azerbaijani, russian, english
    var id: String { rawValue }
    var resource: LocalizedStringResource {
        switch self {
        case .system:      "System"
        case .azerbaijani: "Azərbaycan"
        case .russian:     "Русский"
        case .english:     "English"
        }
    }
    var label: Text { Text(resource) }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var resource: LocalizedStringResource {
        switch self {
        case .system: "System"
        case .light:  "Light"
        case .dark:   "Dark"
        }
    }
    var label: Text { Text(resource) }
    var scheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

enum NotificationChannel: String, CaseIterable, Identifiable {
    case push, tripUpdates, email
    var id: String { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .push:        "Push notifications"
        case .tripUpdates: "Trip updates"
        case .email:       "Email"
        }
    }
    var short: String {
        switch self {
        case .push:        String(localized: "Push")
        case .tripUpdates: String(localized: "Trip updates")
        case .email:       String(localized: "Email")
        }
    }
}

// MARK: - Grouped rows (List / Grouped)

/// A white group card, radius 22, 46 pt rows with inset separators.
struct GroupedCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 16)
            .glassCard(Theme.Radius.group)
    }
}

struct GroupedRow<Trailing: View>: View {
    var symbol: String? = nil
    var tint: Color = Theme.goldText
    let label: LocalizedStringKey
    var labelColor: Color = Theme.ink
    var showsDivider = true
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(Theme.Font.body)
                        .foregroundStyle(tint)
                        .frame(width: 24)
                }
                Text(label)
                    .font(Theme.Font.body)
                    .foregroundStyle(labelColor)
                Spacer(minLength: 8)
                trailing
            }
            .frame(minHeight: Theme.Size.groupedRow)
            if showsDivider { Divider().overlay(Theme.hairline) }
        }
    }
}

extension GroupedRow where Trailing == EmptyView {
    init(symbol: String? = nil, tint: Color = Theme.goldText, label: LocalizedStringKey,
         labelColor: Color = Theme.ink, showsDivider: Bool = true) {
        self.symbol = symbol; self.tint = tint; self.label = label
        self.labelColor = labelColor; self.showsDivider = showsDivider
        self.trailing = EmptyView()
    }
}

private struct SheetFootnote: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .font(Theme.Font.footnoteRegular)
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

// MARK: - P09 · Account

private struct AccountSheet: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss

    @State private var addingEmail = false
    @State private var emailDraft = ""

    var body: some View {
        VStack(spacing: 14) {
            SheetHeader(title: "Account") { dismiss() }
            GroupedCard {
                GroupedRow(label: "Name") { Text(session.displayName ?? "—").foregroundStyle(Theme.inkSoft) }
                GroupedRow(label: "Phone") { Text(session.phoneNumber ?? "—").foregroundStyle(Theme.inkSoft) }
                GroupedRow(label: "Email", showsDivider: false) {
                    if let email = session.email {
                        Text(email).foregroundStyle(Theme.inkSoft)
                    } else {
                        Button("Add") { addingEmail = true }.foregroundStyle(Theme.goldText)
                    }
                }
            }
            GroupedCard {
                verifiedRow("MyGov", "Verified")
                verifiedRow("Driving licence", "Valid until 2031")
                verifiedRow("ID card", "Verified", last: true)
            }
            SheetFootnote(text: "Your name and documents come from MyGov. To change them, update them in MyGov.")
        }
        .font(Theme.Font.body)
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, Theme.Space.noTabBarClearance)
        .alert("Add email", isPresented: $addingEmail) {
            TextField("name@example.com", text: $emailDraft)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
            Button("Save") {
                let value = emailDraft.trimmingCharacters(in: .whitespaces)
                if value.contains("@") { withAnimation(Theme.smooth) { session.email = value } }
                emailDraft = ""
            }
            Button("Cancel", role: .cancel) { emailDraft = "" }
        } message: {
            Text("Receipts and trip updates go here.")
        }
    }

    private func verifiedRow(_ label: LocalizedStringKey, _ value: LocalizedStringKey, last: Bool = false) -> some View {
        GroupedRow(label: label, showsDivider: !last) {
            HStack(spacing: 6) {
                Text(value)
                Image(systemName: "checkmark.seal.fill")
            }
            .foregroundStyle(Theme.success)
        }
    }
}

// MARK: - P08 · Invite friends

private struct InviteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = 0

    private let code = "EMIN10"

    var body: some View {
        VStack(spacing: 14) {
            SheetHeader(title: "Invite friends") { dismiss() }
            GroupedCard {
                GroupedRow(label: "Your code") {
                    HStack(spacing: 12) {
                        Text(verbatim: code).foregroundStyle(Theme.inkSoft)
                        Button("Copy") {
                            UIPasteboard.general.string = code
                            copied += 1
                        }
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.goldText)
                    }
                }
                GroupedRow(label: "Friends joined") { Text(verbatim: "2").foregroundStyle(Theme.inkSoft) }
                GroupedRow(label: "You earned", showsDivider: false) {
                    Text(Decimal(20), format: .currency(code: Currency.code).precision(.fractionLength(0)))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            ShareLink(item: URL(string: "https://rentbutik.az/invite/\(code)")!) {
                Text("Share invite link")
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.rentbutik)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            SheetFootnote(text: "Friends get ₼10 off their first trip. You get ₼10 in your Wallet when it ends.")
        }
        .font(Theme.Font.body)
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, Theme.Space.noTabBarClearance)
        .sensoryFeedback(.success, trigger: copied)
    }
}

// MARK: - P05 · Help

private struct HelpSheet: View {
    let hasAccount: Bool
    let onAlert: (ProfileAlert) -> Void
    var onSupport: () -> Void = {}
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            SheetHeader(title: "Help") { dismiss() }
            GroupedCard {
                chevronRow("message.fill", "Message support") { dismiss(); onSupport() }
                chevronRow("envelope.fill", "Email us") {
                    if let url = URL(string: "mailto:help@rentbutik.az?subject=Rentbutik%20help") { openURL(url) }
                }
                chevronRow("doc.text.fill", "Privacy policy", last: true) {
                    if let url = URL(string: "https://rentbutik.az/privacy") { openURL(url) }
                }
            }
            if hasAccount {
            GroupedCard {
                Button { dismiss(); onAlert(.signOut) } label: {
                    GroupedRow(symbol: "rectangle.portrait.and.arrow.right", tint: Theme.danger,
                               label: "Sign out", labelColor: Theme.danger)
                }
                Button { dismiss(); onAlert(.deleteAccount) } label: {
                    GroupedRow(symbol: "trash.fill", tint: Theme.danger,
                               label: "Delete account", labelColor: Theme.danger, showsDivider: false)
                }
            }
            .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, Theme.Space.noTabBarClearance)
    }

    private func chevronRow(_ symbol: String, _ label: LocalizedStringKey, last: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GroupedRow(symbol: symbol, label: label, showsDivider: !last) {
                Image(systemName: "chevron.right")
                    .font(Theme.Font.footnote)
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("P01 · Profile") {
    NavigationStack {
        ProfileScreen(store: .seeded(), session: .emin(), router: AppRouter())
    }
}

