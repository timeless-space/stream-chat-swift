//
//  LocationHelper.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 20/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import CoreLocation

public class LocationHelper {

    public static let shared = LocationHelper()

    public func getLocationInfo(currentLocation: CLLocation, completion: @escaping CLGeocodeCompletionHandler) {
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
            completion(placemarks, error)
        }
    }
}
