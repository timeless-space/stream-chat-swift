//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

public struct ChannelsScreen: View {
    @StateObject private var channelListViewModel: ChannelListViewModel = ChannelListViewModel()
    
    public init() {}
        
    public var body: some View {
        ChannelListView(viewModel: channelListViewModel)
    }
}
