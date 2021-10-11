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
    
    @Published var deeplinkChannel: ChatChannel?
    
    private var selectedChannelId: String?
    
    public init(selectedChannelId: String? = nil) {
        self.selectedChannelId = selectedChannelId
    }
    
    func loadChannels() {
        controller = chatClient.channelListController(
            query: .init(
                filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: [chatClient.currentUserId!])]),
                sort: [.init(key: .lastMessageAt, isAscending: false)],
                pageSize: 10
            )
        )
        
        channels = controller.channels
        
        controller.synchronize { [unowned self] error in
            if let error = error {
                // handle error
                print(error)
            } else {
                // access channels
                self.channels = controller.channels
                self.checkForDeeplinks()
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
    
    // MARK: - private
    
    private func checkForDeeplinks() {
        if let selectedChannelId = selectedChannelId,
           let channelId = try? ChannelId(cid: selectedChannelId) {
            let chatController = chatClient.channelController(for: channelId, messageOrdering: .topToBottom)
            deeplinkChannel = chatController.channel
            self.selectedChannelId = nil
        }
    }
}

extension ChatChannel: Identifiable {
    public var id: String {
        cid.id
    }
}
