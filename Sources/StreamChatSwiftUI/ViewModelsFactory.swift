//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Factory used to create view models.
class ViewModelsFactory {
    private init() {}
    
    /// Creates the `ChannelListViewModel`.
    static func makeChannelListViewModel() -> ChatChannelListViewModel {
        ChatChannelListViewModel()
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
}
