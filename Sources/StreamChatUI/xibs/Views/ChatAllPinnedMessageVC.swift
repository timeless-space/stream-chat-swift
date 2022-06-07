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
    open private(set) lazy var unPinMessageView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var unPinMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.contentEdgeInsets = UIEdgeInsets
            .init(top: 0, left: 10, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(unPinAllMessageAction(_:)), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var bottomSafeArea: BottomSafeAreaView = {
        return components
            .bottomSafeAreaView
            .init()
            .withoutAutoresizingMaskConstraints
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
    private lazy var messageListVC: ChatMessageListVC? = components
        .messageListVC
        .init()

    open lazy var pinnedMessages = [ChatMessage]()
    open var channelController: ChatChannelController?
    private lazy var navigationBarColor: UIColor = {
        return Appearance.default.colorPalette.walletTabbarBackground
    }()
    private var queueUnpinMessage = DispatchGroup()

    // MARK: - View
    override open func setUp() {
        super.setUp()
        view.addSubview(navigationSafeAreaView)
        view.addSubview(navigationView)
        navigationView.addSubview(backButton)
        navigationView.addSubview(labelTitle)
        view.addSubview(bottomSafeArea)
        view.addSubview(unPinMessageView)
        unPinMessageView.addSubview(unPinMessageButton)
        messageListVC?.client = channelController?.client
        messageListVC?.dataSource = self
        messageListVC?.allowActions = false
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        // color
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        navigationSafeAreaView.backgroundColor = navigationBarColor
        navigationView.backgroundColor = navigationBarColor
        bottomSafeArea.backgroundColor = navigationBarColor
        unPinMessageView.backgroundColor = navigationBarColor
        unPinMessageButton.backgroundColor = navigationBarColor
        // title
        labelTitle.text = "\(pinnedMessages.count) Pinned Messages"
        unPinMessageButton.setTitle("Unpin All Messages", for: .normal)
    }

    override open func setUpLayout() {
        super.setUpLayout()
        layoutSafeAreaView()
        layoutNavigationView()
        layoutTitleLabel()
        layoutBackButton()
        layoutMessageList()
        layoutBottomSafeAreaView()
        layoutUnpinMessageView()
        layoutUnpinAllMessageButton()
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
                .constraint(equalTo: unPinMessageView.topAnchor, constant: 0)
        ])
    }

    private func layoutUnpinAllMessageButton() {
        NSLayoutConstraint.activate([
            unPinMessageButton.centerXAnchor
                .constraint(equalTo: unPinMessageView.centerXAnchor),
            unPinMessageButton.centerYAnchor
                .constraint(equalTo: unPinMessageView.centerYAnchor),
            unPinMessageButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func layoutUnpinMessageView() {
        NSLayoutConstraint.activate([
            unPinMessageView.bottomAnchor
                .constraint(equalTo: bottomSafeArea.topAnchor),
            unPinMessageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            unPinMessageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            unPinMessageView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func layoutBottomSafeAreaView() {
        NSLayoutConstraint.activate([
            bottomSafeArea.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSafeArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSafeArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSafeArea.heightAnchor
                .constraint(equalToConstant: UIView.safeAreaBottom)
        ])
    }

    // MARK: - Action
    @objc func backAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc func unPinAllMessageAction(_ sender: UIButton) {
        guard ChatClient.shared.connectionStatus == .connected else {
            Snackbar.show(text: L10n.Alert.NoInternet)
            return
        }
        guard let messageListVC = messageListVC else {
            return
        }
        var unPinnedMessageCount = 0
        for message in pinnedMessages {
            queueUnpinMessage.enter()
            messageListVC.unPinMessage(message: message) { [weak self] error in
                guard let weakSelf = self else { return }
                if error == nil {
                    unPinnedMessageCount += 1
                }
                weakSelf.queueUnpinMessage.leave()
            }
        }
        queueUnpinMessage.notify(queue: .main) { [weak self] in
            guard let weakSelf = self else { return }
            let msg = unPinnedMessageCount == 1 ? "message" : "messages"
            weakSelf.dismiss(animated: false, completion: nil)
            Snackbar.show(text: "\(unPinnedMessageCount) \(msg) Unpinned.")
        }
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
