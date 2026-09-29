import UserNotifications

/// Real iOS banners for demo events (new chat messages, bookings), shown
/// even while the app is open. Permission is asked the first time something
/// arrives — never at launch.
final class LocalNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotifier()

    private var asked = false

    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    func post(title: String, body: String, thread: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            if !asked {
                asked = true
                _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.threadIdentifier = thread
            try? await center.add(UNNotificationRequest(identifier: UUID().uuidString,
                                                        content: content, trigger: nil))
        }
    }

    // Show the banner in the foreground too — that's what makes it feel live.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

