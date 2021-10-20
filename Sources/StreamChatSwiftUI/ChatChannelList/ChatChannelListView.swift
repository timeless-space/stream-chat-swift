//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

/// View for the chat channel list.
public struct ChatChannelListView<Factory: ViewFactory>: View {
    @StateObject private var viewModel: ChatChannelListViewModel
    
    private let viewFactory: Factory
    private let title: String
    private var onItemTap: (ChatChannel) -> Void
    private var channelDestination: (ChatChannel) -> Factory.ChannelDestination
    
    public init(
        viewFactory: Factory,
        title: String = "Stream Chat",
        onItemTap: ((ChatChannel) -> Void)? = nil
    ) {
        let channelListVM = ViewModelsFactory.makeChannelListViewModel()
        _viewModel = StateObject(
            wrappedValue: channelListVM
        )
        self.viewFactory = viewFactory
        self.title = title
        if let onItemTap = onItemTap {
            self.onItemTap = onItemTap
        } else {
            self.onItemTap = { channel in
                channelListVM.selectedChannel = channel
            }
        }
        
        channelDestination = viewFactory.makeDefaultChannelDestination()
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.channels.isEmpty {
                    viewFactory.makeNoChannelsView()
                } else {
                    ZStack {
                        ChannelDeepLink(
                            deeplinkChannel: $viewModel.deeplinkChannel,
                            channelDestination: channelDestination
                        )

                        ChannelList(
                            channels: viewModel.channels,
                            selectedChannel: $viewModel.selectedChannel,
                            onlineIndicatorShown: viewModel.onlineIndicatorShown(for:),
                            imageLoader: viewModel.image(for:),
                            onItemTap: onItemTap,
                            onItemAppear: viewModel.checkForChannels(index:),
                            channelNaming: viewModel.name(forChannel:),
                            channelDestination: channelDestination
                        )
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension ChatChannelListView where Factory == DefaultViewFactory {
    public init() {
        self.init(viewFactory: DefaultViewFactory.shared)
    }
}
