//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Factory used to create view models.
class ViewModelsFactory {
    private init() {}
    
    /// Creates the `ChannelListViewModel`.
    ///
    /// - Parameters:
    ///    - channelListController: possibility to inject custom channel list controller.
    ///    - selectedChannelId: pre-selected channel id (used for deeplinking).
    /// - Returns: `ChatChannelListViewModel`.
    static func makeChannelListViewModel(
        channelListController: ChatChannelListController? = nil,
        selectedChannelId: String? = nil
    ) -> ChatChannelListViewModel {
        ChatChannelListViewModel(
            channelListController: channelListController,
            selectedChannelId: selectedChannelId
        )
    }
    
    /// Creates the `ChatChannelViewModel`.
    /// - Parameter channel: the channel for which the view model will be created.
    static func makeChannelViewModel(for channel: ChatChannel) -> ChatChannelViewModel {
        let viewModel = ChatChannelViewModel(channel: channel)
        return viewModel
    }
    
    /// Creates the `NewChatViewModel`.
    static func makeNewChatViewModel() -> NewChatViewModel {
        let viewModel = NewChatViewModel()
        return viewModel
    }
    
    /// Creates the view model for the more channel actions.
    ///
    /// - Parameters:
    ///   - channel: the provided channel.
    ///   - actions: list of the channel actions.
    /// - Returns: `MoreChannelActionsViewModel`.
    static func makeMoreChannelActionsViewModel(
        channel: ChatChannel,
        actions: [ChannelAction]
    ) -> MoreChannelActionsViewModel {
        let viewModel = MoreChannelActionsViewModel(
            channel: channel,
            channelActions: actions
        )
        return viewModel
    }
}
