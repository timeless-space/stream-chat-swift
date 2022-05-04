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
    static var shared: ChatClient {
        get {
            if let client =  ChatClientConfiguration.shared.chatClient {
                return client
            } else {
                var config = ChatClientConfig(apiKey: APIKey(ChatClientConfiguration.shared.apiKey))
                config.isLocalStorageEnabled = true
                config.shouldFlushLocalStorageOnStart = false
                let client = ChatClient(config: config) { completion in
                    ChatClientConfiguration.shared.requestNewChatToken?()
                    ChatClientConfiguration.shared.streamChatToken = { token in
                        completion(.success(token))
                    }
                }
                ChatClientConfiguration.shared.chatClient = client
                return ChatClientConfiguration.shared.chatClient!
            }
        }
    }
}

public typealias callbackGeneralGroupInviteLink = ((URL?) -> Void)

open class ChatClientConfiguration {

    // MARK: - Variables
    public static let shared = ChatClientConfiguration()

    // Current Chat client
    open var chatClient: ChatClient?

    open var apiKey = ""
    // streamChat request token
    open var streamChatToken: ((Token) -> Void)?
    open var requestNewChatToken: (() -> Void)?
    // private group dynamicLink
    open var requestPrivateGroupDynamicLink: ((String, String, String) -> Void)? // groupId, signature, expiry
    open var requestedPrivateGroupDynamicLink: ((URL?) -> Void)?
    // General group invite link
    open var requestedGeneralGroupDynamicLink: callbackGeneralGroupInviteLink?
    // join group
    open var joinInviteGroup: ((Bool) -> Void)?
    // Join private group
    open var joinPrivateGroup: (() -> Void)?
    // get private group
    open var getPrivateGroup: ((ChatInviteInfo?) -> Void)?
    // create private group
    open var createPrivateGroup: ((CreatePrivateGroup) -> Void)?

    // MARK: - Init
    public init() {}
}
