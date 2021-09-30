//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat

public class ChannelListViewModel: ObservableObject {
    
    private let chatClient: ChatClient
    private let controller: ChatChannelListController
    private let channelNamer = DefaultChatChannelNamer()
    
    @Published var channels = LazyCachedMapCollection<ChatChannel>()
    
    public init(chatClient: ChatClient) {
        self.chatClient = chatClient
        controller = chatClient.channelListController(
            query: .init(
                filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: ["luke_skywalker"])]),
                sort: [.init(key: .lastMessageAt, isAscending: false)],
                pageSize: 10
            )
        )
        
        controller.synchronize { [unowned self] error in
            if let error = error {
                // handle error
                print(error)
            } else {
                // access channels
                self.channels = controller.channels
            }
        }
    }
    
    func makeViewModel(for channel: ChatChannel) -> ChatChannelViewModel {
        let controller = chatClient.channelController(for: channel.cid,
                                                      messageOrdering: .topToBottom).observableObject
        let viewModel = ChatChannelViewModel(channel: controller)
        return viewModel
    }
    
    func name(forChannel channel: ChatChannel) -> String {
        channelNamer(channel, chatClient.currentUserId) ?? "not named"
    }
    
}

extension ChatChannel: Identifiable {
    
    public var id: String {
        self.cid.id
    }
    
}
