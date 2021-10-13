//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamChat
import SwiftUI

public struct ChatChannelView<NoContent: View>: View, KeyboardReadable {
    @StateObject var viewModel: ChatChannelViewModel
    
    var noContentView: NoContent
    
    @Injected(\.streamColors) var colors
    
    public init(viewModel: ChatChannelViewModel, noContentView: NoContent) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.noContentView = noContentView
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if !viewModel.messages.isEmpty {
                MessageListView(viewModel: viewModel)
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

extension ChatChannelView where NoContent == NoContentView {
    public init(viewModel: ChatChannelViewModel) {
        self.init(viewModel: viewModel, noContentView: NoContentView())
    }
}
