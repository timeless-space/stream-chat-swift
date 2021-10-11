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
        let padding: CGFloat = 16
        let available = max(100, (width ?? 0) - spacerWidth) - padding
        let avatarSize: CGFloat = 40
        return message.isSentByCurrentUser ? available : available - avatarSize
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
            MediaAttachmentView(
                message: message,
                sources: sources,
                width: width
            )
        } else {
            VStack {
                if !sources.isEmpty {
                    MediaAttachmentView(
                        message: message,
                        sources: sources,
                        width: width
                    )
                }

                Text(message.text)
                    .padding(.bottom)
            }
            .background(
                message.isSentByCurrentUser ?
                    Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3)
            )
            .cornerRadius(24)
        }
    }
}

struct MediaAttachmentView: View {
    let message: ChatMessage
    let sources: [URL]
    let width: CGFloat
    
    private let spacing: CGFloat = 2
    
    var body: some View {
        Group {
            if sources.count == 1 {
                SingleImageView(
                    source: sources[0],
                    width: width
                )
            } else if sources.count == 2 {
                HStack(spacing: spacing) {
                    MultiImageView(
                        source: sources[0],
                        width: width / 2
                    )
                    
                    MultiImageView(
                        source: sources[1],
                        width: width / 2
                    )
                }
                .aspectRatio(1, contentMode: .fill)
            } else if sources.count == 3 {
                HStack(spacing: spacing) {
                    MultiImageView(
                        source: sources[0],
                        width: width / 2
                    )
                    
                    VStack(spacing: spacing) {
                        MultiImageView(
                            source: sources[1],
                            width: width / 2
                        )
                        MultiImageView(
                            source: sources[2],
                            width: width / 2
                        )
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            } else if sources.count > 3 {
                HStack(spacing: spacing) {
                    VStack(spacing: spacing) {
                        MultiImageView(
                            source: sources[0],
                            width: width / 2
                        )
                        MultiImageView(
                            source: sources[1],
                            width: width / 2
                        )
                    }
                    
                    VStack(spacing: spacing) {
                        MultiImageView(
                            source: sources[2],
                            width: width / 2
                        )
                        MultiImageView(
                            source: sources[3],
                            width: width / 2
                        )
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
        }
        .frame(maxWidth: width)
        .clipped()
        .cornerRadius(24)
    }
}

struct SingleImageView: View {
    let source: URL
    let width: CGFloat
    
    var body: some View {
        LazyImage(source: source)
            .processors([ImageProcessors.Resize(width: width)])
            .priority(.high)
            .aspectRatio(contentMode: .fit)
    }
}

struct MultiImageView: View {
    let source: URL
    let width: CGFloat
    
    var body: some View {
        LazyImage(source: source)
            .processors([ImageProcessors.Resize(width: width)])
            .priority(.high)
            .frame(width: width)
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
