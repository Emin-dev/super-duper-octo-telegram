import MapKit

/// Warms MapKit's tile cache for the EV (Baku) and Golf (Sea Breeze) maps
/// at launch, so those screens open with the map already drawn.
/// Snapshots render off screen and share the system tile cache.
enum MapPrewarm {
    private static var done = false

    static func start() {
        guard !done else { return }
        done = true
        let regions = regions
        Task.detached(priority: .utility) {
            for region in regions {
                let options = MKMapSnapshotter.Options()
                options.region = region
                options.size = CGSize(width: 440, height: 960)
                options.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
                _ = try? await MKMapSnapshotter(options: options).start()
            }
        }
    }

    /// The camera regions EV01 and G01 open on.
    private static let regions: [MKCoordinateRegion] = [
        MKCoordinateRegion(center: .baku, latitudinalMeters: 1800, longitudinalMeters: 1800),
        MKCoordinateRegion(center: .baku, latitudinalMeters: 4200, longitudinalMeters: 4200),
        MKCoordinateRegion(center: .seaBreeze, latitudinalMeters: 1300, longitudinalMeters: 1300),
    ]
}

