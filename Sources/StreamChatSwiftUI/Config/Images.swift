//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

public class Images {
    public init() {}
    
    // MARK: - Reactions

    public var reactionLoveSmall: UIImage = UIImage(named: "reaction_love_small", in: .streamChatUI)!
    public var reactionLoveBig: UIImage = UIImage(named: "reaction_love_big", in: .streamChatUI)!
    public var reactionLolSmall: UIImage = UIImage(named: "reaction_lol_small", in: .streamChatUI)!
    public var reactionLolBig: UIImage = UIImage(named: "reaction_lol_big", in: .streamChatUI)!
    public var reactionThumgsUpSmall: UIImage = UIImage(named: "reaction_thumbsup_small", in: .streamChatUI)!
    public var reactionThumgsUpBig: UIImage = UIImage(named: "reaction_thumbsup_big", in: .streamChatUI)!
    public var reactionThumgsDownSmall: UIImage = UIImage(named: "reaction_thumbsdown_small", in: .streamChatUI)!
    public var reactionThumgsDownBig: UIImage = UIImage(named: "reaction_thumbsdown_big", in: .streamChatUI)!
    public var reactionWutSmall: UIImage = UIImage(named: "reaction_wut_small", in: .streamChatUI)!
    public var reactionWutBig: UIImage = UIImage(named: "reaction_wut_big", in: .streamChatUI)!

    private var _availableReactions: [MessageReactionType: ChatMessageReactionAppearanceType]?
    public var availableReactions: [MessageReactionType: ChatMessageReactionAppearanceType] {
        get {
            _availableReactions ??
                [
                    .init(rawValue: "love"): ChatMessageReactionAppearance(
                        smallIcon: reactionLoveSmall,
                        largeIcon: reactionLoveBig
                    ),
                    .init(rawValue: "haha"): ChatMessageReactionAppearance(
                        smallIcon: reactionLolSmall,
                        largeIcon: reactionLolBig
                    ),
                    .init(rawValue: "like"): ChatMessageReactionAppearance(
                        smallIcon: reactionThumgsUpSmall,
                        largeIcon: reactionThumgsUpBig
                    ),
                    .init(rawValue: "sad"): ChatMessageReactionAppearance(
                        smallIcon: reactionThumgsDownSmall,
                        largeIcon: reactionThumgsDownBig
                    ),
                    .init(rawValue: "wow"): ChatMessageReactionAppearance(
                        smallIcon: reactionWutSmall,
                        largeIcon: reactionWutBig
                    )
                ]
        }
        set { _availableReactions = newValue }
    }
}

extension UIImage {
    convenience init?(named name: String, in bundle: Bundle) {
        self.init(named: name, in: bundle, compatibleWith: nil)
    }
}
