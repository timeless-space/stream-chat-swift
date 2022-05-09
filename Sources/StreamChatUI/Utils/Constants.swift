//
//  Constants.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 06/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public struct Constants {
    public static let blockExplorer = "https://explorer.harmony.one/tx/"
    public static let privateGroupRadius = 0.5 //km
    // Red packet expire
    public static let redPacketExpireTime = 15 //minutes
    // Padding for messages bubble view
    public static let MessageLeftPadding: CGFloat = 8.0
    public static let MessageRightPadding: CGFloat = -8.0
    public static let MessageTopPadding: CGFloat = 15
    public static var decimalSeparator: String {
        return Locale.current.decimalSeparator ?? "."
    }
    public static let giphyBaseUrl = "https://api.giphy.com/"
}

public struct UserdefaultKey {
    public static let downloadedSticker = "downloadedSticker"
    public static let visibleSticker = "visibleSticker"
    public static let recentSticker = "recentSticker"
}

