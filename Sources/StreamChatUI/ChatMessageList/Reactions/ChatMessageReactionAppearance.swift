//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The type describing message reaction appearance.
public protocol ChatMessageReactionAppearanceType {
    var emojiAnimated: String { get }
    var emojiString: String { get }
}

/// The default `ReactionAppearanceType` implementation without any additional data
/// which can be used to provide custom icons for message reaction.
public struct ChatMessageReactionAppearance: ChatMessageReactionAppearanceType {
    public let emojiAnimated: String
    public let emojiString: String
    
    public init(
        emojiAnimated: String,
        emojiString: String
    ) {
        self.emojiAnimated = emojiAnimated
        self.emojiString = emojiString
    }
}
