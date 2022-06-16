//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import Lottie

open class ChatMessageReactionItemView: _View, AppearanceProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }
    var animatedEmojiView: AnimationView?
    var messageReactionButton: UILabel?

    // MARK: - Overrides
    override open func setUp() {
        super.setUp()
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }

    override open func setUpLayout() {
        super.setUpLayout()
        messageReactionButton?.removeFromSuperview()
        messageReactionButton = UILabel()
        addSubview(messageReactionButton!)
        animatedEmojiView?.removeFromSuperview()
        animatedEmojiView = AnimationView()
        addSubview(animatedEmojiView!)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = content else { return }

        guard let reactions = appearance.images.availableReactions[content.reaction.type] else {
            return
        }

        if content.useAnimatedIcon {
            addAnimatedView(animationName: reactions.emojiAnimated)
        } else {
            addReactionView(titleString: reactions.emojiString)
        }
        isUserInteractionEnabled = content.onTap != nil
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()

        updateContentIfNeeded()
    }

    // MARK: - Actions
    func addAnimatedView(animationName: String) {
        backgroundColor = reactionImageTint
        layer.cornerRadius = 20
        animatedEmojiView?.animation = Animation.named(animationName)
        animatedEmojiView?.loopMode = .loop
        animatedEmojiView?.play()
        animatedEmojiView?.translatesAutoresizingMaskIntoConstraints = false
        animatedEmojiView?.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        animatedEmojiView?.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        animatedEmojiView?.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        animatedEmojiView?.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        animatedEmojiView?.widthAnchor.constraint(equalToConstant: 40).isActive = true
        animatedEmojiView?.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    func addReactionView(titleString: String) {
        messageReactionButton?.text = titleString
        messageReactionButton?.font = UIFont.systemFont(ofSize: 20)
        messageReactionButton?.translatesAutoresizingMaskIntoConstraints = false
        messageReactionButton?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        messageReactionButton?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        messageReactionButton?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        messageReactionButton?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        messageReactionButton?.widthAnchor.constraint(equalToConstant: 25).isActive = true
        messageReactionButton?.heightAnchor.constraint(equalToConstant: 22).isActive = true
    }

    @objc open func handleTap() {
        guard let content = self.content else { return }
        content.onTap?(content.reaction.type)
    }
}

// MARK: - Content
extension ChatMessageReactionItemView {
    public struct Content {
        public let useAnimatedIcon: Bool
        public let reaction: ChatMessageReactionData
        public var onTap: ((MessageReactionType) -> Void)?

        public init(
            useAnimatedIcon: Bool,
            reaction: ChatMessageReactionData,
            onTap: ((MessageReactionType) -> Void)?
        ) {
            self.useAnimatedIcon = useAnimatedIcon
            self.reaction = reaction
            self.onTap = onTap
        }
    }
}

// MARK: - Private
private extension ChatMessageReactionItemView {
    var reactionImage: String? {
        guard let content = content else { return nil }
        let reactions = appearance.images.availableReactions[content.reaction.type]
        return content.useAnimatedIcon ?
            reactions?.emojiAnimated :
            reactions?.emojiString
    }

    var reactionImageTint: UIColor? {
        guard let content = content else { return nil }
        return content.reaction.isChosenByCurrentUser ?
            .clear:
            .clear
    }
}
