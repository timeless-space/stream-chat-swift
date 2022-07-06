//
//  MessageListWithMenuVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 06/07/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

open class MessageListWithMenuVC: _ViewController,
                                   ComponentsProvider,
                                   ThemeProvider {
    // MARK: - Variable
    open private(set) lazy var mainContainerView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
    }()
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
    private lazy var navigationBarColor: UIColor = {
        return Appearance.default.colorPalette.walletTabbarBackground
    }()
    open var channelVC: ChatChannelVC?
    open var channelController: ChatChannelController?

    // MARK: - View
    override open func setUp() {
        super.setUp()
        view.addSubview(blurView)
        view.addSubview(mainContainerView)
        //
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnView))
        tapRecognizer.cancelsTouchesInView = false
        blurView.addGestureRecognizer(tapRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        mainContainerView.backgroundColor = Appearance
            .default
            .colorPalette
            .chatViewBackground
        mainContainerView.layer.cornerRadius = 20.0
        mainContainerView.clipsToBounds = true
        // customizeChannelView
        customizeChannelView()
    }

    override open func setUpLayout() {
        super.setUpLayout()
        layoutBlurView()
        layoutMainContainerView()
        layoutMessageList()
        // customizeChannelView
        customizeChannelView()
    }

    // MARK: - SetupUI
    private func layoutBlurView() {
        view.pin(to: blurView)
    }

    private func layoutMainContainerView() {
        NSLayoutConstraint.activate([
            mainContainerView.leadingAnchor
                .constraint(equalTo: view.leadingAnchor, constant: 30),
            mainContainerView.trailingAnchor
                .constraint(equalTo: view.trailingAnchor, constant: -30),
            mainContainerView.topAnchor
                .constraint(equalTo: view.topAnchor, constant: 60),
            mainContainerView.bottomAnchor
                .constraint(equalTo: view.bottomAnchor, constant: -200),
        ])
    }

    private func layoutMessageList() {
        guard let channelVC = channelVC else {
            return
        }
        addChildViewController(channelVC, targetView: mainContainerView)
        NSLayoutConstraint.activate([
            channelVC.view.leadingAnchor
                .constraint(equalTo: mainContainerView.leadingAnchor, constant: 0),
            channelVC.view.trailingAnchor
                .constraint(equalTo: mainContainerView.trailingAnchor, constant: 0),
            channelVC.view.topAnchor
                .constraint(equalTo: mainContainerView.topAnchor, constant: 0),
            channelVC.view.bottomAnchor
                .constraint(equalTo: mainContainerView.bottomAnchor, constant: -10)
        ])
    }

    private func customizeChannelView() {
        channelVC?.messageComposerVC?.view.isHidden = true
        channelVC?.messageComposerBottomConstraint?.constant = 0
        channelVC?.topSafeAreaHeightConstraint?.constant = 15
        channelVC?.bottomSafeAreaHeightConstraint?.constant = 0
        channelVC?.messageComposerVC?.view.heightAnchor
            .constraint(equalToConstant: 0).isActive = true
        channelVC?.channelController?.delegate = nil
        channelVC?.backButton.isHidden = true
        channelVC?.headerView.isUserInteractionEnabled = false
        channelVC?.moreButton.isUserInteractionEnabled = false
        channelVC?.addFriendButton.isUserInteractionEnabled = false
        channelVC?.addFriendButton.isUserInteractionEnabled = false
        channelVC?.channelAction.isHidden = true
    }

    // MARK: - Action
    /// Triggered when `view` is tapped.
    @objc open func didTapOnView(_ gesture: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
}
