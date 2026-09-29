import Foundation

/// Drives the browse-first gate — RULE K.
///
/// 1. The app opens straight to Home. No wall. Anyone can browse and see prices.
/// 2. An account is created at the first meaningful action (favourite, chat, booking).
/// 3. Identity verification is required before the FIRST RIDE, not before browsing.
///
/// Pricing is the hook, so nothing may block it.
@Observable
final class Session {

    enum State: Equatable {
        /// Browsing without an account. The default on launch.
        case guest
        /// Signed in, identity not yet verified. Can browse and chat, cannot ride.
        case signedIn
        /// MyGov or the 4-step custom path completed. Can ride.
        case verified
    }

    /// Frontend-visible verification progress. This is deliberately separate
    /// from `State.verified`: a local preview, a submitted document or an
    /// incoming UI callback must never unlock a real ride.
    enum VerificationProgress: Equatable {
        case notStarted
        case pending
        case previewApproved
        case rejected
    }

    var state: State = .guest
    var displayName: String?
    var phoneNumber: String?
    var email: String?
    var verificationProgress: VerificationProgress = .notStarted

    /// What gates a booking. Browsing never checks this.
    var canRide: Bool { state == .verified }

    /// What gates chat and favourites.
    var hasAccount: Bool { state != .guest }

    init(state: State = .guest) {
        self.state = state
    }

    // MARK: - Transitions

    func signIn(name: String, phone: String) {
        displayName = name
        phoneNumber = phone
        // Signing in is not the same as being verified — identity is checked
        // before the first ride, not before browsing (RULE K).
        state = .signedIn
    }

    func beginVerificationPreview() {
        guard state != .guest else { return }
        verificationProgress = .pending
    }

    func receivePreviewApproval() {
        guard state != .guest else { return }
        verificationProgress = .previewApproved
    }

    func receivePreviewRejection() {
        guard state != .guest else { return }
        verificationProgress = .rejected
    }

    /// MyGov returns identity AND licence, so that path verifies in one step.
    func completeVerification() {
        guard AppConfiguration.isDemo else { return }
        state = .verified
    }

    func signOut() {
        state = .guest
        displayName = nil
        phoneNumber = nil
        email = nil
        verificationProgress = .notStarted
    }

    /// Development convenience: a verified account, so screens that come after
    /// the gate can be built and looked at before Phase 4 exists.
    static func emin() -> Session {
        let session = Session(state: .verified)
        session.displayName = "Emin"
        session.phoneNumber = "+994 50 123 45 67"
        return session
    }
}

