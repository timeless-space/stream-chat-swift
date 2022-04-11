//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import Lottie

open class ChatMessageReactionsView: _View, ThemeProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    open var reactionItemView: ChatMessageReactionItemView.Type {
        components.messageReactionItemView
    }

    // returns the selection of reactions that should be rendered by this view
    open var reactions: [ChatMessageReactionData] {
        guard let content = content else { return [] }
        return content.reactions.filter { reaction in
            guard appearance.images.availableReactions[reaction.type] != nil else {
                log
                    .warning(
                        "reaction with type \(reaction.type) is not registered in appearance.images.availableReactions, skipping"
                    )
                return false
            }
            return true
        }
    }

    // MARK: - Subviews

    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 15
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
        if isThreadInReaction {
            stackView.spacing = UIStackView.spacingUseSystem
        }
        guard let content = content else { return }
        content.reactions.forEach { reaction in
            if appearance.images.availableReactions[reaction.type] == nil {
                log
                    .warning(
                        "reaction with type \(reaction.type) is not registered in appearance.images.availableReactions, skipping"
                    )
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
//            let itemViewSize: CGFloat = isThreadInReaction ? 20 : 30
//            itemView.widthAnchor.constraint(equalToConstant: itemViewSize).isActive = true
//            itemView.heightAnchor.constraint(equalToConstant: itemViewSize).isActive = true

            self.stackView.addArrangedSubview(itemView)
        }
        guard !isThreadInReaction else {
            return
        }
        // Adding animation for reaction items
        for (i,view) in stackView.subviews.enumerated() {
            let duration = TimeInterval(i+1)/15
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                UIView.animate(withDuration: duration, delay: 0, options: .showHideTransitionViews, animations: { [weak self] in
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
