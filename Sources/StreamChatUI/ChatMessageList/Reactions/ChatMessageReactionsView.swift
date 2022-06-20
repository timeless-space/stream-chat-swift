//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import Lottie

/// The view that shows the list of reactions attached to the message.
open class ChatMessageReactionsView: _View, ThemeProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    open var reactionItemView: ChatMessageReactionItemView.Type {
        components.messageReactionItemView
    }

    /// The sorting order of how the reactions data will be displayed.
    open var reactionsSorting: ((ChatMessageReactionData, ChatMessageReactionData) -> Bool) {
        components.reactionsSorting
    }

    // MARK: - Subviews

    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack.withoutAutoresizingMaskConstraints
    }()

    public var isThreadInReaction = false
    // MARK: - Overrides

    override open func setUpLayout() {
        embed(stackView)
    }

    override open func updateContent() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        guard let content = content else { return }

        content.reactions.forEach { reaction in
            if appearance.images.availableReactions[reaction.type] == nil {
                logWarning(unavailableReaction: reaction)
                return
            }
            let itemView = reactionItemView.init()
            itemView.content = .init(
                useAnimatedIcon: content.useAnimatedIcons,
                reaction: reaction,
                onTap: content.didTapOnReaction
            )
            itemView.translatesAutoresizingMaskIntoConstraints = false
            itemView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
            itemView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
            itemView.alpha = isThreadInReaction ? 1 : 0
            stackView.addArrangedSubview(itemView)
        }
        guard !isThreadInReaction else {
            return
        }
        // Adding animation for reaction items
        for (i,view) in stackView.subviews.enumerated() {
            let duration = TimeInterval(i+1)/15
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                UIView.animate(withDuration: duration, delay: 0.1, options: .showHideTransitionViews, animations: { [weak self] in
                    view.alpha = 1
                    view.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
                }, completion: { [weak self] _ in
                    UIView.animate(withDuration: duration, animations: {
                        view.transform = CGAffineTransform.identity
                    })
                })
            }
        }
    }

    private func logWarning(unavailableReaction reaction: ChatMessageReactionData) {
        log.warning(
            "reaction with type \(reaction.type) is not registered in appearance.images.availableReactions, skipping"
        )
    }
}

// MARK: - Content

extension ChatMessageReactionsView {
    public struct Content {
        public let useAnimatedIcons: Bool
        public let reactions: [ChatMessageReactionData]
        public let didTapOnReaction: ((MessageReactionType) -> Void)?

        public init(
            useAnimatedIcons: Bool,
            reactions: [ChatMessageReactionData],
            didTapOnReaction: ((MessageReactionType) -> Void)?
        ) {
            self.useAnimatedIcons = useAnimatedIcons
            self.reactions = reactions
            self.didTapOnReaction = didTapOnReaction
        }
    }
}
