//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
import Nuke
import NukeUI
import StreamChat
import SwiftUI

struct MessageView<Factory: ViewFactory>: View {
    var factory: Factory
    let message: ChatMessage
    var width: CGFloat?
    var onDoubleTap: () -> Void
    
    var body: some View {
        HStack {
            if message.isSentByCurrentUser {
                MessageSpacer(spacerWidth: spacerWidth)
            } else {
                factory.makeMessageAvatarView(for: message.author)
            }
            
            MessageAttachmentView(
                message: message,
                contentWidth: contentWidth
            )
            .onTapGesture(count: 2) {
                onDoubleTap()
            }
//            .overlay(
//                !message.reactionScores.isEmpty ?
//                    ReactionsContainer(message: message) : nil
//            )
            
            if !message.isSentByCurrentUser {
                MessageSpacer(spacerWidth: spacerWidth)
            }
        }
    }
    
    private var contentWidth: CGFloat {
        let padding: CGFloat = 16
        let minimumWidth: CGFloat = 240
        let available = max(minimumWidth, (width ?? 0) - spacerWidth) - padding
        let avatarSize: CGFloat = 40
        let totalWidth = message.isSentByCurrentUser ? available : available - avatarSize
        return totalWidth
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
