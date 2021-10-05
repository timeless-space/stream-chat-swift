//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat

public struct ChannelsScreen: View {
    
    @StateObject var channelListViewModel: ChannelListViewModel
    
    public init(chatClient: ChatClient) {
        _channelListViewModel = StateObject(
            wrappedValue: ChannelListViewModel(chatClient: chatClient)
        )
    }
        
    public var body: some View {
        ChannelListView(viewModel: channelListViewModel)
    }
}
