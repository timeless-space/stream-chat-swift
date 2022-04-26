//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    public var actionsController: ChatMessageActionsVC!
    /// `_ChatMessageReactionsVC` instance for showing reactions.
    public var reactionsController: ChatMessageReactionsVC?
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
        return CGFloat(actionsController.messageActions.count * 50)
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
        let contentSizeHeight = (abs(messageContentView.frame.origin.y - messageContentViewPadding)
                                 + messageContentView.frame.height
                                 + actionMenuMaxHeight + messageContentViewPadding)
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
            if isScrollEnable() {
                constraints += [
                    reactionsController.view.topAnchor.constraint(
                        equalTo: view.topAnchor,
                        constant: UIScreen.main.bounds.midY),
                ]
            } else {
                let reactionViewTop = (reactionViewFrame.height > 0
                                       ? messageContentViewPadding
                                       - (reactionViewFrame.height - messageContentYPosition)
                                       : messageContentViewPadding)
                constraints += [
                    reactionsController.view.bottomAnchor.constraint(
                        equalTo: messageContainerStackView.topAnchor,
                        constant: reactionViewTop)
                ]
            }
        }

        constraints.append(
            actionsController.view.widthAnchor.pin(equalTo: contentView.widthAnchor, multiplier: 0.6)
        )

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
            messageContentContainerView.heightAnchor.pin(greaterThanOrEqualToConstant: messageViewFrame.height)
        ]

        let actionsContainerStackView = ContainerStackView()
        actionsContainerStackView.addArrangedSubview(.spacer(axis: .horizontal))
        messageContainerStackView.addArrangedSubview(actionsContainerStackView)

        actionsController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(actionsController, targetView: actionsContainerStackView)

        if message.isSentByCurrentUser {
            constraints.append(
                actionsController.view.trailingAnchor.constraint(equalTo: messageContentContainerView.trailingAnchor, constant: -messageBubbleViewInsets.right)
            )
        } else {
            constraints.append(
                actionsController.view.leadingAnchor.pin(
                    equalTo: messageContentContainerView.leadingAnchor,
                    constant: messageBubbleViewInsets.left
                )
            )
        }

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

        let topSpacing = (UIView.safeAreaTop + 50)
        if messageViewFrame.minY <= topSpacing || isScrollEnable() {
            constraints += [
                (messageContentContainerView).topAnchor
                    .pin(equalTo: contentView.topAnchor,
                         constant: topSpacing)
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
        NSLayoutConstraint.activate(constraints)
    }

    /// Triggered when `view` is tapped.
    @objc open func didTapOnView(_ gesture: UITapGestureRecognizer) {
        let actionsLocation = gesture.location(in: actionsController.view)
        let reactionsLocation = gesture.location(in: reactionsController?.view)
        let isGestureInActionsView = actionsController.view.frame.contains(actionsLocation)
        let isGestureInReactionsView = reactionsController?.view.frame.contains(reactionsLocation) == true

        if isGestureInActionsView || isGestureInReactionsView {
            return
        }

        dismiss(animated: true)
    }
}
