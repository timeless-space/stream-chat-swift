//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import NukeUI
import StreamChat
import SwiftUI

struct ImageAttachmentContainer: View {
    let message: ChatMessage
    let sources: [URL]
    let width: CGFloat
        
    var body: some View {
        if message.text.isEmpty {
            ImageAttachmentView(
                message: message,
                sources: sources,
                width: width
            )
        } else {
            VStack {
                if !sources.isEmpty {
                    ImageAttachmentView(
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

struct ImageAttachmentView: View {
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
        LazyLoadingImage(source: source, width: width)
            .aspectRatio(contentMode: .fit)
    }
}

struct MultiImageView: View {
    let source: URL
    let width: CGFloat
    
    var body: some View {
        LazyLoadingImage(source: source, width: width)
            .frame(width: width)
    }
}

struct LazyLoadingImage: View {
    let source: URL
    let width: CGFloat
    
    var body: some View {
        LazyImage(source: source) { state in
            if let imageContainer = state.imageContainer {
                Image(imageContainer)
            } else if state.error != nil {
                Color(.secondarySystemBackground)
            } else {
                ZStack {
                    Color(.secondarySystemBackground)
                    ProgressView()
                }
            }
        }
        .processors([ImageProcessors.Resize(width: width)])
        .priority(.high)
    }
}
