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
            ZStack {
                ChannelDeepLink(
                    deeplinkChannel: $viewModel.deeplinkChannel,
                    channelDestination: channelDestination
                )
                
                ChannelList(
                    channels: viewModel.channels,
                    selectedChannel: $viewModel.selectedChannel,
                    onItemTap: onItemTap,
                    channelNaming: viewModel.name(forChannel:),
                    channelDestination: channelDestination
                )
            }
            .onAppear {
                viewModel.loadChannels()
            }
            .navigationTitle("Stream Chat")
        }
    }
}

public struct ChannelList<ChannelDestination: View>: View {
    var channels: LazyCachedMapCollection<ChatChannel>
    @Binding var selectedChannel: ChatChannel?
    private var onItemTap: (ChatChannel) -> Void
    private var channelNaming: (ChatChannel) -> String
    private var channelDestination: (ChatChannel) -> ChannelDestination
    
    @Injected(\.streamColors) var colors
    
    public init(
        channels: LazyCachedMapCollection<ChatChannel>,
        selectedChannel: Binding<ChatChannel?>,
        onItemTap: @escaping (ChatChannel) -> Void,
        channelNaming: @escaping (ChatChannel) -> String,
        channelDestination: @escaping (ChatChannel) -> ChannelDestination
    ) {
        self.channels = channels
        self.onItemTap = onItemTap
        self.channelNaming = channelNaming
        self.channelDestination = channelDestination
        _selectedChannel = selectedChannel
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(channels) { channel in
                    Button {
                        onItemTap(channel)
                    } label: {
                        HStack {
                            Text(channelNaming(channel))
                            Spacer()
                        }
                        .padding()
                    }
                    .foregroundColor(.black)
                                            
                    NavigationLink(tag: channel, selection: $selectedChannel) {
                        channelDestination(channel)
                    } label: {
                        EmptyView()
                    }
                }
            }
            .background(colors.appBackground)
        }
    }
}

public struct ChannelDeepLink<ChannelDestination: View>: View {
    private var channelDestination: (ChatChannel) -> ChannelDestination
    @Binding var deeplinkChannel: ChatChannel?
    
    public init(
        deeplinkChannel: Binding<ChatChannel?>,
        channelDestination: @escaping (ChatChannel) -> ChannelDestination
    ) {
        self.channelDestination = channelDestination
        _deeplinkChannel = deeplinkChannel
    }
    
    public var body: some View {
        if let deeplinkChannel = deeplinkChannel {
            NavigationLink(tag: deeplinkChannel, selection: $deeplinkChannel) {
                channelDestination(deeplinkChannel)
            } label: {
                EmptyView()
            }
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
