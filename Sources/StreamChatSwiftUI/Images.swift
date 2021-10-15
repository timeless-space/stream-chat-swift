//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// Provides access to the images used in the SDK.
public class Images {
    public init() {}
    
    /// A private internal function that will safely load an image from the bundle or return a circle image as backup
    /// - Parameter imageName: The required image name to load from the bundle
    /// - Returns: A UIImage that is either the correct image from the bundle or backup circular image
    private static func loadImageSafely(with imageName: String) -> UIImage {
        if let image = UIImage(named: imageName, in: .streamChatUI) {
            return image
        } else {
            log.error(
                """
                \(imageName) image has failed to load from the bundle please make sure it's included in your assets folder.
                A default 'red' circle image has been added.
                """
            )
            return UIImage.circleImage
        }
    }
    
    // MARK: - Reactions

    public var reactionLoveSmall: UIImage = loadImageSafely(with: "reaction_love_small")
    public var reactionLoveBig: UIImage = loadImageSafely(with: "reaction_love_big")
    public var reactionLolSmall: UIImage = loadImageSafely(with: "reaction_lol_small")
    public var reactionLolBig: UIImage = loadImageSafely(with: "reaction_lol_big")
    public var reactionThumgsUpSmall: UIImage = loadImageSafely(with: "reaction_thumbsup_small")
    public var reactionThumgsUpBig: UIImage = loadImageSafely(with: "reaction_thumbsup_big")
    public var reactionThumgsDownSmall: UIImage = loadImageSafely(with: "reaction_thumbsdown_small")
    public var reactionThumgsDownBig: UIImage = loadImageSafely(with: "reaction_thumbsdown_big")
    public var reactionWutSmall: UIImage = loadImageSafely(with: "reaction_wut_small")
    public var reactionWutBig: UIImage = loadImageSafely(with: "reaction_wut_big")

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
