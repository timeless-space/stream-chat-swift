//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

public class StreamChat {
    var chatClient: ChatClient
    
    public init(chatClient: ChatClient) {
        self.chatClient = chatClient
        StreamChatProviderKey.currentValue = self
    }
}

private struct StreamChatProviderKey: InjectionKey {
    static var currentValue: StreamChat?
}

extension InjectedValues {
    var streamChat: StreamChat {
        get {
            guard let injected = Self[StreamChatProviderKey.self] else {
                fatalError("Chat client was not setup")
            }
            return injected
        }
        set {
            Self[StreamChatProviderKey.self] = newValue
        }
    }
    
    var chatClient: ChatClient {
        get {
            streamChat.chatClient
        }
        set {
            streamChat.chatClient = newValue
        }
    }
}
