import SwiftUI

/// Filter chip. Two states, `Selected=true/false`.
///
/// RULE B3: chip text renders directly on the surface. Never put a filled shape
/// inside a `.background` under glass — it rasterises a second layer and the
/// text goes visibly blurry. Shipped as a bug once.
struct RentbutikChip: View {

    /// Two selected treatments exist in the file and they are NOT
    /// interchangeable:
    /// - `.solid` — `brand/solid` fill with `text/on-gold`. Filter chips on
    ///   `Renter / Cars near you`.
    /// - `.tint` — `brand/tint` fill with `text/gold`. Choice chips, e.g. the
    ///   duration picker on `Golf / Booking`.
    enum Style { case solid, tint }

    let title: LocalizedStringKey
    let isSelected: Bool
    var style: Style = .solid
    let action: () -> Void

    init(_ title: LocalizedStringKey,
         isSelected: Bool,
         style: Style = .solid,
         action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.style = style
        self.action = action
    }

    private var foreground: Color {
        guard isSelected else { return Theme.ink }
        return style == .solid ? Theme.onGold : Theme.goldText
    }

    private var background: Color {
        guard isSelected else { return Theme.card }
        return style == .solid ? Theme.brandSolid : Theme.brandTint
    }

    var body: some View {
        Button(action: action) {
            // Never white on gold (RULE B1) — the solid style uses
            // `text/on-gold` #14161A, confirmed from the file's bindings.
            Text(title)
                .font(Theme.Font.subheadline)
                .foregroundStyle(foreground)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .glassChip(tint: isSelected
                           ? (style == .solid ? Theme.brandSolid : Theme.brandSolid.opacity(0.3))
                           : nil)
        }
        .buttonStyle(PressScale(haptic: .click))
        .animation(Theme.snappy, value: isSelected)
    }
}

#Preview {
    @Previewable @State var selected = "All"
    let options = ["All", "Electric", "Golf", "Luxury"]

    return HStack(spacing: 8) {
        ForEach(options, id: \.self) { option in
            RentbutikChip(LocalizedStringKey(option),
                          isSelected: selected == option) {
                selected = option
            }
        }
    }
    .padding()
    .background(Theme.background)
}

