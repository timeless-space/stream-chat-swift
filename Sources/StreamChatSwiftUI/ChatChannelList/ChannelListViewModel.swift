//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat

public class ChannelListViewModel: ObservableObject {
    @Injected(\.chatClient) var chatClient: ChatClient
    
    private var controller: ChatChannelListController!
    private let channelNamer = DefaultChatChannelNamer()
    
    @Published var channels = LazyCachedMapCollection<ChatChannel>()
    
    @Published var selectedChannel: ChatChannel?
    
    public init() {}
    
    func loadChannels() {
        controller = chatClient.channelListController(
            query: .init(
                filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: [chatClient.currentUserId!])]),
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
    
    public func makeViewModel(for channel: ChatChannel) -> ChatChannelViewModel {
        let controller = chatClient.channelController(
            for: channel.cid,
            messageOrdering: .topToBottom
        )
        let viewModel = ChatChannelViewModel(channelController: controller)
        return viewModel
    }
    
    public func name(forChannel channel: ChatChannel) -> String {
        channelNamer(channel, chatClient.currentUserId) ?? "not named"
    }
    
    public func open(channel: ChatChannel) {
        selectedChannel = channel
    }
}

extension ChatChannel: Identifiable {
    public var id: String {
        cid.id
    }
}
