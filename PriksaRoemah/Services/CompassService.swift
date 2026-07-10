import Combine
import CoreLocation

/// Baca arah hadap rumah dari compass (heading) perangkat — pengganti input manual
/// House Facing. Dipanggil begitu survey dimulai supaya heading sempat update
/// sebelum lantai pertama selesai discan.
final class CompassService: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var headingDegrees: CLLocationDirection?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        headingDegrees = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
}
