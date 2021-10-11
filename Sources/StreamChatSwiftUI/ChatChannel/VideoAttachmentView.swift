//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import SwiftUI

public struct VideoAttachmentsContainer: View {
    let message: ChatMessage
    let width: CGFloat
    
    public var body: some View {
        VStack {
            ForEach(message.videoAttachments, id: \.self) { attachment in
                VideoAttachmentView(videoURL: attachment.videoURL, width: width)
            }
        }
    }
}

public struct VideoAttachmentView: View {
    @Injected(\.videoPreviewLoader) var videoPreviewLoader
    
    let videoURL: URL
    let width: CGFloat
    
    @State var previewImage: UIImage?
                
    public var body: some View {
        ZStack {
            if let previewImage = previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray
            }
            
            Button {
                // TODO: implement video tap
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
        .frame(width: width)
        .aspectRatio(4 / 3, contentMode: .fit)
        .cornerRadius(24)
        .onAppear {
            videoPreviewLoader.loadPreviewForVideo(at: videoURL) { result in
                switch result {
                case let .success(image):
                    self.previewImage = image
                case .failure:
                    self.previewImage = nil
                }
            }
        }
        .cornerRadius(24)
    }
}
