//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamChat
import SwiftUI

public struct ChatChannelView<Factory: ViewFactory>: View, KeyboardReadable {
    @StateObject var viewModel: ChatChannelViewModel
    
    var factory: Factory
    
    var noContentView: Factory.NoContent
    var loadingContentView: Factory.LoadingContent
    
    @Injected(\.streamColors) var colors
    
    public init(
        viewModel: ChatChannelViewModel,
        viewFactory: Factory
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        factory = viewFactory
        noContentView = viewFactory.makeNoContentView()
        loadingContentView = viewFactory.makeLoadingContentView()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if !viewModel.messages.isEmpty {
                MessageListView(
                    viewModel: viewModel,
                    factory: factory
                )
            } else {
                noContentView
            }
            
            Divider()
            
            HStack {
                TextField("Send a message", text: $viewModel.text)
                Spacer()
                Button {
                    viewModel.sendMessage()
                } label: {
                    Text("Send")
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(colors.appBackground.edgesIgnoringSafeArea(.bottom))
    }
}
