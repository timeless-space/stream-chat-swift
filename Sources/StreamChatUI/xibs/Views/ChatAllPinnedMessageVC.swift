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
    open private(set) lazy var activityIndicator: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .whiteLarge)
            .withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var mainContainerView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
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
    private var unPinnedMessageCounter = 0

    // MARK: - View
    override open func setUp() {
        super.setUp()
        view.addSubview(mainContainerView)
        view.addSubview(activityIndicator)
        // mainContainerView
        mainContainerView.addSubview(navigationSafeAreaView)
        mainContainerView.addSubview(navigationView)
        mainContainerView.addSubview(bottomSafeArea)
        mainContainerView.addSubview(unPinMessageView)
        // navigationView
        navigationView.addSubview(backButton)
        navigationView.addSubview(labelTitle)
        // unPinMessageView
        unPinMessageView.addSubview(unPinMessageButton)
        // messageListVC
        messageListVC?.client = channelController?.client
        messageListVC?.dataSource = self
        messageListVC?.delegate = self
        messageListVC?.isPinnedMessagePreview = true
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
        // activity indicator
        activityIndicator.isHidden = true
    }

    override open func setUpLayout() {
        super.setUpLayout()
        layoutMainContainerView()
        layoutSafeAreaView()
        layoutActivityIndicatorView()
        layoutNavigationView()
        layoutTitleLabel()
        layoutBackButton()
        layoutMessageList()
        layoutBottomSafeAreaView()
        layoutUnpinMessageView()
        layoutUnpinAllMessageButton()
    }

    private func refreshMessages() {
        labelTitle.text = "\(pinnedMessages.count) Pinned Messages"
        messageListVC?.listView.reloadData()
    }

    // MARK: - SetupUI
    private func layoutMainContainerView() {
        NSLayoutConstraint.activate([
            mainContainerView.leadingAnchor
                .constraint(equalTo: view.leadingAnchor, constant: 0),
            mainContainerView.trailingAnchor
                .constraint(equalTo: view.trailingAnchor, constant: 0),
            mainContainerView.topAnchor
                .constraint(equalTo: view.topAnchor, constant: 0),
            mainContainerView.bottomAnchor
                .constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
    }

    private func layoutSafeAreaView() {
        NSLayoutConstraint.activate([
            navigationSafeAreaView.leadingAnchor
                .constraint(equalTo: mainContainerView.leadingAnchor, constant: 0),
            navigationSafeAreaView.trailingAnchor
                .constraint(equalTo: mainContainerView.trailingAnchor, constant: 0),
            navigationSafeAreaView.topAnchor
                .constraint(equalTo: mainContainerView.topAnchor, constant: 0),
            navigationSafeAreaView.heightAnchor.constraint(equalToConstant: UIView.safeAreaTop)
        ])
    }

    private func layoutActivityIndicatorView() {
        activityIndicator.centerXAnchor
            .constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor
            .constraint(equalTo: view.centerYAnchor).isActive = true
    }

    private func layoutNavigationView() {
        NSLayoutConstraint.activate([
            navigationView.leadingAnchor
                .constraint(equalTo: mainContainerView.leadingAnchor, constant: 0),
            navigationView.trailingAnchor
                .constraint(equalTo: mainContainerView.trailingAnchor, constant: 0),
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
        addChildViewController(messageListVC, targetView: mainContainerView)
        NSLayoutConstraint.activate([
            messageListVC.view.leadingAnchor
                .constraint(equalTo: mainContainerView.leadingAnchor, constant: 0),
            messageListVC.view.trailingAnchor
                .constraint(equalTo: mainContainerView.trailingAnchor, constant: 0),
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
            unPinMessageView.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor),
            unPinMessageView.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor),
            unPinMessageView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func layoutBottomSafeAreaView() {
        NSLayoutConstraint.activate([
            bottomSafeArea.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor),
            bottomSafeArea.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor),
            bottomSafeArea.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor),
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
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        view.bringSubviewToFront(activityIndicator)
        mainContainerView.isUserInteractionEnabled = false
        mainContainerView.alpha = 0.5
        // unpin all messages
        unPinAllMessages()
    }

    private func unPinAllMessages() {
        if unPinnedMessageCounter > pinnedMessages.count - 1 {
            let msg = unPinnedMessageCounter == 1 ? "Message" : "Messages"
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            dismiss(animated: false, completion: nil)
            Snackbar.show(text: "\(unPinnedMessageCounter) \(msg) Unpinned.")
        } else {
            let message = pinnedMessages[unPinnedMessageCounter]
            messageListVC?.unPinMessage(message: message) { [weak self] error in
                guard let weakSelf = self else { return }
                if error == nil {
                    weakSelf.unPinnedMessageCounter += 1
                } else {
                    weakSelf.unPinnedMessageCounter = weakSelf.pinnedMessages.count
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    weakSelf.unPinAllMessages()
                }
            }
        }
    }
}

// MARK: - ChatMessageListVCDataSource
extension ChatAllPinnedMessageVC: ChatMessageListVCDataSource {
    public var messages: [ChatMessage] {
        return pinnedMessages
    }

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

// MARK: - ChatMessageListVCDelegate
extension ChatAllPinnedMessageVC: ChatMessageListVCDelegate {
    public func chatMessageListVC(_ vc: ChatMessageListVC, didTapOnMessageListView messageListView: ChatMessageListView, with gestureRecognizer: UITapGestureRecognizer) {
    }

    public func chatMessageListVC(_ vc: ChatMessageListVC, willDisplayMessageAt indexPath: IndexPath) {}

    public func chatMessageListVC(_ vc: ChatMessageListVC, scrollViewDidScroll scrollView: UIScrollView) {}

    public func chatMessageListVC(_ vc: ChatMessageListVC, didTapOnAction actionItem: ChatMessageActionItem, for message: ChatMessage) {
        switch actionItem {
        case is PinMessageActionItem:
            UIApplication.shared.windows.last?.rootViewController?.dismiss(animated: true) { [weak self] in
                guard let weakSelf = self, message.isPinned else {
                    return
                }
                weakSelf.messageListVC?.unPinMessage(message: message, completion: { error in
                    guard error == nil else {
                        return Snackbar.show(text: L10n.Message.Actions.unPinFailed)
                    }
                    guard let mIndex = weakSelf.pinnedMessages
                        .firstIndex(where: { $0.id == message.id}) else { return }
                    weakSelf.pinnedMessages.remove(at: mIndex)
                    Snackbar.show(text: "Message Unpinned.")
                    guard !weakSelf.pinnedMessages.isEmpty else {
                        weakSelf.dismiss(animated: true, completion: nil)
                        return
                    }
                    weakSelf.refreshMessages()
                })
            }
        default:
            return
        }
    }
}
