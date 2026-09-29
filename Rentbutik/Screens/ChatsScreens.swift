import SwiftUI

// MARK: - C01 · Chats

/// Tab root: large title, native search, Pinned (Support) and Recent.
struct ChatsScreen: View {
    let store: Store
    let router: AppRouter

    @State private var query = ""

    private var filtered: [MessageThread] {
        guard !query.isEmpty else { return store.threads }
        return store.threads.filter {
            $0.counterpartName.localizedCaseInsensitiveContains(query)
                || ($0.vehicle ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let pinned = filtered.filter(\.isPinned)
                // Newest conversation first, as in Messages.
                let recent = filtered.filter { !$0.isPinned }
                    .sorted { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }

                // Large title + white search capsule, drawn as C01 draws them.
                // (iOS 27 folds a large title into the bar once a search
                // drawer is attached, so the title is ours, like Trips.)
                Text("Chats")
                    .font(Theme.Font.largeTitle)
                    .foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Space.gap)
                    .padding(.bottom, 12)
                ChatsSearchField(query: $query)
                    .padding(.bottom, 16)

                if !pinned.isEmpty {
                    ChatsSectionTitle("Pinned")
                    ChatRows(threads: pinned)
                        .padding(.bottom, 20)
                }
                if !recent.isEmpty {
                    ChatsSectionTitle("Recent")
                    ChatRows(threads: recent)
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .background(Theme.background)
        .navigationTitle("Chats")
        .toolbarVisibility(.hidden, for: .navigationBar)
        .scrollDismissesKeyboard(.immediately)
    }
}

/// C01's search: white capsule, magnifier, Body placeholder.
private struct ChatsSearchField: View {
    @Binding var query: String
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.inkSoft)
            TextField("Search", text: $query)
                .focused($focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") { query = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Theme.inkSoft)
                    .transition(.opacity)
            }
        }
        .font(Theme.Font.body)
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(Theme.card, in: .capsule)
        .contentShape(.capsule)
        .onTapGesture { focused = true }
        .animation(Theme.snappy, value: query.isEmpty)
    }
}

private struct ChatsSectionTitle: View {
    let title: LocalizedStringKey
    init(_ title: LocalizedStringKey) { self.title = title }
    var body: some View {
        Text(title)
            .font(Theme.Font.title3)
            .foregroundStyle(Theme.ink)
            .padding(.top, 8)
            .padding(.bottom, 12)
    }
}

private struct ChatRows: View {
    let threads: [MessageThread]

    var body: some View {
        VStack(spacing: Theme.Space.gap) {
            ForEach(threads) { thread in
                NavigationLink(value: Route.thread(threadID: thread.id)) {
                    ChatRow(thread: thread)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Avatar, name + time, one-line preview, then the vehicle line (or the
/// Support subtitle). Unread shows a brand/solid count badge.
private struct ChatRow: View {
    let thread: MessageThread

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ChatAvatar(thread: thread, size: 52)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(thread.counterpartName)
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if let last = thread.messages.last?.sentAt {
                        Text(ChatRow.time(last))
                            .font(Theme.Font.subheadlineRegular)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    if thread.unreadCount > 0 {
                        Text("\(thread.unreadCount)")
                            .font(Theme.Font.captionSemibold)
                            .foregroundStyle(Theme.onGold)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Theme.brandSolid, in: .circle)
                    }
                }
                Text(thread.messages.last?.text ?? "")
                    .font(Theme.Font.subheadlineRegular)
                    .foregroundStyle(thread.unreadCount > 0 ? Theme.ink : Theme.inkSoft)
                    .lineLimit(1)
                if let vehicle = thread.vehicle {
                    Label(vehicle, systemImage: "car.side.fill")
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Text(thread.subtitle)
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(Theme.Radius.card)
        .contentShape(.rect)
    }

    /// "09:41" today, "Yesterday", otherwise a short date — all locale-aware.
    static func time(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return date.formatted(.dateTime.hour().minute()) }
        if cal.isDateInYesterday(date) {
            return date.formatted(.relative(presentation: .named)).capitalized
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

/// Initials on brand/tint; Support uses the real Rentbutik mark.
struct ChatAvatar: View {
    let thread: MessageThread
    let size: CGFloat

    var body: some View {
        Group {
            if thread.isPinned {
                Image("rentbutikLogo")
                    .resizable()
                    .scaledToFill()
            } else {
                Text(thread.initials)
                    .font(Theme.Font.title3)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.brandTint)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

// MARK: - C02 · Thread  (C03 Support uses the same view)

/// Title + native subtitle, a ⋯ menu (C02a · Report · Block), the booking the
/// chat is about, bubbles, quick replies and the composer.
/// The tab bar stays visible here too — Emin wants it on every screen.
struct ThreadScreen: View {
    let thread: MessageThread
    let store: Store

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var confirm: ChatSafetyAction?

    private var live: MessageThread {
        store.threads.first { $0.id == thread.id } ?? thread
    }

    var body: some View {
        VStack(spacing: 0) {
            if let vehicle = live.vehicle {
                BookingContextCard(vehicle: vehicle)
                    .padding(.horizontal, Theme.Space.screen)
                    .padding(.top, 6)
            }

            ThreadMessages(thread: live, isTyping: store.typingThreadIDs.contains(thread.id))
                .onAppear {
                    store.viewingThreadID = thread.id
                    store.markRead(thread.id)
                }
                .onDisappear {
                    if store.viewingThreadID == thread.id { store.viewingThreadID = nil }
                }
                .task { await store.refreshSuggestions(for: thread.id) }

            QuickReplies(replies: store.suggestions[thread.id]
                            ?? ["On my way", "Running 5 min late", "Where exactly are you?"],
                         isAI: store.agent.isModelAvailable) { send($0) }
            MessageComposer(draft: $draft,
                            onAttach: { store.send($0, in: thread.id) },
                            onSend: { send(draft) })
        }
        .background(Theme.background)
        .navigationTitle(live.counterpartName)
        .navigationSubtitle(live.presence ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // C02a — native Menu: Report · Block.
                Menu {
                    Button("Report", systemImage: "exclamationmark.bubble") { confirm = .report }
                    Button("Block", systemImage: "hand.raised", role: .destructive) { confirm = .block }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More")
            }
        }
        .alert(confirm?.title ?? "", item: $confirm) { action in
            Button(action.confirmLabel, role: .destructive) { apply(action) }
            Button("Cancel", role: .cancel) {}
        } message: { action in
            Text(action.message(for: live.counterpartName))
        }
    }

    private func send(_ text: String) {
        store.send(text, in: thread.id)
        draft = ""
    }

    /// Block removes the chat and closes it; Report files it with Support.
    private func apply(_ action: ChatSafetyAction) {
        switch action {
        case .block:
            dismiss()
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                withAnimation(Theme.smooth) { store.threads.removeAll { $0.id == thread.id } }
            }
        case .report:
            store.send(String(localized: "I’d like to report my chat with \(live.counterpartName)."), in: "thr-support")
        }
    }
}

enum ChatSafetyAction: Hashable {
    case report, block
    var title: LocalizedStringKey {
        self == .report ? "Report this chat?" : "Block this person?"
    }
    var confirmLabel: LocalizedStringKey { self == .report ? "Report" : "Block" }
    func message(for name: String) -> String {
        self == .report
            ? "Our team will review the conversation with \(name)."
            : "\(name) won’t be able to message you. Active bookings are not affected."
    }
}

/// The booking this chat is about — photo, name, dates, chevron.
private struct BookingContextCard: View {
    let vehicle: String

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 52, height: 36)
                .background { PhotoFill(photoName: "mercedesAMGGT", symbol: "car.fill", glyphSize: 16) }
                .clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(vehicle)
                    .font(Theme.Font.subheadlineSemibold)
                    .foregroundStyle(Theme.ink)
                Text(verbatim: "22–23 Sep · Pickup in Sahil, Baku")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(Theme.Font.footnote)
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(10)
        .glassCard(Theme.Radius.group)
    }
}

private struct MessageBubble: View {
    let text: String
    let isFromMe: Bool
    var attachment: MessageAttachment? = nil

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 56) }
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                if let attachment {
                    AttachmentBubble(attachment: attachment, isFromMe: isFromMe)
                }
                if !text.isEmpty {
                    Text(text)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(isFromMe ? Theme.brandTint : Theme.card, in: .rect(cornerRadius: 22))
                }
            }
            if !isFromMe { Spacer(minLength: 56) }
        }
    }
}

/// Quick replies — tinted glass capsules that send in one tap.
private struct QuickReplies: View {
    let replies: [String]
    /// Suggestions came from the on-device model — shown with a sparkle.
    var isAI = false
    let onSend: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if isAI {
                    Image(systemName: "sparkles")
                        .font(Theme.Font.subheadlineSemibold)
                        .foregroundStyle(Theme.goldText)
                        .symbolEffect(.pulse, options: .nonRepeating, value: replies)
                        .accessibilityLabel("Suggested replies")
                }
                ForEach(replies, id: \.self) { reply in
                    Button(reply) { onSend(reply) }
                        .font(Theme.Font.subheadlineSemibold)
                        .foregroundStyle(Theme.ink)
                        // C02: quick replies sit on brand/tint.
                        .buttonStyle(.glass(.regular.tint(Theme.brandTint)))
                        .buttonBorderShape(.capsule)
                        .tint(Theme.brandSolid.opacity(0.25))
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .animation(Theme.smooth, value: replies)
        }
        .scrollIndicators(.hidden)
        .padding(.vertical, 8)
    }
}

/// The bubbles, newest at the bottom; new ones pop in from their side.
private struct ThreadMessages: View {
    let thread: MessageThread
    let isTyping: Bool

    private var incomingCount: Int { thread.messages.count { !$0.isFromMe } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                Text("Rentbutik may review chats to keep everyone safe.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                if let first = thread.messages.first?.sentAt {
                    Text("Today · \(first.formatted(.dateTime.hour().minute()))")
                        .font(Theme.Font.footnoteRegular)
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.bottom, 6)
                }
                ForEach(thread.messages) { message in
                    MessageBubble(text: message.text, isFromMe: message.isFromMe,
                                  attachment: message.attachment)
                        .transition(.scale(0.85, anchor: message.isFromMe ? .bottomTrailing : .bottomLeading)
                            .combined(with: .opacity))
                }
                if isTyping {
                    TypingBubble()
                        .transition(.scale(0.8, anchor: .bottomLeading).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .animation(Theme.bouncy, value: thread.messages.count)
            .animation(Theme.snappy, value: isTyping)
        }
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.impact(weight: .light), trigger: incomingCount)
    }
}

/// Three dots on an incoming bubble while the counterpart "types".
private struct TypingBubble: View {
    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
                .font(Theme.Font.title3)
                .foregroundStyle(Theme.inkSoft)
                .symbolEffect(.variableColor.iterative, options: .repeating)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.card, in: .rect(cornerRadius: 20))
                .accessibilityLabel("Typing")
            Spacer(minLength: 60)
        }
    }
}

/// "+" attach, capsule field, and a dark send circle.
private struct MessageComposer: View {
    @Binding var draft: String
    let onAttach: (MessageAttachment) -> Void
    let onSend: () -> Void

    @State private var sends = 0
    private var canSend: Bool { !draft.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        HStack(spacing: 10) {
            AttachMenu(onAttach: onAttach)

            HStack(spacing: 8) {
                TextField("Message", text: $draft, axis: .vertical)
                    .font(Theme.Font.body)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit { if canSend { sends += 1; onSend() } }
                Button {
                    sends += 1
                    onSend()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(Theme.Font.headline)
                        .foregroundStyle(Theme.card)
                        .frame(width: 32, height: 32)
                        .background(Theme.ink, in: .circle)
                }
                .disabled(!canSend)
                .opacity(canSend ? 1 : 0.4)
                .accessibilityLabel("Send")
            }
            .padding(.leading, 16)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .capsule)
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.bottom, 8)
        .sensoryFeedback(.selection, trigger: sends)
    }
}

#Preview("C01 · Chats") {
    NavigationStack {
        ChatsScreen(store: .seeded(), router: AppRouter())
    }
}

#Preview("C02 · Thread") {
    let store = Store.seeded()
    return NavigationStack {
        ThreadScreen(thread: store.threads[1], store: store)
    }
}

