import SwiftUI
import MapKit

extension CLLocationCoordinate2D {
    /// Downtown Baku — Sahil / Fountains Square.
    static let baku = CLLocationCoordinate2D(latitude: 40.3719, longitude: 49.8456)
    /// SeaBreeze resort, north of the city on the Absheron peninsula.
    static let seaBreeze = CLLocationCoordinate2D(latitude: 40.5905, longitude: 49.9880)
}

/// A vehicle shown on the canvas.
struct MapVehiclePin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let symbol: String
    var isSelected: Bool = false
    /// G01 prints the charge under the selected pin — "92%".
    var caption: String? = nil
    /// N2: the held vehicle shows "Held" and a clock badge.
    var isHeld: Bool = false
}

/// A map is a CANVAS you float over, not a panel — RULE P.
///
/// This is real MapKit, not a rendered still. The still was only ever a
/// stand-in because Figma cannot host a live map.
///
/// On RULE B9: that rule forbids a **live blurred** backdrop, which caused
/// real device stutter — blur 75 plus saturation 0.7 recomputed every frame.
/// Nothing here is blurred. The desaturation it asks for comes from
/// `.mapStyle(.standard(emphasis: .muted))`, which is the same treatment
/// `tools/mapsnap.swift` used to bake the original PNG.
///
/// Everything floats inside ONE bottom-anchored glass panel. Nothing sits
/// loose on cartography — bare text over streets is unreadable, and that was
/// a real defect on `EV / Active trip`.
struct MapCanvas<Panel: View>: View {
    var center: CLLocationCoordinate2D = .baku
    /// Metres across. Tighter for a single vehicle, wider for a fleet.
    var span: CLLocationDistance = 1400
    var pins: [MapVehiclePin] = []
    /// When this changes the camera glides to it — the swiped-to vehicle.
    var focus: CLLocationCoordinate2D? = nil
    /// Trailing top control. EV01 uses a QR scanner, others recentre.
    /// `nil` hides the trailing button (G01).
    var trailingSymbol: String? = "location.fill"
    var onTrailing: (() -> Void)? = nil
    var showsControls: Bool = true
    /// False when the panel is a full-bleed carousel that manages its own
    /// margins.
    var insetPanel: Bool = true
    /// Tapping a pin selects that vehicle (the carousel scrolls to it).
    var onSelectPin: ((String) -> Void)? = nil
    /// G02: the dotted walking route to the Golf desk.
    var route: [CLLocationCoordinate2D] = []
    var onBack: (() -> Void)?
    var onRecenter: (() -> Void)?
    @ViewBuilder let panel: Panel

    @State private var position: MapCameraPosition = .automatic

    private var initialPosition: MapCameraPosition {
        .region(MKCoordinateRegion(center: center,
                                   latitudinalMeters: span,
                                   longitudinalMeters: span))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position, interactionModes: [.pan, .zoom]) {
                ForEach(pins) { pin in
                    Annotation("", coordinate: pin.coordinate) {
                        Button {
                            onSelectPin?(pin.id)
                        } label: {
                            MapVehicleMarker(symbol: pin.symbol,
                                             isSelected: pin.isSelected,
                                             caption: pin.isHeld ? String(localized: "Held") : pin.caption,
                                             isHeld: pin.isHeld)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.plain)
                        .disabled(onSelectPin == nil)
                        .accessibilityLabel(pin.caption ?? pin.id)
                    }
                }
                if route.count > 1 {
                    MapPolyline(coordinates: route)
                        .stroke(Theme.brandSolid,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0.1, 10]))
                }
            }
            // `.muted` is the desaturation RULE B9 calls for. Points of
            // interest stay on — they are how you find the car.
            .mapStyle(.standard(emphasis: .muted))
            .ignoresSafeArea()

            if showsControls {
                VStack {
                    HStack {
                        if let onBack {
                            MapCircleButton(symbol: "chevron.left",
                                            label: "Back", action: onBack)
                        }
                        Spacer()
                        if let trailingSymbol {
                            MapCircleButton(symbol: trailingSymbol,
                                            label: trailingSymbol == "location.fill" ? "Recentre" : "Scan") {
                                if let onTrailing { onTrailing() }
                                else {
                                    withAnimation(Theme.smooth) { position = initialPosition }
                                    onRecenter?()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Space.screen)
                    Spacer()
                }
            }

            // The single glass panel that gathers every control.
            panel
                .padding(.horizontal, insetPanel ? Theme.Space.screen : 0)
                .padding(.bottom, Theme.Space.gap)
        }
        .onAppear { position = initialPosition }
        .onChange(of: focus.map { "\($0.latitude),\($0.longitude)" }) {
            guard let focus else { return }
            withAnimation(Theme.smooth) {
                position = .region(MKCoordinateRegion(center: focus,
                                                      latitudinalMeters: span,
                                                      longitudinalMeters: span))
            }
        }
    }
}

/// RULES.md B10: only the SELECTED pin scales (1.35) and casts a shadow.
/// Live shadows on every pin cost real frames with 45 pins on screen.
private struct MapVehicleMarker: View {
    let symbol: String
    let isSelected: Bool
    var caption: String?
    var isHeld = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: isSelected ? 22 : 15, weight: .semibold))
                .foregroundStyle(Theme.onBrand)
                .frame(width: isSelected ? 48 : 33, height: isSelected ? 48 : 33)
                .background(Theme.brandSolid, in: .circle)
                .overlay { Circle().strokeBorder(Theme.onBrand, lineWidth: 2) }
                .shadow(color: isSelected ? .black.opacity(0.25) : .clear,
                        radius: isSelected ? 8 : 0, y: isSelected ? 3 : 0)
                .overlay(alignment: .topTrailing) {
                    if isHeld {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.brandSolid)
                            .padding(3)
                            .background(Theme.onBrand, in: .circle)
                            .offset(x: 4, y: -4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            if isSelected || isHeld, let caption {
                Text(caption)
                    .font(Theme.Font.subheadlineSemibold)
                    .foregroundStyle(Theme.ink)
            }
        }
        .animation(Theme.bouncy, value: isSelected)
        .animation(Theme.bouncy, value: isHeld)
    }
}

/// 44pt circular icon button — RULES.md C.
struct MapCircleButton: View {
    let symbol: String
    let label: LocalizedStringKey
    let action: () -> Void

    @State private var bounce = 0

    var body: some View {
        Button {
            bounce += 1
            action()
        } label: {
            Image(systemName: symbol)
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.ink)
                .symbolEffect(.bounce, value: bounce)
                .frame(width: 44, height: 44)
                .glassEffect(.regular, in: .circle)
        }
        .buttonStyle(PressScale(haptic: .click))
        .accessibilityLabel(label)
    }
}

/// The glass container every map control lives in.
struct MapPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

/// Charge ring. `arcData` in Figma genuinely encodes the level, so this does
/// too rather than faking a fixed arc.
struct BatteryRing: View {
    /// 0–100.
    let percent: Int
    var diameter: CGFloat = 46

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(Double(percent) / 100, 0), 1))
                .stroke(Theme.brandSolid,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            // EV01 prints the charge inside the ring — "87%".
            Text("\(percent)%")
                .font(.system(size: diameter * 0.26, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement()
        .accessibilityLabel("Battery")
        .accessibilityValue("\(percent) percent")
    }
}


/// Swipeable vehicle cards over a map — the second card peeks at the right
/// edge, exactly as EV01 and G01 draw it. Native paging scroll; the centred
/// card's id is written to `selection`, which the map follows.
struct VehicleCarousel<Item: Identifiable, Card: View>: View where Item.ID == String {
    let items: [Item]
    @Binding var selection: String?
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    card(item)
                        // Figma: 342 pt on a 402 pt screen, the next card peeking by ~32 pt.
                        .containerRelativeFrame(.horizontal) { width, _ in width - 28 }
                        .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
        // No edge fade — it drew a pale band across the map behind the cards.
        .scrollEdgeEffectHidden(true, for: .all)
        .contentMargins(.horizontal, Theme.Space.screen, for: .scrollContent)
        // Hug the cards' height so the carousel anchors to the bottom of the
        // map instead of claiming the whole screen.
        .fixedSize(horizontal: false, vertical: true)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// ‹ inside a map card — steps back to the card's previous state (EV05,
/// EV01e, EV01d…) without reaching for the screen's top button.
struct CardBackButton: View {
    let action: () -> Void
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(Theme.Font.subheadlineSemibold)
                .foregroundStyle(Theme.ink)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.circle)
        .sensoryFeedback(.selection, trigger: taps)
        .accessibilityLabel("Back")
    }
}

/// The QR button that sits left of Start on EV and Golf cards.
struct ScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "qrcode.viewfinder")
        }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.circle)
        // Same 52 pt row as Book and Start (N2).
        .controlSize(.large)
        .foregroundStyle(Theme.ink)
        .accessibilityLabel("Scan to unlock")
    }
}

/// One map card taken out of the carousel (G01a, G01d, EV day tariff).
/// It is never clipped: if it's taller than the room above the tab bar, it
/// scrolls inside itself instead.
struct SingleMapCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
                .padding(.horizontal, Theme.Space.screen)
            ScrollView {
                content
                    .padding(.horizontal, Theme.Space.screen)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

/// EV01 / G01 "🕒 14:59" — reserve the vehicle free for 15 minutes.
/// Idle it reads "Book"; while held it counts down and a tap offers cancel.
struct HoldButton: View {
    let until: Date?
    /// EV01 "Book · 15 min", G01 "Book".
    var title: LocalizedStringKey = "Book"
    let onBook: () -> Void
    let onCancel: () -> Void

    @State private var confirmCancel = false
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            if until == nil { onBook() } else { confirmCancel = true }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(Theme.brandSolid)
                    .symbolEffect(.bounce, value: until == nil)
                if let until {
                    Text(timerInterval: Date.now...max(until, .now), countsDown: true)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                } else {
                    // Start keeps its label; Book steps down on narrow rows.
                    ViewThatFits(in: .horizontal) {
                        Text(title)
                        Text("Book")
                        EmptyView()
                    }
                }
            }
            .font(Theme.Font.headline)
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.rentbutik)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .animation(Theme.smooth, value: until)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .accessibilityLabel(until == nil ? "Book for 15 minutes" : "Held for you")
        .confirmationDialog("Cancel reservation?", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("Cancel reservation", role: .destructive, action: onCancel)
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("The car goes back on the map for everyone.")
        }
    }
}

