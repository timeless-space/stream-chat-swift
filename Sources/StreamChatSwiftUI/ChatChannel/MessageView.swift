//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
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
                ImageAttachmentContainer(message: message, sources: message.imageAttachments.map { attachment in
                    attachment.imagePreviewURL
                }, width: contentWidth)
            } else if !message.giphyAttachments.isEmpty {
                ImageAttachmentContainer(message: message, sources: message.giphyAttachments.map { attachment in
                    attachment.previewURL
                }, width: contentWidth)
            } else if !message.videoAttachments.isEmpty {
                VideoAttachmentsContainer(message: message, width: contentWidth)
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

struct MessageSpacer: View {
    var spacerWidth: CGFloat?
    
    var body: some View {
        Spacer()
            .frame(minWidth: spacerWidth)
            .layoutPriority(-1)
    }
}
