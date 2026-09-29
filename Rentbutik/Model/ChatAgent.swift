import Foundation
import FoundationModels

/// The demo "backend" for chats: every counterpart (hosts and Support) is
/// played by Apple's on-device Foundation Model, so conversations answer for
/// real without a server. Nothing leaves the phone.
///
/// When Apple Intelligence is off or the device isn't eligible, a small
/// scripted fallback answers instead, so the app still feels alive.
final class ChatAgent {

    /// Three next-message ideas for the renter, generated on device.
    @Generable
    struct ReplyIdeas {
        @Guide(description: "Three short messages the renter might send next, each 2 to 5 words, no emoji",
               .count(3))
        var replies: [String]
    }

    /// One session per thread keeps each persona's memory of the chat.
    private var sessions: [String: LanguageModelSession] = [:]

    var isModelAvailable: Bool { SystemLanguageModel.default.isAvailable }

    // MARK: Replies

    /// The counterpart's next message, in character.
    func reply(in thread: MessageThread) async -> String {
        guard let last = thread.messages.last(where: \.isFromMe)?.promptText else {
            return fallbackReply(to: "", in: thread)
        }
        guard isModelAvailable else { return fallbackReply(to: last, in: thread) }

        let session = session(for: thread)
        guard !session.isResponding else { return fallbackReply(to: last, in: thread) }
        do {
            let response = try await session.respond(
                to: last,
                options: GenerationOptions(temperature: 0.7, maximumResponseTokens: 90))
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? fallbackReply(to: last, in: thread) : text
        } catch {
            return fallbackReply(to: last, in: thread)
        }
    }

    /// Suggested quick replies for the composer, from the latest messages.
    func suggestions(for thread: MessageThread) async -> [String] {
        let defaults = defaultSuggestions(for: thread)
        guard isModelAvailable else { return defaults }

        let recent = thread.messages.suffix(4)
            .map { ($0.isFromMe ? "Renter: " : "\(thread.counterpartName): ") + $0.promptText }
            .joined(separator: "\n")
        // A fresh single-turn session, so ideas never pollute the persona's memory.
        let session = LanguageModelSession(instructions: """
            You help a person renting a car in Baku reply quickly in a chat with \
            \(thread.counterpartName). Suggest what the renter could send next.
            """)
        do {
            let ideas = try await session.respond(to: recent, generating: ReplyIdeas.self).content
            let cleaned = ideas.replies
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\""))) }
                .filter { !$0.isEmpty && $0.count <= 40 }
            return cleaned.count >= 2 ? Array(cleaned.prefix(3)) : defaults
        } catch {
            return defaults
        }
    }

    /// The first message a new person sends, in their voice.
    func opener(for thread: MessageThread, fallback: String) async -> String {
        await generate(for: thread,
                       prompt: "Write the first message you send this renter to start the chat. Mention your \(thread.vehicle ?? "service").",
                       fallback: fallback)
    }

    /// A natural follow-up the counterpart sends without being asked.
    func followUp(in thread: MessageThread) async -> String {
        await generate(for: thread,
                       prompt: "The renter hasn't replied for a while. Send one short, friendly follow-up.",
                       fallback: thread.isPinned
                           ? "Just checking in — is there anything else we can help with?"
                           : "Just checking in — let me know if you have any questions about the \(thread.vehicle ?? "booking").")
    }

    private func generate(for thread: MessageThread, prompt: String, fallback: String) async -> String {
        guard isModelAvailable else { return fallback }
        let session = session(for: thread)
        guard !session.isResponding else { return fallback }
        do {
            let text = try await session.respond(
                to: prompt, options: GenerationOptions(temperature: 0.8, maximumResponseTokens: 70)).content
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "\"")))
            return text.isEmpty ? fallback : text
        } catch {
            return fallback
        }
    }

    // MARK: Personas

    private func session(for thread: MessageThread) -> LanguageModelSession {
        if let existing = sessions[thread.id] { return existing }
        let session = LanguageModelSession(instructions: persona(for: thread))
        sessions[thread.id] = session
        return session
    }

    private func persona(for thread: MessageThread) -> String {
        let shared = """
            Reply as a chat message: one to three short, friendly sentences, \
            plain text, no emoji, no sign-off. Never invent prices or policies \
            beyond what is stated here. Reply in the language the renter writes in.
            """
        switch thread.id {
        case "thr-support":
            return """
                You are Rentbutik Support, the in-app help team of Rentbutik, a \
                rental app in Baku for cars, electric cars by the minute, golf \
                carts at Sea Breeze and transfers. Facts: EV rides cost ₼1 to \
                unlock plus the tariff, with a ₼5 hold released after the ride. \
                Car rentals carry a ₼100 deposit, refunded after return. Wallet \
                top-ups use Apple Pay or cards. Verification is needed only \
                before the first trip, via MyGov or documents. If you can't \
                solve something, say a teammate will follow up in the chat.
                \(shared)
                """
        case "thr-golf":
            return """
                You are the Sea Breeze Golf desk at the Sea Breeze resort near \
                Nardaran. Golf carts cost ₼16–24 an hour; pick-up is at the desk; \
                carts must stay inside the resort. You are courteous and brief.
                \(shared)
                """
        case "thr-rashad":
            return """
                You are Rashad Karimov, a Rentbutik Transfer driver with a Porsche \
                911 GT3 RS. You run Baku → Sheki on Sunday at 08:00, ₼45 a seat or \
                ₼160 for the whole car. You are punctual and friendly.
                \(shared)
                """
        default:
            let car = thread.vehicle ?? "the car"
            return """
                You are \(thread.counterpartName), a host on Rentbutik in Baku, \
                chatting with a renter about your \(car). Pickup is in Sahil, \
                Baku; the rental is 22–23 Sep, 10:00 to 10:00. You are helpful, \
                punctual and a little warm. You can agree on a meeting time, \
                describe where to meet, and answer questions about the car.
                \(shared)
                """
        }
    }

    // MARK: Fallback (no Apple Intelligence)

    private func fallbackReply(to text: String, in thread: MessageThread) -> String {
        let t = text.lowercased()
        let isSupport = thread.id == "thr-support"
        if t.contains("[the renter sent a photo]") || t.hasPrefix("[photo]") {
            return isSupport ? "Thanks for the photo — we’ve added it to your trip record."
                             : "Got the photo, thanks! Looks good."
        }
        if t.contains("[the renter sent a video]") || t.hasPrefix("[video]") {
            return "Thanks for the video — I’ll take a look now."
        }
        if t.contains("[the renter sent a document") {
            return isSupport ? "Document received. We’ll review it and reply here."
                             : "Thanks, I’ve got the document."
        }
        if t.contains("late") { return "No problem, take your time. I’ll wait at the pickup point." }
        if t.contains("way") { return "Great, see you soon! I’m by the entrance." }
        if t.contains("where") { return "Sahil, Baku — right by the metro exit. I’ll send a pin." }
        if t.contains("refund") || t.contains("deposit") {
            return "Deposits are released after the return check, usually within 3–5 days."
        }
        if t.contains("time") || t.contains(":") { return "That time works for me. See you then!" }
        return isSupport
            ? "Thanks for reaching out — we’re looking into it and will reply here shortly."
            : "Sounds good! Let me know if you need anything before pickup."
    }

    private func defaultSuggestions(for thread: MessageThread) -> [String] {
        thread.id == "thr-support"
            ? ["Where is my refund?", "Change my booking", "Talk to a person"]
            : ["On my way", "Running 5 min late", "Where exactly are you?"]
    }
}

