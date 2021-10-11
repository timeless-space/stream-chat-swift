//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension InjectedValues {
    var chatClient: ChatClient {
        get {
            streamChat.chatClient
        }
        set {
            streamChat.chatClient = newValue
        }
    }
    
    var streamColors: StreamColors {
        get {
            streamChat.theme.colors
        }
        set {
            streamChat.theme.colors = newValue
        }
    }
    
    var videoPreviewLoader: VideoPreviewLoader {
        get {
            streamChat.videoPreviewLoader
        }
        set {
            streamChat.videoPreviewLoader = newValue
        }
    }
}
