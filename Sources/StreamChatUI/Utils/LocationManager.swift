//
//  LocationManager.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 04/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

import UIKit
import CoreLocation

public protocol onLocationPermissionChangedCallback: NSObject {
    func onPermissionChanged()
}

public class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: Variables
    public static let shared = LocationManager()
    public var locationManager: CLLocationManager?
    public var location: Dynamic<CLLocation> = Dynamic(CLLocation())
    public weak var delegate: onLocationPermissionChangedCallback? = nil

    private override init() {
        super.init()
    }

    public class func isAuthorized() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }

    public class func hasLocationPermissionDenied() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .restricted, .denied:
                return true
            default:
                return false
            }
        } else {
            return true
        }
    }

    public func requestLocationAuthorization() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
        locationManager?.requestWhenInUseAuthorization()
    }

    public func requestGPS() {
        self.locationManager?.requestLocation()
    }

    public func isEmptyCurrentLoc() -> Bool {
        return location.value.coordinate.latitude == 0 && location.value.coordinate.longitude == 0
    }

    public class func getDistanceInKm(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000
    }

    class func showLocationPermissionAlert() {
        let alertController = UIAlertController(title: "Location Permission Required", message: "Please enable location permissions in settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Settings", style: .default, handler: {(cAlertAction) in
            //Redirect to Settings app
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        UIApplication.shared.getTopViewController()?.present(alertController, animated: true, completion: nil)
    }
}

extension LocationManager {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            return
        }
        self.location.value = lastLocation
    }
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // check the authorization status changes here
        delegate?.onPermissionChanged()
    }
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)
        if (error as? CLError)?.code == .denied {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
}
