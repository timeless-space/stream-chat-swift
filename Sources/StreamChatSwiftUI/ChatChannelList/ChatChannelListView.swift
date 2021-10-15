//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// View for the chat channel list.
public struct ChatChannelListView<Factory: ViewFactory>: View {
    @StateObject private var viewModel: ChatChannelListViewModel
    
    private let viewFactory: Factory
    private let title: String
    
    public init(viewFactory: Factory, title: String = "Stream Chat") {
        _viewModel = StateObject(
            wrappedValue: ViewModelsFactory.makeChannelListViewModel()
        )
        self.viewFactory = viewFactory
        self.title = title
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.channels.isEmpty {
                    viewFactory.makeNoChannelsView()
                } else {
                    Text("channel list")
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
