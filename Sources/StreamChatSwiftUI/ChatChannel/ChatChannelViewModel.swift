//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

public class ChatChannelViewModel: ObservableObject {
    
    private var cancellables = Set<AnyCancellable>()
    
    @ObservedObject var channel: ChatChannelController.ObservableObject
    
    @Published var messages = LazyCachedMapCollection<ChatMessage>() {
        didSet {
            if oldValue.count != messages.count {
                scrollToLastMessage()
            }
        }
    }
    
    @Published var scrolledId: String?
    
    @Published var text = ""
    
    @Published var showScrollToLatestButton = false
        
    public init(channel: ChatChannelController.ObservableObject) {
        self.channel = channel
    }
    
    func subscribeToChannelChanges() {
        self.messages = channel.messages
        self.channel.objectWillChange.sink { [weak self] in
            guard let self = self else { return }
            self.messages = self.channel.messages
        }
        .store(in: &cancellables)
    }
    
    func sendMessage() {
        channel.controller.createNewMessage(text: text) {
            switch $0 {
            case .success(let response):
                print(response)
            case .failure(let error):
                print(error)
            }
        }
        
        self.text = ""
    }
    
    func scrollToLastMessage() {
        if scrolledId != messages.first?.id {
            scrolledId = messages.first?.id
        }
    }
    
}

extension ChatMessage: Identifiable {}
