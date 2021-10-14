//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension InjectedValues {
    public var chatClient: ChatClient {
        get {
            streamChat.chatClient
        }
        set {
            streamChat.chatClient = newValue
        }
    }
    
    public var streamColors: StreamColors {
        get {
            streamChat.theme.colors
        }
        set {
            streamChat.theme.colors = newValue
        }
    }
    
    public var videoPreviewLoader: VideoPreviewLoader {
        get {
            streamChat.videoPreviewLoader
        }
        set {
            streamChat.videoPreviewLoader = newValue
        }
    }
    
    public var images: Images {
        get {
            streamChat.theme.images
        }
        set {
            streamChat.theme.images = newValue
        }
    }
}
