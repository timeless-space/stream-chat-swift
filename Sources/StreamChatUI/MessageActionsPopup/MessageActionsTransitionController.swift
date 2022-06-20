//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// Transitions controller for `ChatMessagePopupVC`.
open class ChatMessageActionsTransitionController: NSObject, UIViewControllerTransitioningDelegate,
    UIViewControllerAnimatedTransitioning {
        /// Indicates if the transition is for presenting or dismissing.
        open var isPresenting: Bool = false

        /// Feedback generator.
        public private(set) lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

        /// The currently selected message identifier.
        public internal(set) var selectedMessageId: MessageId?

        /// The message list view controller.
        public private(set) weak var messageListVC: ChatMessageListVC?

        /// extra Padding to solve message jump issue
        private let extraPadding: CGFloat = 80

        /// The frame the message view's snapshot animates to when pop-up is being dismissed.
        open var selectedMessageContentViewFrame: CGRect? {
            guard let messageContentView = selectedMessageCell?.messageContentView else { return nil }
            let reactionsBubbleHeight = messageContentView.reactionsBubbleView?.frame.height ?? extraPadding
            var frame = messageContentView.superview?.convert(messageContentView.frame, to: nil) ?? .zero
            frame.origin.y -= reactionsBubbleHeight
            frame.size.height = (messageContentView.frame.height + reactionsBubbleHeight)
            return frame
        }

        /// The message cell that displays the selected message.
        open var selectedMessageCell: ChatMessageCell? {
            messageListVC?
                .listView
                .visibleCells
                .compactMap { $0 as? ChatMessageCell }
                .first(where: { $0.messageContentView?.content?.id == selectedMessageId })
        }

        /// Creates transition controller used to animate message actions pop-up for the message displayed by the given message list view controller.
        ///
        /// - Parameter messageListVC: The view controller displaying the message list to animate to/from.
        public required init(messageListVC: ChatMessageListVC?) {
            super.init()

            self.messageListVC = messageListVC
        }

        public func animationController(
            forPresented presented: UIViewController,
            presenting: UIViewController,
            source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            isPresenting = true
            return self
        }

        public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            isPresenting = false
            return self
        }

        public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            0.25
        }

        public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            if isPresenting {
                animatePresent(using: transitionContext)
            } else {
                animateDismiss(using: transitionContext)
            }
        }

        /// Animates present transition.
        open func animatePresent(using transitionContext: UIViewControllerContextTransitioning) {
            guard
                let toVC = transitionContext.viewController(forKey: .to) as? ChatMessagePopupVC,
                let originalMessageContentView = selectedMessageCell?.messageContentView
            else { return }

            selectedMessageId = originalMessageContentView.content?.id

            let messageViewFrame = selectedMessageContentViewFrame ?? .zero
            let messageViewType = type(of: originalMessageContentView)
            let messageAttachmentInjectorType = originalMessageContentView.attachmentViewInjector.map { type(of: $0) }
            let messageLayoutOptions = originalMessageContentView.layoutOptions?.subtracting([.reactions]) ?? []
            let message = originalMessageContentView.content

            let messageView = messageViewType.init()
            messageView.setUpLayoutIfNeeded(options: messageLayoutOptions, attachmentViewInjectorType: messageAttachmentInjectorType)
            messageView.frame = messageViewFrame
            messageView.content = message

            transitionContext.containerView.addSubview(toVC.view)
            toVC.view.isHidden = true
            toVC.messageContentView = messageView
            toVC.messageViewFrame = messageViewFrame
            toVC.reactionViewFrame = (originalMessageContentView.reactionsBubbleView?
                                        .frame ?? .zero)
            toVC.messageContentViewPadding = extraPadding
            toVC.messageContentYPosition = originalMessageContentView.mainContainer.frame.minY
            toVC.setUpLayout()
            let blurView = UIVisualEffectView()
            blurView.frame = transitionContext.finalFrame(for: toVC)

            let makeSnapshot: (UIViewController?) -> UIView? = { viewController in
                guard let view = viewController?.view else { return nil }

                let snapshot = view.snapshotView(afterScreenUpdates: true)
                snapshot?.frame = view.superview?.convert(view.frame, to: nil) ?? .zero
                snapshot?.transform = .init(scaleX: 0, y: 0)
                snapshot?.alpha = 0.0
                return snapshot
            }

            let reactionsSnapshot: UIView? = makeSnapshot(toVC.reactionsController)
            let actionsSnapshot: UIView? = makeSnapshot(toVC.actionsController)

            let transitionSubviews = [
                blurView,
                reactionsSnapshot,
                actionsSnapshot,
                messageView
            ].compactMap { $0 }

            transitionSubviews.forEach(transitionContext.containerView.addSubview)
            messageView.mainContainer.layoutMargins = originalMessageContentView.mainContainer.layoutMargins
            messageView.bubbleThreadFootnoteContainer.layoutMargins = originalMessageContentView.bubbleThreadFootnoteContainer.layoutMargins

            let duration = transitionDuration(using: transitionContext)
            UIView.animate(
                withDuration: 0.2 * duration,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                },
                completion: { _ in
                    self.impactFeedbackGenerator.impactOccurred()
                }
            )

            let showSnapshot: (UIView?) -> Void = { view in
                view?.transform = .identity
                view?.alpha = 1.0
            }

            UIView.animate(
                withDuration: 0.8 * duration,
                delay: 0.2 * duration,
                options: [.curveEaseInOut],
                animations: {
                    messageView.transform = .identity
                    messageView.frame = toVC.messageContentContainerView.superview?.convert(
                        toVC.messageContentContainerView.frame,
                        to: nil
                    ) ?? .zero

                    showSnapshot(actionsSnapshot)
                    showSnapshot(reactionsSnapshot)

                    blurView.effect = (toVC.blurView as? UIVisualEffectView)?.effect
                },
                completion: { _ in
                    transitionSubviews.forEach { $0.removeFromSuperview() }

                    toVC.messageContentContainerView.embed(messageView.withoutAutoresizingMaskConstraints)
                    toVC.view.isHidden = false

                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
        }

        /// Animates dismissal transition.
        open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
            guard
                let fromVC = transitionContext.viewController(forKey: .from) as? ChatMessagePopupVC,
                let toVC = transitionContext.viewController(forKey: .to)
            else { return }

            let blurView = UIVisualEffectView()
            blurView.effect = (fromVC.blurView as? UIVisualEffectView)?.effect
            blurView.frame = transitionContext.finalFrame(for: toVC)

            let makeSnapshot: (UIViewController?) -> UIView? = { viewController in
                guard let view = viewController?.view else { return nil }

                let snapshot = view.snapshotView(afterScreenUpdates: true)
                snapshot?.frame = view.superview?.convert(view.frame, to: nil) ?? .zero
                return snapshot
            }

            let reactionsSnapshot: UIView? = makeSnapshot(fromVC.reactionsController)
            let actionsSnapshot: UIView? = makeSnapshot(fromVC.actionsController)
            let messageViewFrame = self.selectedMessageContentViewFrame ?? .zero
            let messageView = fromVC.messageContentView!
            var frame = fromVC.messageContentContainerView.convert(messageView.frame, to: transitionContext.containerView)
            //frame.size.height = messageViewFrame.height
            messageView.removeFromSuperview()
            messageView.frame = frame
            messageView.translatesAutoresizingMaskIntoConstraints = true

            let transitionSubviews = [blurView, reactionsSnapshot, actionsSnapshot, messageView]
                .compactMap { $0 }
            transitionSubviews.forEach(transitionContext.containerView.addSubview)

            fromVC.view.isHidden = true

            // We use alpha instead of isHidden, because messageContentView is embed
            // in a UIStackView, and so hiding it will change the layout of the message cell.
            selectedMessageCell?.messageContentView?.alpha = 0.0

            let hideView: (UIView?) -> Void = { view in
                view?.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
                view?.alpha = 0.0
            }

            let duration = transitionDuration(using: transitionContext)
            UIView.animate(
                withDuration: duration,
                delay: 0,
                animations: {
                    if let frame = self.selectedMessageContentViewFrame {
                        messageView.frame = frame
                    } else {
                        hideView(messageView)
                    }

                    hideView(actionsSnapshot)
                    hideView(reactionsSnapshot)

                    blurView.effect = nil
                },
                completion: { _ in
                    transitionSubviews.forEach { $0.removeFromSuperview() }

                    self.selectedMessageCell?.messageContentView?.alpha = 1.0

                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

                    self.selectedMessageId = nil
                }
            )
        }
    }
