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
    open private(set) lazy var channelContainerView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var mainContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "mainContainerStackView")
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
    open private(set) lazy var channelActionsContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "channelActionsContainerStackView")
    /// Class used for buttons in `channelActionsContainerStackView`.
    open var actionButtonClass: ChatMessageActionControl.Type { ChatMessageActionControl.self }
    private lazy var navigationBarColor: UIColor = {
        return Appearance.default.colorPalette.walletTabbarBackground
    }()
    open var channelVC: ChatChannelVC?
    private var channelController: ChatChannelController? {
        return channelVC?.channelController
    }
    private var isChannelMuted = false

    // MARK: - View
    override open func setUp() {
        super.setUp()
        view.addSubview(blurView)
        view.addSubview(mainContainerStackView)
        mainContainerStackView.addArrangedSubview(channelContainerView)
        mainContainerStackView.addArrangedSubview(channelActionsContainerStackView)
        //
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnView))
        tapRecognizer.cancelsTouchesInView = false
        blurView.addGestureRecognizer(tapRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        // mainContainerStackView
        mainContainerStackView.axis = .vertical
        mainContainerStackView.alignment = .fill
        mainContainerStackView.spacing = 10
        // ChannelActionView
        setupChannelActionView()
        // mainContainerView
        channelContainerView.backgroundColor = Appearance
            .default
            .colorPalette
            .chatViewBackground
        channelContainerView.layer.cornerRadius = 20.0
        channelContainerView.clipsToBounds = true
        // customizeChannelView
        customizeChannelView()
    }

    override open func setUpLayout() {
        super.setUpLayout()
        layoutBlurView()
        layoutMainContainerStackView()
        layoutMessageList()
        // customizeChannelView
        customizeChannelView()
    }

    override open func updateContent() {
        isChannelMuted = channelController?.channel?.isMuted ?? false
        channelActionsContainerStackView.removeAllArrangedSubviews()
        channelActions.forEach {
            let actionView = actionButtonClass.init()
            actionView.containerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            actionView.content = $0
            actionView.containerStackView.backgroundColor = appearance.colorPalette.messageActionMenuBackground
            channelActionsContainerStackView.addArrangedSubview(actionView)
            actionView.accessibilityIdentifier = "\(type(of: $0))"
        }
        channelActionsContainerStackView.layoutMarginsDidChange()
    }

    open var channelActions: [ChatMessageActionItem] {
        guard let channelController = channelController else {
            return []
        }
        if channelController.channel?.type == .announcement {
            return [muteChannelActionItem()]
        }
        var actions: [ChatMessageActionItem] = []
        actions.append(markAsReadActionItem())
        actions.append(muteChannelActionItem())
        actions.append(deleteActionItem())
        return actions
    }

    // MARK: - SetupUI
    private func layoutBlurView() {
        view.pin(to: blurView)
    }

    private func layoutMainContainerStackView() {
        NSLayoutConstraint.activate([
            mainContainerStackView.leadingAnchor
                .constraint(equalTo: view.leadingAnchor, constant: 30),
            mainContainerStackView.trailingAnchor
                .constraint(equalTo: view.trailingAnchor, constant: -30),
            mainContainerStackView.topAnchor
                .constraint(equalTo: view.topAnchor, constant: 60),
            mainContainerStackView.bottomAnchor
                .constraint(greaterThanOrEqualTo: view.bottomAnchor, constant: -60),
        ])
    }

    private func layoutMessageList() {
        guard let channelVC = channelVC else {
            return
        }
        addChildViewController(channelVC, targetView: channelContainerView)
        NSLayoutConstraint.activate([
            channelVC.view.leadingAnchor
                .constraint(equalTo: channelContainerView.leadingAnchor, constant: 0),
            channelVC.view.trailingAnchor
                .constraint(equalTo: channelContainerView.trailingAnchor, constant: 0),
            channelVC.view.topAnchor
                .constraint(equalTo: channelContainerView.topAnchor, constant: 0),
            channelVC.view.bottomAnchor
                .constraint(equalTo: channelContainerView.bottomAnchor, constant: -10)
        ])
    }

    private func setupChannelActionView() {
        channelActionsContainerStackView.axis = .vertical
        channelActionsContainerStackView.alignment = .fill
        channelActionsContainerStackView.spacing = 1
        // Fix safe area layout issue when message actions go below scroll view
        channelActionsContainerStackView.insetsLayoutMarginsFromSafeArea = false
        channelActionsContainerStackView.isLayoutMarginsRelativeArrangement = true
        channelActionsContainerStackView.layoutMargins = .zero
        channelActionsContainerStackView.layer.cornerRadius = 16
        channelActionsContainerStackView.layer.masksToBounds = true
        channelActionsContainerStackView.backgroundColor = appearance.colorPalette.messageActionMenuSeparator
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

    open func markAsReadActionItem() -> ChatMessageActionItem {
        MarkAsReadActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for delete action
    open func deleteActionItem() -> ChatMessageActionItem {
        DeleteActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance, title: L10n.Message.Actions.delete
        )
    }

    /// Returns `ChatMessageActionItem` for delete action
    open func muteChannelActionItem() -> ChatMessageActionItem {
        MuteUnmuteChannelActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance,
            isMute: isChannelMuted
        )
    }

    /// Triggered for actions which should be handled by `delegate` and not in this view controller.
    open func handleAction(_ actionItem: ChatMessageActionItem) {
        switch actionItem {
        case is MarkAsReadActionItem:
            break
        case is MuteUnmuteChannelActionItem:
            if isChannelMuted {
                unMuteNotification()
            } else {
                muteNotification()
            }
            break
        case is DeleteActionItem:
            deleteChat()
            break
        default:
            break
        }
    }


    public func muteNotification() {
        channelController?.muteChannel(completion: { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                Snackbar.show(text: "Error while mute channel notifications")
                weakSelf.isChannelMuted = false
                return
            }
            weakSelf.isChannelMuted = true
            Snackbar.show(text: "Notifications muted", messageType: StreamChatMessageType.ChatGroupMute)
            DispatchQueue.main.async {
                weakSelf.dismiss(animated: true)
            }
        })
    }

    public func unMuteNotification() {
        channelController?.unmuteChannel(completion: { [weak self] error in
            guard let weakSelf = self else { return }
            guard error == nil else {
                Snackbar.show(text: "Error while unmute group notifications")
                weakSelf.isChannelMuted = true
                return
            }
            weakSelf.isChannelMuted = false
            Snackbar.show(text: "Notifications unmuted", messageType: StreamChatMessageType.ChatGroupMute)
            DispatchQueue.main.async {
                weakSelf.dismiss(animated: true)
            }
        })
    }

    public func deleteChat() {
        let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.channelController?.hideChannel(clearHistory: true) { [weak self] error in
                guard let weakSelf = self else { return }
                guard error == nil else {
                    Snackbar.show(text: error?.localizedDescription ?? "")
                    return
                }
                DispatchQueue.main.async {
                    weakSelf.dismiss(animated: true)
                }
            }
        }
        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        presentAlert(
            title: "Are you sure you want to delete chat?",
            message: nil, actions: [yesAction, noAction])
    }
}
