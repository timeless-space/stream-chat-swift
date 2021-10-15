//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// View model for the `ChatChannelListView`.
public class ChatChannelListViewModel: ObservableObject {
    @Published var channels = [ChatChannel]()
}
