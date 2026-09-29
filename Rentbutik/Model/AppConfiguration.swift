import Foundation

/// Demo services are explicit and unavailable in release builds.
enum AppConfiguration {
    static var isDemo: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
