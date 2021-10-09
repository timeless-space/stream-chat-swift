//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import NukeUI
import StreamChat
import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    var width: CGFloat?
    
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
            
            // TODO: temporary logic
            if !message.imageAttachments.isEmpty {
                MediaAttachmentsView(message: message, sources: message.imageAttachments.map { attachment in
                    attachment.imagePreviewURL
                }, width: contentWidth)
            } else if !message.giphyAttachments.isEmpty {
                MediaAttachmentsView(message: message, sources: message.giphyAttachments.map { attachment in
                    attachment.previewURL
                }, width: contentWidth)
            } else if !message.videoAttachments.isEmpty {
                MediaAttachmentsView(message: message, sources: message.videoAttachments.map { attachment in
                    attachment.videoURL
                }, width: contentWidth)
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
    
    private var contentWidth: CGFloat {
        max(100, (width ?? 0) - spacerWidth)
    }
    
    private var spacerWidth: CGFloat {
        (width ?? 0) / 4
    }
}

struct MediaAttachmentsView: View {
    let message: ChatMessage
    let sources: [URL]
    let width: CGFloat
    
    var body: some View {
        if message.text.isEmpty {
            LazyImage(source: sources[0])
                .processors([ImageProcessors.Resize(width: width)])
                .priority(.high)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(24)
        } else {
            VStack {
                if !sources.isEmpty {
                    LazyImage(source: sources[0])
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
