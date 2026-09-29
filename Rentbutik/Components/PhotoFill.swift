import SwiftUI
import UIKit

/// The app's one photo surface. Real photography when the asset exists,
/// a warm placeholder when it does not.
///
/// RULE B2: photo areas are OPAQUE, never glass. A glass backdrop ignores
/// `clipShape` and leaks the image past the rounded corners — shipped once.
/// Callers clip; this view only fills.
struct PhotoFill: View {
    let photoName: String?
    let symbol: String
    var glyphSize: CGFloat = 44

    var body: some View {
        if let photoName, UIImage(named: photoName) != nil {
            Image(photoName)
                .resizable()
                .scaledToFill()
                // Photography carries its own meaning; the label beside it
                // already names the vehicle.
                .accessibilityHidden(true)
        } else {
            LinearGradient(colors: [Theme.accentAmber.opacity(0.55),
                                    Theme.accentBronze.opacity(0.75)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: glyphSize, weight: .semibold))
                        .foregroundStyle(Theme.onBrand.opacity(0.9))
                }
        }
    }
}

