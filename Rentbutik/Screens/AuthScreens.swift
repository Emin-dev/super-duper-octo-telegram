import SwiftUI
import LocalAuthentication

// MARK: - Flow

/// Section 06 · Sign in — "only at the first trip".
///
/// Presented full screen by the tab shell when a ride needs a verified person
/// (`AppRouter.requireVerified`). Browsing never opens it. Returning people
/// land on A07, everyone else on A01b.
enum AuthStep: Hashable {
    case start           // A02
    case details         // A03 / A03c
    case documents       // A05 · 5 stages in one view
    case checking        // A06 · A06b · A06c · A06d in one view
    case welcomeBack     // A07
}

struct AuthFlow: View {
    let session: Session
    let request: AuthRequest

    @Environment(\.dismiss) private var dismiss
    @State private var path: [AuthStep] = []
    @State private var isCompany = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch request.entry {
                case .firstTrip:
                    AccountTypeScreen(onClose: { dismiss() },
                                      onChoose: { company in
                                          isCompany = company
                                          path.append(.start)
                                      },
                                      onSignIn: { path.append(.welcomeBack) })
                case .returning:
                    WelcomeBackScreen(onClose: { dismiss() }, onSignIn: finishReturning)
                }
            }
            .navigationDestination(for: AuthStep.self) { step in
                switch step {
                case .start:
                    StartScreen(onMyGov: {
                                    // MyGov returns identity AND licence in
                                    // one hop, so it lands straight on A06c.
                                    // MyGov returns the verified name and number.
                                    session.signIn(name: "Emin", phone: "+994 50 123 45 67")
                                    session.completeVerification()
                                    path.append(.checking)
                                },
                                onDocuments: { path.append(.details) })
                case .details:
                    DetailsScreen(isCompany: isCompany) { name, phone in
                        session.signIn(name: name, phone: phone)
                        path.append(.documents)
                    }
                case .documents:
                    CaptureStagesView(heading: "Your documents",
                                      stages: AuthFlow.documentStages,
                                      hint: "Hold still — we capture automatically when it is sharp.",
                                      onCancel: { path.removeLast() },
                                      onDone: {
                                          session.beginVerificationPreview()
                                          path.append(.checking)
                                      })
                        .toolbarVisibility(.hidden, for: .navigationBar)
                case .checking:
                    CheckingScreen(session: session,
                                   heldVehicle: request.heldVehicle,
                                   holdEnds: request.holdEnds,
                                   onRetake: { path.removeLast() },
                                   onContinue: finish)
                case .welcomeBack:
                    WelcomeBackScreen(onClose: nil, onSignIn: finishReturning)
                }
            }
        }
        .tint(Theme.goldText)
    }

    private func finish() {
        let resume = session.canRide ? request.onVerified : {}
        dismiss()
        resume()
    }

    /// A07 is for people who were verified before — "No documents needed".
    private func finishReturning(_ phone: String) {
        session.signIn(name: session.displayName ?? "", phone: phone)
        session.completeVerification()
        finish()
    }
}

// MARK: - Shared layout

/// Logo, Title 1 and a Body line, centred — A01b, A02 and A06 share it.
private struct AuthHero: View {
    var logo = true
    var symbol: String? = nil
    let title: LocalizedStringKey
    var detail: LocalizedStringKey? = nil

    @ScaledMetric private var logoSize: CGFloat = 76
    @ScaledMetric private var symbolSize: CGFloat = 60

    var body: some View {
        VStack(spacing: 10) {
            Group {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: symbolSize * 0.8, weight: .semibold))
                        .foregroundStyle(Theme.brandSolid)
                        .symbolRenderingMode(.hierarchical)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: symbolSize, height: symbolSize)
                } else if logo {
                    Image("rentbutikLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                }
            }
            .padding(.bottom, 14)
            .accessibilityHidden(true)

            Text(title)
                .font(Theme.Font.title1)
                .foregroundStyle(Theme.ink)
                .contentTransition(.opacity)
            if let detail {
                Text(detail)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .multilineTextAlignment(.center)
    }
}

/// Close (✕) in the leading slot — the native glass toolbar button.
private struct CloseToolbar: ToolbarContent {
    let action: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close", systemImage: "xmark", action: action)
                .tint(Theme.ink)
        }
    }
}

/// Full-width glass capsule — the Continue / MyGov / Register buttons.
private struct AuthButton: View {
    let title: LocalizedStringKey
    var symbol: String? = nil
    var isEnabled = true
    let action: () -> Void

    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(Theme.brandSolid)
                        .symbolEffect(.bounce, value: taps)
                }
                Text(title)
            }
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(Theme.snappy, value: isEnabled)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
    }
}

// MARK: - A01b · Personal or company

private struct AccountTypeScreen: View {
    let onClose: () -> Void
    let onChoose: (_ company: Bool) -> Void
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            AuthHero(title: "How will you rent?",
                     detail: "Choose how you will use Rentbutik.")

            VStack(spacing: Theme.Space.gap) {
                AccountTypeRow(symbol: "person.fill", title: "Personal",
                               detail: "Just for me") { onChoose(false) }
                AccountTypeRow(symbol: "building.2.fill", title: "Company",
                               detail: "Invoices with VÖEN") { onChoose(true) }
            }

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(Theme.inkSoft)
                Button("Sign in", action: onSignIn)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.goldText)
            }
            .font(Theme.Font.subheadlineRegular)
        }
        .padding(.horizontal, Theme.Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .toolbar { CloseToolbar(action: onClose) }
    }
}

private struct AccountTypeRow: View {
    let symbol: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let action: () -> Void

    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.goldText)
                    .symbolEffect(.bounce, value: taps)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.capsule)
        .sensoryFeedback(.selection, trigger: taps)
    }
}

// MARK: - A02 · Start

private struct StartScreen: View {
    let onMyGov: () -> Void
    let onDocuments: () -> Void

    @State private var myGovFailed = false
    @State private var connecting = false

    var body: some View {
        VStack(spacing: 28) {
            AuthHero(title: "Verify once, ride anytime",
                     detail: "Needed before your first trip. MyGov does it in one tap.")

            VStack(spacing: 12) {
                AuthButton(title: connecting ? "Connecting to MyGov…" : "Continue with MyGov",
                           symbol: connecting ? nil : "checkmark.seal.fill",
                           isEnabled: !connecting) {
                    // MyGov hands back after its own sign-in — a few seconds.
                    guard AppConfiguration.isDemo else { myGovFailed = true; return }
                    withAnimation(Theme.snappy) { connecting = true }
                    Task {
                        try? await Task.sleep(for: .seconds(Double.random(in: 2.6...3.6)))
                        connecting = false
                        onMyGov()
                    }
                }
                .overlay(alignment: .leading) {
                    if connecting { ProgressView().padding(.leading, 20) }
                }
                AuthButton(title: "Register with documents", action: onDocuments)
            }

            HStack(spacing: 4) {
                Link("Terms of service", destination: URL(string: "https://rentbutik.az/terms")!)
                Text(verbatim: "·")
                Link("Privacy policy", destination: URL(string: "https://rentbutik.az/privacy")!)
            }
            .font(Theme.Font.footnoteRegular)
            .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        // A02's error state: MyGov came back without finishing.
        .alert("MyGov didn’t finish", isPresented: $myGovFailed) {
            Button("Try again") { if AppConfiguration.isDemo { onMyGov() } }
            Button("Register with documents", action: onDocuments)
        } message: {
            Text("Try again, or register with your documents instead.")
        }
    }
}

// MARK: - A03 · Your details  (A03c · Company is the same view)

private struct DetailsScreen: View {
    let isCompany: Bool
    let onContinue: (_ name: String, _ phone: String) -> Void

    private enum Field: Hashable { case name, fin, email, company, voen, phone, code }

    @FocusState private var focus: Field?
    @State private var name = ""
    @State private var birthDate = Calendar.current.date(from: DateComponents(year: 1994, month: 3, day: 14)) ?? .now
    @State private var fin = ""
    @State private var email = ""
    @State private var company = ""
    @State private var voen = ""
    @State private var phone = PhoneCode()

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && fin.count == 7
            && (!isCompany || (!company.isEmpty && voen.count == 10))
            && phone.isComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(isCompany ? "Step 1 of 2 · Company account" : "Step 1 of 2 · About a minute.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.bottom, 16)

                FormSectionTitle(isCompany ? "Account admin" : "Your details")
                GroupedCard {
                    FormRow("Full name") {
                        TextField("As on your ID card", text: $name)
                            .textContentType(.name)
                            .focused($focus, equals: .name)
                    }
                    FormRow("Date of birth") {
                        DatePicker("Date of birth", selection: $birthDate,
                                   in: ...Date.now, displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    FormRow("FIN code") {
                        TextField("7 characters", text: $fin.max(7))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($focus, equals: .fin)
                    }
                    FormRow(isCompany ? "Invoice e-mail" : "Email", divider: isCompany) {
                        TextField(isCompany ? "accounts@company.az" : "name@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .focused($focus, equals: .email)
                    }
                    if isCompany {
                        FormRow("Company") {
                            TextField("As registered", text: $company)
                                .textContentType(.organizationName)
                                .focused($focus, equals: .company)
                        }
                        FormRow("VÖEN", divider: false) {
                            TextField("10-digit tax ID", text: $voen.digits(10))
                                .keyboardType(.numberPad)
                                .focused($focus, equals: .voen)
                        }
                    }
                }
                .padding(.bottom, 20)

                PhoneCodeSection(value: $phone, focus: $focus, phoneField: .phone, codeField: .code)
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Your details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            AuthButton(title: "Continue", isEnabled: canContinue) {
                onContinue(name, "+994 \(phone.number)")
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 8)
        }
    }
}

/// Footnote / Semibold, uppercase, above a grouped card.
private struct FormSectionTitle: View {
    let title: LocalizedStringKey
    init(_ title: LocalizedStringKey) { self.title = title }
    var body: some View {
        Text(title)
            .textCase(.uppercase)
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.inkSoft)
            .padding(.leading, 2)
            .padding(.bottom, 8)
    }
}

/// Label column + field, one row of a grouped card.
private struct FormRow<Field: View>: View {
    let label: LocalizedStringKey
    var divider = true
    @ViewBuilder let field: Field

    @ScaledMetric private var labelWidth: CGFloat = 117

    init(_ label: LocalizedStringKey, divider: Bool = true, @ViewBuilder field: () -> Field) {
        self.label = label
        self.divider = divider
        self.field = field()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(label)
                    .foregroundStyle(Theme.ink)
                    .frame(width: labelWidth, alignment: .leading)
                field
                    .foregroundStyle(Theme.ink)
            }
            .font(Theme.Font.body)
            .frame(minHeight: 48)
            if divider { Divider().overlay(Theme.hairline) }
        }
    }
}

/// Phone + one-time code, shared by A03 and A07.
private struct PhoneCode {
    var number = ""
    var code = ""
    var sentAt: Date?
    var isComplete: Bool { number.count >= 9 && code.count == 6 }
}

private struct PhoneCodeSection<Focus: Hashable>: View {
    @Binding var value: PhoneCode
    var focus: FocusState<Focus?>.Binding
    let phoneField: Focus
    let codeField: Focus

    @State private var sends = 0
    /// Seconds until Resend is allowed again.
    @State private var cooldown = 0

    private var sendLabel: String {
        if cooldown > 0 { return String(localized: "Resend in \(cooldown)s") }
        return value.sentAt == nil ? String(localized: "Send code") : String(localized: "Resend")
    }

    /// The SMS "arrives" ~3 s later as a real banner and fills itself in —
    /// the same feel as iOS one-time-code AutoFill.
    private func sendCode(via channel: String) {
        guard AppConfiguration.isDemo else { return }
        sends += 1
        value.sentAt = .now
        focus.wrappedValue = codeField
        let code = String(format: "%06d", Int.random(in: 100_000...999_999))
        Task {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.5...3.5)))
            LocalNotifier.shared.post(title: channel,
                                      body: String(localized: "Your Rentbutik code is \(code). Don’t share it with anyone."),
                                      thread: "otp")
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation(Theme.snappy) { value.code = code }
        }
        Task {
            cooldown = 30
            while cooldown > 0 {
                try? await Task.sleep(for: .seconds(1))
                cooldown -= 1
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormSectionTitle("Phone number")
            GroupedCard {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text(verbatim: "+994")
                            .foregroundStyle(Theme.ink)
                        TextField("50 123 45 67", text: $value.number.digits(9))
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .focused(focus, equals: phoneField)
                        Button(sendLabel) { sendCode(via: String(localized: "SMS")) }
                        .font(Theme.Font.subheadlineSemibold)
                        .foregroundStyle(Theme.ink)
                        .buttonStyle(.glass(.regular.tint(Theme.brandTint)))
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                        .disabled(value.number.count < 9 || cooldown > 0)
                        .opacity(value.number.count < 9 || cooldown > 0 ? 0.45 : 1)
                        .contentTransition(.numericText())
                        .sensoryFeedback(.success, trigger: sends)
                    }
                    .font(Theme.Font.body)
                    .frame(minHeight: 48)
                    Divider().overlay(Theme.hairline)
                }
                FormRow("Code", divider: false) {
                    TextField("6-digit code", text: $value.code.digits(6))
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused(focus, equals: codeField)
                }
            }
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("We send a 6-digit code by SMS. There is no password.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
                Button("Get the code on WhatsApp instead") { sendCode(via: "WhatsApp") }
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.goldText)
                .disabled(value.number.count < 9)
                .opacity(value.number.count < 9 ? 0.45 : 1)
                Text("By continuing you accept the Terms of service and Privacy policy.")
                    .font(Theme.Font.footnoteRegular)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.horizontal, 2)
        }
    }
}

private extension Binding where Value == String {
    /// Keeps at most `limit` characters.
    func max(_ limit: Int) -> Binding<String> {
        Binding(get: { wrappedValue },
                set: { wrappedValue = String($0.prefix(limit)) })
    }
    /// Keeps digits only, at most `limit` of them.
    func digits(_ limit: Int) -> Binding<String> {
        Binding(get: { wrappedValue },
                set: { wrappedValue = String($0.filter(\.isNumber).prefix(limit)) })
    }
}

// MARK: - A05 · Document camera  (five stages — the shared capture view)

extension AuthFlow {
    static let documentStages: [CaptureStage] = [
        .init(id: "id-front", title: "ID card · front", detail: "1 of 5 · Front side", short: "Tap to scan", symbol: "person.text.rectangle.fill"),
        .init(id: "id-back", title: "ID card · back", detail: "2 of 5 · Back side", short: "Tap to scan", symbol: "list.bullet.rectangle.fill"),
        .init(id: "lic-front", title: "Driving licence · front", detail: "3 of 5 · Front side", short: "Tap to scan", symbol: "person.crop.rectangle.fill"),
        .init(id: "lic-back", title: "Driving licence · back", detail: "4 of 5 · Back side", short: "Tap to scan", symbol: "menucard.fill"),
        .init(id: "selfie", title: "Selfie with your ID", detail: "5 of 5 · ID next to your face", short: "Tap to scan", symbol: "person.crop.circle.fill", aspect: 0.8),
    ]
}

// MARK: - A06 · Checking  (A06b rejected · A06c verified · A06d Face ID)

private struct CheckingScreen: View {
    let session: Session
    let heldVehicle: String?
    let holdEnds: Date
    let onRetake: () -> Void
    let onContinue: () -> Void

    enum Stage { case checking, rejected, verified }

    @State private var stage: Stage = .checking
    @State private var askFaceID = false
    @State private var verifiedTick = 0

    var body: some View {
        VStack(spacing: 20) {
            switch stage {
            case .checking:
                AuthHero(symbol: "clock.fill", title: "Checking your documents",
                         detail: "Usually a few minutes. We’ll notify you the moment you’re verified.")
            case .rejected:
                AuthHero(symbol: "exclamationmark.triangle.fill", title: "Licence photo is blurry",
                         detail: "Retake the back of your driving licence. Everything else is fine.")
            case .verified:
                AuthHero(symbol: "checkmark.seal.fill", title: "You’re verified")
            }

            if let heldVehicle {
                HoldPill(vehicle: heldVehicle, until: holdEnds)
            }

            switch stage {
            case .checking: AuthButton(title: "Continue", action: onContinue)
            case .rejected: AuthButton(title: "Retake photo", action: onRetake)
            case .verified: AuthButton(title: "Continue to your trip", action: onContinue)
            }
        }
        .padding(.horizontal, Theme.Space.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationBarBackButtonHidden()
        .animation(Theme.smooth, value: stage)
        .sensoryFeedback(.success, trigger: verifiedTick)
        .task {
            if session.canRide {
                markVerified()
                return
            }
            // No backend yet: the document check resolves on-device after a
            // short wait, the way the review service will answer.
            guard (try? await Task.sleep(for: .seconds(2.5))) != nil else { return }
            session.receivePreviewApproval()
            session.completeVerification()
            markVerified()
        }
        // A06d — offered once, right after verifying.
        .alert("Use Face ID next time?", isPresented: $askFaceID) {
            Button("Use Face ID") { Task { await enableFaceID() } }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Sign in with a glance instead of a code.")
        }
    }

    private func markVerified() {
        stage = .verified
        verifiedTick += 1
        askFaceID = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    private func enableFaceID() async {
        _ = try? await LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                  localizedReason: String(localized: "Sign in with a glance instead of a code."))
    }
}

/// "Porsche 911 GT3 RS held for you · 29:41" — brand/tint capsule, live countdown.
private struct HoldPill: View {
    let vehicle: String
    let until: Date

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .foregroundStyle(Theme.goldText)
            Text("\(vehicle) held for you · \(Text(timerInterval: Date.now...max(until, .now), countsDown: true))")
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(Theme.Font.subheadlineSemibold)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.brandTint, in: .capsule)
    }
}

// MARK: - A07 · Welcome back

private struct WelcomeBackScreen: View {
    let onClose: (() -> Void)?
    let onSignIn: (_ phone: String) -> Void

    private enum Field: Hashable { case phone, code }
    @FocusState private var focus: Field?
    @State private var phone = PhoneCode()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Sign in with your phone number. No documents needed.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.bottom, 20)
                PhoneCodeSection(value: $phone, focus: $focus, phoneField: .phone, codeField: .code)
            }
            .padding(.horizontal, Theme.Space.screen)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Welcome back")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onClose { CloseToolbar(action: onClose) }
        }
        .safeAreaInset(edge: .bottom) {
            AuthButton(title: "Sign in", isEnabled: phone.isComplete) {
                onSignIn("+994 \(phone.number)")
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, 8)
        }
        .onAppear { focus = .phone }
    }
}

// MARK: - Previews

#Preview("A01b · Personal or company") {
    AuthFlow(session: Session(), request: AuthRequest(heldVehicle: "Porsche 911 GT3 RS"))
}

#Preview("A03 · Your details") {
    NavigationStack { DetailsScreen(isCompany: false) { _, _ in } }
}

#Preview("A03c · Company details") {
    NavigationStack { DetailsScreen(isCompany: true) { _, _ in } }
}

#Preview("A05 · Document camera") {
    CaptureStagesView(heading: "Your documents", stages: AuthFlow.documentStages,
                      hint: "Hold still — we capture automatically when it is sharp.",
                      onCancel: {}, onDone: {})
}

#Preview("A06 · Checking") {
    NavigationStack {
        CheckingScreen(session: Session(), heldVehicle: "Porsche 911 GT3 RS",
                       holdEnds: .now.addingTimeInterval(29 * 60 + 41),
                       onRetake: {}, onContinue: {})
    }
}

#Preview("A07 · Welcome back") {
    NavigationStack { WelcomeBackScreen(onClose: {}, onSignIn: { _ in }) }
}

