//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import NukeUI

public struct ChatChannelAnyView: View, KeyboardReadable {
    
    @StateObject var viewModel: ChatChannelAnyViewModel
    
    @Environment(\.components) var components
    
    public init(viewModel: ChatChannelAnyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.channel.messages.count > 0 {
                MessageListAnyView(viewModel: viewModel)
            } else {
                components.messageComponents.noContentView
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
    }
}

struct MessageAnyView: View {
    
    let message: ChatMessage
    var spacerWidth: CGFloat?
    
    var body: some View {
        HStack {
            if message.isSentByCurrentUser {
                MessageAnySpacer(spacerWidth: spacerWidth)
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
            
            if message.imageAttachments.count > 0 {
                if message.text.isEmpty {
                    LazyImage(source: message.imageAttachments[0].imagePreviewURL)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                } else {
                    VStack {
                        if message.imageAttachments.count > 0 {
                            LazyImage(source: message.imageAttachments[0].imagePreviewURL)
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(24)
                        }

                        Text(message.text)
                    }
                    .padding()
                    .background(message.isSentByCurrentUser ?
                                Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3))
                    .cornerRadius(24)
                }
            } else {
                Text(message.text)
                    .padding()
                    .background(message.isSentByCurrentUser ?
                                Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3))
                    .cornerRadius(24)
            }
            
            if !message.isSentByCurrentUser {
                MessageSpacer(spacerWidth: spacerWidth)
            }
        }
    }
    
}

struct MessageAnySpacer: View {
    
    var spacerWidth: CGFloat?
    
    var body: some View {
        Spacer()
            .frame(minWidth: spacerWidth)
            .layoutPriority(-1)
    }

}
