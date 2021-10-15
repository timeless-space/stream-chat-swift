//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Factory used to create view models.
class ViewModelsFactory {
    /// Creates the `ChannelListViewModel`.
    static func makeChannelListViewModel() -> ChatChannelListViewModel {
        ChatChannelListViewModel()
    }
}
