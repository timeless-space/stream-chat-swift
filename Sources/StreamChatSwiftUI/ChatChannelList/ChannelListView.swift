//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

public struct ChannelListView<ChannelDestination: View>: View {
    @StateObject private var viewModel: ChannelListViewModel
    
    private var onItemTap: (ChatChannel) -> Void
    
    private var channelDestination: (ChatChannel) -> ChannelDestination
    
    @Environment(\.chatTheme) var chatTheme
    
    public init(
        viewModel: ChannelListViewModel,
        onItemTap: ((ChatChannel) -> Void)? = nil,
        channelDestination: @escaping ((ChatChannel) -> ChannelDestination)
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        if let onItemTap = onItemTap {
            self.onItemTap = onItemTap
        } else {
            self.onItemTap = { channel in
                viewModel.selectedChannel = channel
            }
        }
        
        self.channelDestination = channelDestination
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.channels) { channel in
                        Button {
                            onItemTap(channel)
                        } label: {
                            HStack {
                                Text(viewModel.name(forChannel: channel))
                                Spacer()
                            }
                            .padding()
                        }
                        .foregroundColor(.black)
                                                
                        NavigationLink(tag: channel, selection: $viewModel.selectedChannel) {
                            channelDestination(channel)
                        } label: {
                            EmptyView()
                        }
                    }
                }
                .background(chatTheme.colors.appBackground)
            }
            .onAppear {
                viewModel.loadChannels()
            }
            .navigationTitle("Stream Chat")
        }
    }
}

extension ChannelListView where ChannelDestination == ChatChannelView<NoContentView> {
    public init(viewModel: ChannelListViewModel, onItemTap: ((ChatChannel) -> Void)? = nil) {
        self.init(viewModel: viewModel, onItemTap: onItemTap, channelDestination: { channel in
            ChatChannelView(viewModel: viewModel.makeViewModel(for: channel))
        })
    }
}
