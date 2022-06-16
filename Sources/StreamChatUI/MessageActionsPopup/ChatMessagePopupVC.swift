//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `_ChatMessagePopupVC` is shown when user long-presses a message.
/// By default, it has a blurred background, reactions, and actions which are shown for a given message
/// and with which user can interact.
open class ChatMessagePopupVC: _ViewController, ComponentsProvider {
    /// `ContainerStackView` encapsulating underlying views `reactionsController`, `actionsController` and `messageContentView`.
    open private(set) lazy var messageContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    /// `UIView` with `UIBlurEffect` that is shown as a background.
    open private(set) lazy var blurView: UIView = {
        let blur: UIBlurEffect
        if #available(iOS 13.0, *) {
            blur = UIBlurEffect(style: .systemMaterial)
        } else {
            blur = UIBlurEffect(style: .regular)
        }
        return UIVisualEffectView(effect: blur)
            .withoutAutoresizingMaskConstraints
    }()
    /// Container view that holds `messageContentView`.
    open private(set) lazy var messageContentContainerView = UIView()
        .withoutAutoresizingMaskConstraints
    //
    open private(set) lazy var scrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints
    /// Insets for `messageContentView`'s bubble view.
    public var messageBubbleViewInsets: UIEdgeInsets = .zero
    /// `messageContentView` being displayed.
    public var messageContentView: ChatMessageContentView!
    /// Message data that is shown.
    public var message: ChatMessage { messageContentView.content! }
    /// Initial frame of a message.
    public var messageViewFrame: CGRect!
    /// `_ChatMessageActionsVC` instance for showing actions.
    public var actionsController: ChatMessageActionsVC?
    /// `_ChatMessageReactionsVC` instance for showing reactions.
    public var reactionsController: ChatMessageReactionsVC?
    /// `ChatMessageReactionAuthorsVC` instance for showing the authors of the reactions.
    public var reactionAuthorsController: ChatMessageReactionAuthorsVC?
    /// empty padding view
    private lazy var spacingView = UIView()
    /// reactionViewFrame
    public var reactionViewFrame: CGRect = .zero
    /// extra message content view padding
    public var messageContentViewPadding: CGFloat = 0
    /// messageContentYPosition
    public var messageContentYPosition: CGFloat = 0
    /// actionMenuMaxHeight
    private var actionMenuMaxHeight: CGFloat {
        return CGFloat(actionsController?.messageActions.count ?? 0 * 50)
    }
    /// actionMenuMaxHeight
    private var topPadding: CGFloat {
        return (UIView.safeAreaTop + 50)
    }
    /// The height of the reactions author view. By default it depends on the number of total reactions.
    open var reactionAuthorsViewHeight: CGFloat {
        message.totalReactionsCount > 4 ? 320 : 180
    }

    /// The width percentage of the reactions author view in relation with the popup's width.
    /// By default it depends on the number of total reactions.
    open var reactionAuthorsViewWidthMultiplier: CGFloat {
        message.totalReactionsCount >= 4 ? 0.90 : 0.75
    }

    override open func setUp() {
        super.setUp()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnView))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        view.backgroundColor = .clear
    }

    override open func setUpLayout() {
        guard messageViewFrame != nil else { return }
        view.embed(blurView)
        view.embed(scrollView)
        setupUI(contentView: scrollView)
        actionsController?.updateContent()
        scrollToBottom()
    }

    private func scrollToBottom()  {
        let contentSizeHeight = (abs(messageContentView.frame.origin.y)
                                 + messageContentView.frame.height
                                 + actionMenuMaxHeight
                                 + messageContentViewPadding
                                 + reactionAuthorsViewHeight)
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width,
                                        height: contentSizeHeight)
        let point = CGPoint(x: 0, y: scrollView.contentSize.height
                            - UIScreen.main.bounds.height)
        if point.y >= 0 {
            scrollView.setContentOffset(point, animated: false)
        }
        scrollView.isScrollEnabled = isScrollEnable()
    }

    private func isScrollEnable() -> Bool {
        return ((messageContentView.frame.height
                + actionMenuMaxHeight)
                > UIScreen.main.bounds.height)
    }

    private func setupUI(contentView: UIView) {

        messageContainerStackView.axis = .vertical
        messageContainerStackView.spacing = 0
        contentView.addSubview(messageContainerStackView)

        var constraints: [NSLayoutConstraint] = [
            messageContainerStackView.leadingAnchor.pin(greaterThanOrEqualTo: contentView.leadingAnchor),
            messageContainerStackView.trailingAnchor.pin(lessThanOrEqualTo: contentView.trailingAnchor),
            messageContainerStackView.bottomAnchor.pin(lessThanOrEqualTo: contentView.bottomAnchor),
            messageContainerStackView.topAnchor.pin(greaterThanOrEqualTo: contentView.topAnchor)
        ]

        if let reactionsController = reactionsController {
            addChildViewController(reactionsController, targetView: view)
            if message.isSentByCurrentUser {
                constraints += [
                    reactionsController.view.trailingAnchor
                        .pin(lessThanOrEqualTo: view.trailingAnchor, constant: -messageBubbleViewInsets.right),
                    reactionsController.reactionsBubble.tailTrailingAnchor
                        .pin(equalTo: view.leadingAnchor, constant: messageBubbleViewInsets.left),
                    reactionsController.view.leadingAnchor
                        .pin(greaterThanOrEqualTo: view.leadingAnchor),
                ]
            } else {
                constraints += [
                    // added leadingAnchor
                    reactionsController.view.trailingAnchor
                        .pin(lessThanOrEqualTo: view.trailingAnchor),
                    reactionsController.reactionsBubble.tailLeadingAnchor
                        .pin(equalTo: view.trailingAnchor, constant: -messageBubbleViewInsets.right),
                    reactionsController.view.leadingAnchor
                        .pin(greaterThanOrEqualTo: view.leadingAnchor, constant: messageBubbleViewInsets.left),
                ]
            }
            let reactionViewTop = (reactionViewFrame.height > 0
                                   ? messageContentViewPadding
                                   - (reactionViewFrame.height - messageContentYPosition)
                                   : messageContentViewPadding)

            if isScrollEnable() {
                constraints += [
                    reactionsController.view.topAnchor.constraint(
                        equalTo: view.topAnchor,
                        constant: reactionViewTop),
                ]
            } else {
                constraints += [
                    reactionsController.view.bottomAnchor.constraint(
                        equalTo: messageContainerStackView.topAnchor,
                        constant: reactionViewTop)
                ]
            }
        }

        spacingView.translatesAutoresizingMaskIntoConstraints = false
        if let timeStampLabel = messageContentView.timestampLabel {
            constraints.append(
                spacingView.heightAnchor.constraint(equalToConstant: 5)
            )
        } else {
            constraints.append(
                spacingView.heightAnchor.constraint(equalToConstant: 12)
            )
        }

        messageContainerStackView.addArrangedSubview(messageContentContainerView)
        messageContainerStackView.addArrangedSubview(spacingView)

        constraints += [
            messageContentContainerView.widthAnchor.pin(equalToConstant: messageViewFrame.width),
            messageContentContainerView.heightAnchor.pin(equalToConstant: messageViewFrame.height)
        ]

        layoutActionController(&constraints)

        if message.isSentByCurrentUser {
            messageContainerStackView.alignment = .trailing
            constraints.append(
                messageContainerStackView.trailingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.maxX
                )
            )
        } else {
            messageContainerStackView.alignment = .leading
            constraints.append(
                messageContainerStackView.leadingAnchor.pin(
                    equalTo: contentView.leadingAnchor,
                    constant: messageViewFrame.minX
                )
            )
        }

        if messageViewFrame.minY <= topPadding || isScrollEnable() {
            let topConstant = reactionViewFrame.height > 0 ? (reactionViewFrame.height / 2) :
            20
            constraints += [
                (messageContentContainerView).topAnchor
                    .pin(equalTo: contentView.topAnchor,
                         constant: isScrollEnable() ? topConstant : topPadding)
                    .with(priority: .streamAlmostRequire)
            ]
        } else {
            reactionsController?.view.layoutIfNeeded()
            constraints += [
                messageContentContainerView.topAnchor.pin(
                    equalTo: contentView.topAnchor,
                    constant: messageViewFrame.minY
                )
                    .with(priority: .streamLow)
            ]
        }
        addReactionAuthorsView()
        layoutReactionAuthorsView()
        NSLayoutConstraint.activate(constraints)
    }

    private func layoutActionController(_ constraints: inout [NSLayoutConstraint]) {
        guard let controller = actionsController else {
            return
        }
        let actionsContainerStackView = ContainerStackView()
        actionsContainerStackView.addArrangedSubview(.spacer(axis: .horizontal))
        messageContainerStackView.addArrangedSubview(actionsContainerStackView)

        constraints.append(
            controller.view.widthAnchor.pin(equalTo: scrollView.widthAnchor, multiplier: 0.6)
        )

        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller, targetView: actionsContainerStackView)

        if message.isSentByCurrentUser {
            constraints.append(
                controller.view.trailingAnchor.constraint(equalTo: messageContentContainerView.trailingAnchor, constant: -messageBubbleViewInsets.right)
            )
        } else {
            constraints.append(
                controller.view.leadingAnchor.pin(
                    equalTo: messageContentContainerView.leadingAnchor,
                    constant: messageBubbleViewInsets.left
                )
            )
        }
    }

    /// Add the reaction authors to the view hierarchy.
    open func addReactionAuthorsView() {
        let reactionsContainerStackView = ContainerStackView()
        reactionsContainerStackView.addArrangedSubview(.spacer(axis: .horizontal))
        messageContainerStackView.addArrangedSubview(reactionsContainerStackView)

        guard let reactionAuthorsController = reactionAuthorsController else { return }
        addChildViewController(reactionAuthorsController, targetView: reactionsContainerStackView)
    }

    /// Layouts the reaction authors view, by default, at the bottom. It can display
    /// the message actions instead depending on where the popup is being presented from.
    open func layoutReactionAuthorsView() {
        guard let reactionAuthorsController = self.reactionAuthorsController else {
            return
        }
        reactionAuthorsController.view.translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = [
            reactionAuthorsController.view.heightAnchor.pin(
                equalToConstant: reactionAuthorsViewHeight
            ),
            reactionAuthorsController.view.widthAnchor.pin(
                equalTo: scrollView.widthAnchor,
                multiplier: reactionAuthorsViewWidthMultiplier
            )
        ]

        if message.isSentByCurrentUser {
            constraints += [
                reactionAuthorsController.view.trailingAnchor.constraint(
                    equalTo: messageContentContainerView.trailingAnchor,
                    constant: -messageBubbleViewInsets.right)
            ]
        } else {
            constraints += [
                reactionAuthorsController.view.leadingAnchor.pin(
                    equalTo: messageContentContainerView.leadingAnchor,
                    constant: messageBubbleViewInsets.left
                )
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// Triggered when `view` is tapped.
    @objc open func didTapOnView(_ gesture: UITapGestureRecognizer) {
        let actionsLocation = gesture.location(in: actionsController?.view)
        let reactionsLocation = gesture.location(in: reactionsController?.view)
        let isGestureInActionsView = actionsController?.view.frame.contains(actionsLocation) == true
        let isGestureInReactionsView = reactionsController?.view.frame.contains(reactionsLocation) == true

        if isGestureInActionsView || isGestureInReactionsView {
            return
        }

        dismiss(animated: true)
    }
}
