import Foundation
import MapKit
import AppKit

struct Job { let lat: Double; let lon: Double; let meters: Double
             let w: Int; let h: Int; let dark: Bool; let out: String }

let jobs: [Job] = [
  // Baku city centre — for Cars near you / EV
  Job(lat: 40.3725, lon: 49.8430, meters: 1800, w: 804, h: 1748, dark: false, out: "baku-light.png"),
  Job(lat: 40.3725, lon: 49.8430, meters: 1800, w: 804, h: 1748, dark: true,  out: "baku-dark.png"),
  // SeaBreeze resort, north of Baku — for Golf
  Job(lat: 40.6420, lon: 49.8200, meters: 1200, w: 804, h: 1748, dark: false, out: "seabreeze-light.png")
]

let dir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let group = DispatchGroup()

for j in jobs {
  group.enter()
  let o = MKMapSnapshotter.Options()
  o.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: j.lat, longitude: j.lon),
                                latitudinalMeters: j.meters, longitudinalMeters: j.meters)
  o.size = CGSize(width: j.w, height: j.h)
  o.showsBuildings = true
  if #available(macOS 13.0, *) {
    // .muted emphasis matches RULE B9's desaturated map requirement
    o.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
  }
  o.appearance = NSAppearance(named: j.dark ? .darkAqua : .aqua)

  MKMapSnapshotter(options: o).start(with: .global()) { snap, err in
    defer { group.leave() }
    guard let snap = snap else {
      FileHandle.standardError.write("FAIL \(j.out): \(err?.localizedDescription ?? "unknown")\n".data(using: .utf8)!)
      return
    }
    guard let tiff = snap.image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
      FileHandle.standardError.write("FAIL encode \(j.out)\n".data(using: .utf8)!); return
    }
    let url = URL(fileURLWithPath: dir).appendingPathComponent(j.out)
    do { try png.write(to: url); print("OK \(j.out) \(png.count) bytes") }
    catch { FileHandle.standardError.write("FAIL write \(j.out): \(error)\n".data(using: .utf8)!) }
  }
}
let r = group.wait(timeout: .now() + 120)
if r == .timedOut { FileHandle.standardError.write("TIMEOUT\n".data(using: .utf8)!); exit(1) }

