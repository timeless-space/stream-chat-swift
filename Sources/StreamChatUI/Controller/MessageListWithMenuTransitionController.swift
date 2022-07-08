//
//  MessageListWithMenuTransitionController.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 08/07/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class MessageListWithMenuTransitionController: NSObject, UIViewControllerTransitioningDelegate,
    UIViewControllerAnimatedTransitioning {
        /// Indicates if the transition is for presenting or dismissing.
        open var isPresenting: Bool = false

        /// Feedback generator.
        public private(set) lazy var impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

        /// - Parameter messageListVC: The view controller displaying the message list to animate to/from.
        public required override init() {
            super.init()
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
                let toVC = transitionContext.viewController(forKey: .to) as? MessageListWithMenuVC
            else { return }
            transitionContext.containerView.addSubview(toVC.view)
            toVC.view.isHidden = true
            let blurView = UIVisualEffectView()
            blurView.frame = transitionContext.finalFrame(for: toVC)

            let transitionSubviews = [
                blurView
            ].compactMap { $0 }

            transitionSubviews.forEach(transitionContext.containerView.addSubview)

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

            UIView.animate(
                withDuration: 0.8 * duration,
                delay: 0.2 * duration,
                options: [.curveEaseInOut],
                animations: {
                    blurView.effect = (toVC.blurView as? UIVisualEffectView)?.effect
                },
                completion: { _ in
                    transitionSubviews.forEach { $0.removeFromSuperview() }
                    toVC.view.isHidden = false

                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
        }

        /// Animates dismissal transition.
        open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {
            guard
                let fromVC = transitionContext.viewController(forKey: .from) as? MessageListWithMenuVC,
                let toVC = transitionContext.viewController(forKey: .to)
            else { return }

            let blurView = UIVisualEffectView()
            blurView.effect = (fromVC.blurView as? UIVisualEffectView)?.effect
            blurView.frame = transitionContext.finalFrame(for: toVC)

            let transitionSubviews = [blurView]
                .compactMap { $0 }
            transitionSubviews.forEach(transitionContext.containerView.addSubview)

            fromVC.view.isHidden = true

            let duration = transitionDuration(using: transitionContext)
            UIView.animate(
                withDuration: duration,
                delay: 0,
                animations: {
                    blurView.effect = nil
                },
                completion: { _ in
                    transitionSubviews.forEach { $0.removeFromSuperview() }
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            )
        }
    }
