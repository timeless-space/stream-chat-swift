//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat

public class MessageViewModel: ObservableObject {
    let message: ChatMessage
    private(set) var messageController: ChatMessageController.ObservableObject!
    
    @Injected(\.chatClient) var chatClient
    
    public init(message: ChatMessage) {
        self.message = message
        messageController = chatClient.messageController(
            cid: message.cid!, messageId: message.id
        ).observableObject
    }
    
    func loadReactions() {
        messageController.controller.synchronize()
    }
    
    func reactionTapped(_ reaction: String) {}
}
