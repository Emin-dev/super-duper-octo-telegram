import SwiftUI

/// L01 · Places — the ONE place list, opened from every location row
/// (EV delivery and drivers, Golf drivers, Transfer pickup, car delivery).
/// Tapping a place chooses it and closes the sheet.
struct PlacesSheet: View {
    let store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var adding = false
    @State private var newName = ""
    @State private var newAddress = ""
    @State private var picks = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeader(title: "Places") { dismiss() }

            GroupedCard {
                ForEach(store.places) { place in
                    Button {
                        picks += 1
                        store.selectedPlaceID = place.id
                        dismiss()
                    } label: {
                        GroupedRow(symbol: place.symbol, label: LocalizedStringKey(place.name),
                                   showsDivider: place.id != store.places.last?.id) {
                            HStack(spacing: 10) {
                                Text(place.address)
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.inkSoft)
                                    .lineLimit(1)
                                Image(systemName: "checkmark")
                                    .font(Theme.Font.headline)
                                    .foregroundStyle(Theme.goldText)
                                    .opacity(place.id == store.selectedPlace?.id ? 1 : 0)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button { adding = true } label: {
                Label("Add a place", systemImage: "plus.circle.fill")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.goldText)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: Theme.Size.groupedRow, alignment: .leading)
                    .glassCard(Theme.Radius.group)
            }
            .buttonStyle(.plain)

            Text("One list for the whole app. A place saved here shows up in every place picker: EV delivery and drivers, Golf drivers, Transfer pickup and car delivery. Tap a place to use it here.")
                .font(Theme.Font.footnoteRegular)
                .foregroundStyle(Theme.inkSoft)
                .padding(.horizontal, 2)
        }
        .padding(.horizontal, Theme.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, Theme.Space.noTabBarClearance)
        .fittedSheet()
        .sensoryFeedback(.selection, trigger: picks)
        .alert("Add a place", isPresented: $adding) {
            TextField("Name", text: $newName)
            TextField("Address", text: $newAddress)
                .textContentType(.fullStreetAddress)
            Button("Add") {
                let name = newName.trimmingCharacters(in: .whitespaces)
                let address = newAddress.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty, !address.isEmpty { store.addPlace(name: name, address: address) }
                newName = ""; newAddress = ""
            }
            Button("Cancel", role: .cancel) { newName = ""; newAddress = "" }
        } message: {
            Text("It will show up in every place picker.")
        }
    }
}

#Preview("L01 · Places") {
    // Sheets snapshot blank in previews, so show the content itself.
    PlacesSheet(store: .seeded())
        .background(Theme.background)
}

