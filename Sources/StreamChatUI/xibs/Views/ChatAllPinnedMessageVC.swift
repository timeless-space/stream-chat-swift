//
//  ChatAllPinnedMessageVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 03/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

open class ChatAllPinnedMessageVC: _ViewController,
                                   ComponentsProvider,
                                   ThemeProvider {
    // MARK: - Variable
    open private(set) lazy var navigationSafeAreaView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var navigationView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var bottomView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var labelTitle: UILabel = {
        return UILabel(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(Appearance.default.images.backCircle, for: .normal)
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()
    /// The message list component responsible to render the messages.
    open lazy var messageListVC: ChatMessageListVC? = Components()
        .messageListVC
        .init()

    open lazy var pinnedMessages = [ChatMessage]()
    open var channelController: ChatChannelController?

    // MARK: - View
    override open func setUp() {
        super.setUp()
        addDismissAction()
        view.addSubview(navigationSafeAreaView)
        view.addSubview(navigationView)
        navigationView.addSubview(backButton)
        navigationView.addSubview(labelTitle)
        view.addSubview(bottomView)
        messageListVC?.dataSource = self
        messageListVC?.allowActions = false
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        // color
        let navColor = Appearance.default.colorPalette.walletTabbarBackground
        navigationSafeAreaView.backgroundColor = navColor
        navigationView.backgroundColor = navColor
        bottomView.backgroundColor = navColor
        // title
        labelTitle.text = "Pinned Messages"
    }

    override open func setUpLayout() {
        super.setUpLayout()
        layoutSafeAreaView()
        layoutNavigationView()
        layoutTitleLabel()
        layoutBackButton()
        layoutMessageList()
        layoutBottomView()
    }

    // MARK: - SetupUI
    private func layoutSafeAreaView() {
        NSLayoutConstraint.activate([
            navigationSafeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            navigationSafeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            navigationSafeAreaView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            navigationSafeAreaView.heightAnchor.constraint(equalToConstant: UIView.safeAreaTop)
        ])
    }

    private func layoutNavigationView() {
        NSLayoutConstraint.activate([
            navigationView.leadingAnchor
                .constraint(equalTo: view.leadingAnchor, constant: 0),
            navigationView.trailingAnchor
                .constraint(equalTo: view.trailingAnchor, constant: 0),
            navigationView.topAnchor
                .constraint(equalTo: navigationSafeAreaView.bottomAnchor, constant: 0),
            navigationView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func layoutTitleLabel() {
        NSLayoutConstraint.activate([
            labelTitle.centerXAnchor
                .constraint(equalTo: navigationView.centerXAnchor),
            labelTitle.centerYAnchor
                .constraint(equalTo: navigationView.centerYAnchor)
        ])
    }

    private func layoutBackButton() {
        NSLayoutConstraint.activate([
            backButton.leadingAnchor
                .constraint(equalTo: navigationView.leadingAnchor, constant: 12),
            backButton.centerYAnchor
                .constraint(equalTo: navigationView.centerYAnchor, constant: 0),
            backButton.heightAnchor.constraint(equalToConstant: 46),
            backButton.widthAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func layoutMessageList() {
        guard let messageListVC = messageListVC else {
            return
        }
        addChildViewController(messageListVC, targetView: view)
        NSLayoutConstraint.activate([
            messageListVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            messageListVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            messageListVC.view.topAnchor
                .constraint(equalTo: navigationView.bottomAnchor, constant: 0),
            messageListVC.view.bottomAnchor
                .constraint(equalTo: bottomView.topAnchor, constant: 0)
        ])
    }

    private func layoutBottomView() {
        NSLayoutConstraint.activate([
            bottomView.leadingAnchor
                .constraint(equalTo: view.leadingAnchor, constant: 0),
            bottomView.trailingAnchor
                .constraint(equalTo: view.trailingAnchor, constant: 0),
            bottomView.bottomAnchor
                .constraint(equalTo: view.bottomAnchor, constant: UIView.safeAreaTop),
            bottomView.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    // MARK: - Action
    @objc func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    private func addDismissAction() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnView))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)
    }
    /// Triggered when `view` is tapped.
    @objc open func didTapOnView(_ gesture: UITapGestureRecognizer) {
        dismiss(animated: true)
    }
}

// MARK: - ChatMessageListVCDataSource
extension ChatAllPinnedMessageVC: ChatMessageListVCDataSource {
    public func channel(for vc: ChatMessageListVC) -> ChatChannel? {
        return channelController?.channel
    }

    public func numberOfMessages(in vc: ChatMessageListVC) -> Int {
        return pinnedMessages.count
    }

    public func chatMessageListVC(_ vc: ChatMessageListVC, messageAt indexPath: IndexPath) -> ChatMessage? {
        guard indexPath.item < pinnedMessages.count else { return nil }
        return pinnedMessages[indexPath.item]
    }

    open func chatMessageListVC(
        _ vc: ChatMessageListVC,
        messageLayoutOptionsAt indexPath: IndexPath
    ) -> ChatMessageLayoutOptions {
        guard let channel = channelController?.channel else { return [] }
        return components.messageLayoutOptionsResolver.optionsForMessage(
            at: indexPath,
            in: channel,
            with: AnyRandomAccessCollection(pinnedMessages),
            appearance: appearance
        )
    }
}
