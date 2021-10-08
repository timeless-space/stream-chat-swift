//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

public struct ChannelsScreen: View {
    @StateObject private var channelListViewModel: ChannelListViewModel
    
    public init(selectedChannelId: String? = nil) {
        let viewModel = ChannelListViewModel(selectedChannelId: selectedChannelId)
        _channelListViewModel = StateObject(wrappedValue: viewModel)
    }
        
    public var body: some View {
        ChannelListView(viewModel: channelListViewModel)
    }
}
