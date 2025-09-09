//
//  GeoLocationService.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import CoreLocation
import Foundation

final class GeoLocationService: NSObject {
    
    var currentLocation: CLLocation? {
        return locationManager.location
    }
    
    private let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
    }
    
    deinit {
        locationManager.stopUpdatingLocation()
    }
}

extension GeoLocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14, *) {
            if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
                locationManager.startUpdatingLocation()
            }
            
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                locationManager.stopUpdatingLocation()
            }
        } else {
            if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                locationManager.startUpdatingLocation()
            }
            
            if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted {
                locationManager.stopUpdatingLocation()
            }
        }
        
    }
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        currentLocation = locationManager.location
//    }
}
