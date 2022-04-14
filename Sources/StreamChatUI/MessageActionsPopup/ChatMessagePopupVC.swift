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
    private lazy var paddingView = UIView()
    
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

        messageContainerStackView.axis = .vertical
        messageContainerStackView.spacing = 0
        view.addSubview(messageContainerStackView)

        var constraints: [NSLayoutConstraint] = [
            messageContainerStackView.bottomAnchor.pin(lessThanOrEqualTo: view.bottomAnchor),
            messageContainerStackView.topAnchor.pin(greaterThanOrEqualTo: view.topAnchor),
            messageContainerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            messageContainerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
        ]

        if let reactionsController = reactionsController {
            let reactionsContainerView = ContainerStackView()
            messageContainerStackView.addArrangedSubview(reactionsContainerView)
            reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))
            
            reactionsController.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(reactionsController, targetView: reactionsContainerView)

            reactionsContainerView.addArrangedSubview(.spacer(axis: .horizontal))
            
            if message.isSentByCurrentUser {
                constraints += [
                    reactionsController.view.trailingAnchor
                        .pin(lessThanOrEqualTo: actionsController.view.trailingAnchor),
                    reactionsController.reactionsBubble.tailTrailingAnchor
                        .pin(equalTo: messageContentContainerView.leadingAnchor, constant: messageBubbleViewInsets.left),
                ]
            } else {
                constraints += [
                    // added leadingAnchor
                    reactionsController.view.leadingAnchor
                        .pin(greaterThanOrEqualTo: actionsController.view.leadingAnchor),
                    reactionsController.reactionsBubble.tailLeadingAnchor
                        .pin(equalTo: messageContentContainerView.trailingAnchor, constant: -messageBubbleViewInsets.right),
                ]
            }
            constraints += [
                reactionsController.view.bottomAnchor.constraint(equalTo: messageContentContainerView.topAnchor, constant: 0),
                reactionsController.view.widthAnchor.pin(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
            ]
        }
        
        constraints.append(
            actionsController.view.widthAnchor.pin(equalTo: view.widthAnchor, multiplier: 0.6)
        )
        
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(
            paddingView.heightAnchor.constraint(equalToConstant: 12)
        )
        messageContainerStackView.addArrangedSubview(messageContentContainerView)
        messageContainerStackView.addArrangedSubview(paddingView)

        if let timeStampLabel = messageContentView.timestampLabel {
            constraints.append(
                paddingView.heightAnchor.constraint(equalToConstant: 5)
            )
        } else {
            constraints.append(
                paddingView.heightAnchor.constraint(equalToConstant: 12)
            )
        }
        var contentHeight = messageViewFrame.height
        if contentHeight > UIScreen.main.bounds.midY {
            contentHeight = UIScreen.main.bounds.midY
        }
        constraints += [
            messageContentContainerView.widthAnchor.pin(equalToConstant: messageViewFrame.width),
            messageContentContainerView.heightAnchor.pin(equalToConstant: contentHeight)
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
        } else {
            messageContainerStackView.alignment = .leading
        }

        if messageViewFrame.minY <= 0 {
            constraints += [
                (reactionsController?.view ?? messageContentContainerView).topAnchor
                    .pin(equalTo: view.topAnchor)
                    .with(priority: .streamAlmostRequire)
            ]
        } else {
            reactionsController?.view.layoutIfNeeded()
            constraints += [
                messageContentContainerView.topAnchor.pin(
                    equalTo: view.topAnchor,
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
