//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct ReactionsContainer: View {
    let message: ChatMessage
    
    var body: some View {
        VStack {
            HStack {
                if !message.isSentByCurrentUser {
                    Spacer()
                }
                
                ReactionsView(message: message)
                
                if message.isSentByCurrentUser {
                    Spacer()
                }
            }
            
            Spacer()
        }
        .offset(x: message.isSentByCurrentUser ? -16 : 16, y: -16)
    }
}

struct ReactionsView: View {
    let message: ChatMessage
    
    @Injected(\.images) var images
    
    var body: some View {
        HStack {
            ForEach(reactions) { reaction in
                if let image = iconProvider(for: reaction) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20)
                }
            }
        }
        .padding(.all, 6)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
    
    var reactions: [MessageReactionType] {
        message.reactionScores.keys.filter { reactionType in
            (message.reactionScores[reactionType] ?? 0) > 0
        }
    }
    
    func iconProvider(for reaction: MessageReactionType) -> UIImage? {
        images.availableReactions[reaction]?.smallIcon
    }
}

extension MessageReactionType: Identifiable {
    public var id: String {
        rawValue
    }
}
