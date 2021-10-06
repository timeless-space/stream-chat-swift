//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

public class StreamChat {
    var chatClient: ChatClient
    var theme: ChatTheme
    
    public init(
        chatClient: ChatClient,
        theme: ChatTheme = ChatTheme()
    ) {
        self.chatClient = chatClient
        self.theme = theme
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
    
    var streamColors: StreamColors {
        get {
            streamChat.theme.colors
        }
        set {
            streamChat.theme.colors = newValue
        }
    }
}
