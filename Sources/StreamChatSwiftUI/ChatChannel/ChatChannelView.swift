//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

/// View for the chat channel.
public struct ChatChannelView<Factory: ViewFactory>: View {
    @StateObject private var viewModel: ChatChannelViewModel
    
    private var factory: Factory
    
    public init(
        viewFactory: Factory,
        channelController: ChatChannelController
    ) {
        _viewModel = StateObject(
            wrappedValue: ViewModelsFactory.makeChannelViewModel(with: channelController)
        )
        factory = viewFactory
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            MessageListView(
                factory: factory,
                messages: $viewModel.messages,
                scrolledId: $viewModel.scrolledId,
                showScrollToLatestButton: $viewModel.showScrollToLatestButton,
                currentDateString: $viewModel.currentDateString,
                onMessageAppear: viewModel.handleMessageAppear(index:),
                onScrollToBottom: viewModel.scrollToLastMessage
            )
            .onAppear {
                viewModel.subscribeToChannelChanges()
            }
        }
        .modifier(factory.makeChannelHeaderViewModifier(for: viewModel.channel))
    }
}
