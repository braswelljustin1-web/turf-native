import CoreLocation
import Combine

struct LocationFix: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var accuracyMeters: Double
    var capturedAt: Date
    var approximate: Bool
}

@MainActor final class PropertyLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var fix: LocationFix?
    @Published private(set) var status = "Enter the property location manually, or request a device fix."
    @Published private(set) var requesting = false
    private let manager = CLLocationManager()
    private var timeout: Task<Void, Never>?
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    func request() {
        cancel()
        fix = nil
        requesting = true
        status = "Waiting for location permission or a device fix…"
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled else { return }
            self?.finish("Location timed out. You can retry or enter the property manually.")
        }
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        else { acquireIfAllowed() }
    }
    private func acquireIfAllowed() {
        guard requesting else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        case .denied: finish("Location access is denied. Enter the property manually or change access in Settings.")
        case .restricted: finish("Location access is restricted. Manual entry is available.")
        case .notDetermined: break
        @unknown default: finish("Location is unavailable. Manual entry is available.")
        }
    }
    func cancel() {
        timeout?.cancel(); timeout = nil
        manager.stopUpdatingLocation()
        requesting = false
    }
    private func finish(_ message: String) { cancel(); status = message }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            fix = nil
            finish("Location access is unavailable. Saved property locations are unchanged; manual entry is available.")
        } else { acquireIfAllowed() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard requesting else { return }
        guard let location = locations.last, location.horizontalAccuracy >= 0,
              abs(location.timestamp.timeIntervalSinceNow) <= 60,
              CLLocationCoordinate2DIsValid(location.coordinate) else {
            finish("The device returned an old or invalid location. Retry or enter the property manually."); return
        }
        fix = LocationFix(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,
            accuracyMeters: location.horizontalAccuracy, capturedAt: location.timestamp,
            approximate: manager.accuracyAuthorization == .reducedAccuracy)
        finish("Device fix captured locally. Confirm that you are at the property before using it.")
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard requesting else { return }
        finish("A device location could not be obtained. Retry or use manual entry.")
    }
}
