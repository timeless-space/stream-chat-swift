//
//  Snackbar.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 26/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageType {
    public static let ChatGroupMute = 100
    public static let ChatGroupUnMute = 101
    public static let RedPacketExpired = 102
    public static let MessageCopied = 103
    public static let StickerAlreadyDownloaded = 104
}
class Snackbar {
    static func show(text: String, messageType: Int? = nil) {
        var userInfo = [String: Any]()
        userInfo["message"] = text
        if let type = messageType {
            userInfo["type"] = type
        }
        NotificationCenter.default.post(name: .showSnackBar, object: nil, userInfo: userInfo)
    }

    static func hide() {
        NotificationCenter.default.post(name: .hideSnackBar, object: nil)
    }
}
