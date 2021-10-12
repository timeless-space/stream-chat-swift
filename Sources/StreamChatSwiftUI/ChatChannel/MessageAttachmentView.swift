//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct MessageAttachmentView: View {
    var message: ChatMessage
    var contentWidth: CGFloat
    
    var body: some View {
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
    }
}
