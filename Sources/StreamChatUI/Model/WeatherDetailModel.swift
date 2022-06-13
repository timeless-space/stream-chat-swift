//
//  WeatherDetailModel.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 10/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

public struct WeatherDetailModel {
    public var baseUrl = "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/Weather/"

    public var imageName: String?
    public var backgroundImage: UIImage?
    public var message: String?

    public func getImageUrl() -> String {
        return "\(baseUrl)\(imageName ?? "")"
    }
}
