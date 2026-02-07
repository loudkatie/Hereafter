//
//  LocationManager.swift
//  Hereafter
//
//  CoreLocation integration. Phase 1: current location + reverse geocoding.
//  Phase 2: geofencing + background monitoring.
//

import Foundation
import CoreLocation

@MainActor
class LocationManager: NSObject, ObservableObject {
    
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var currentPlaceName: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 50 // Update every 50m of movement
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Permissions
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }
    
    var hasLocationPermission: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Location Updates
    
    func startUpdating() {
        guard hasLocationPermission else { return }
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    // MARK: - Reverse Geocoding
    
    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first else { return }
            
            Task { @MainActor in
                // Try to get the most specific place name available
                self?.currentPlaceName = placemark.name
                    ?? placemark.subLocality
                    ?? placemark.locality
                    ?? "Unknown location"
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if self.hasLocationPermission {
                self.startUpdating()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location.coordinate
            self.reverseGeocode(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Hereafter: Location error — \(error.localizedDescription)")
    }
}
