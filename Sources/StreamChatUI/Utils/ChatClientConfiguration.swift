//
//  ChatClientConfiguration.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public extension ChatClient {
    static var shared: ChatClient = {
        var config = ChatClientConfig(apiKey: APIKey(ChatClientConfiguration.shared.apiKey))
        config.isLocalStorageEnabled = true
        config.shouldFlushLocalStorageOnStart = false
        let client = ChatClient(config: config) { completion in
            ChatClientConfiguration.shared.requestNewChatToken?()
            ChatClientConfiguration.shared.streamChatToken = { token in
                completion(.success(token))
            }
        }
        return client
    }()
}

public typealias callbackGeneralGroupInviteLink = ((URL?) -> Void)

open class ChatClientConfiguration {

    // MARK: - Variables
    public static let shared = ChatClientConfiguration()
    open var apiKey = ""
    // streamChat request token
    open var streamChatToken: ((Token) -> Void)?
    open var requestNewChatToken: (() -> Void)?
    // private group dynamicLink
    open var requestPrivateGroupDynamicLink: ((String, String, String) -> Void)? // groupId, signature, expiry
    open var requestedPrivateGroupDynamicLink: ((URL?) -> Void)?
    // General group invite link
    open var requestedGeneralGroupDynamicLink: callbackGeneralGroupInviteLink?
    // MARK: - Init
    public init() {}
}

public struct ChatGroupUIConfiguration {
    private static let groupNameColors = [Appearance.default.colorPalette.groupChatUserColorBlue,Appearance.default.colorPalette.groupChatUserColorYellow,Appearance.default.colorPalette.groupChatUserColorPink,Appearance.default.colorPalette.groupChatUserColorGreen]
    public static var userColorContainer = [UserId: UIColor?]()
    public static func getRandomColor(userID: UserId) -> UIColor {
        if let color = ChatGroupUIConfiguration.userColorContainer[userID] as? UIColor {
            return color
        }
        let color = groupNameColors.randomElement() ?? UIColor.white
        ChatGroupUIConfiguration.userColorContainer[userID] = color
        return color
    }
}
