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
            if !viewModel.channelController.messages.isEmpty {
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

struct MessageView: View {
    let message: ChatMessage
    var spacerWidth: CGFloat?
    
    var body: some View {
        HStack {
            if message.isSentByCurrentUser {
                MessageSpacer(spacerWidth: spacerWidth)
            } else {
                if let url = message.author.imageURL?.absoluteString {
                    LazyImage(source: url)
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
            }
            
            if !message.imageAttachments.isEmpty {
                if message.text.isEmpty {
                    LazyImage(source: message.imageAttachments[0].imagePreviewURL)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                } else {
                    VStack {
                        if !message.imageAttachments.isEmpty {
                            LazyImage(source: message.imageAttachments[0].imagePreviewURL)
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(24)
                        }

                        Text(message.text)
                    }
                    .padding()
                    .background(
                        message.isSentByCurrentUser ?
                            Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3)
                    )
                    .cornerRadius(24)
                }
            } else {
                Text(message.text)
                    .padding()
                    .background(
                        message.isSentByCurrentUser ?
                            Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3)
                    )
                    .cornerRadius(24)
            }
            
            if !message.isSentByCurrentUser {
                MessageSpacer(spacerWidth: spacerWidth)
            }
        }
    }
}

struct MessageSpacer: View {
    var spacerWidth: CGFloat?
    
    var body: some View {
        Spacer()
            .frame(minWidth: spacerWidth)
            .layoutPriority(-1)
    }
}

extension ChatChannelView where NoContent == NoContentView {
    public init(viewModel: ChatChannelViewModel) {
        self.init(viewModel: viewModel, noContentView: NoContentView())
    }
}
