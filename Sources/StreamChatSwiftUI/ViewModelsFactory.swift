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
    
    static func makeChannelViewModel(for channel: ChatChannel) -> ChatChannelViewModel {
        let viewModel = ChatChannelViewModel(channel: channel)
        return viewModel
    }
}
