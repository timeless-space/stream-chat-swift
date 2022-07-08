//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol ChatMessageActionsVCDelegate: AnyObject {
    func chatMessageActionsVC(
        _ vc: ChatMessageActionsVC,
        message: ChatMessage,
        didTapOnActionItem actionItem: ChatMessageActionItem
    )
    func chatMessageActionsVCDidFinish(_ vc: ChatMessageActionsVC)
}

/// View controller to show message actions.
open class ChatMessageActionsVC: _ViewController, ThemeProvider {
    public weak var delegate: ChatMessageActionsVCDelegate?

    /// `ChatMessageController` instance used to obtain the message data.
    public var messageController: ChatMessageController!

    /// `ChannelConfig` that contains the feature flags of the channel.
    public var channelConfig: ChannelConfig!

    /// Message that should be shown in this view controller.
    open var message: ChatMessage? {
        messageController.message
    }
    
    /// The `AlertsRouter` instance responsible for presenting alerts.
    open lazy var alertsRouter = components
        .alertsRouter
        // Temporary solution until the actions router works with with the `UIWindow`
        .init(rootViewController: self.parent ?? self)

    /// `ContainerView` for showing message's actions.
    open private(set) lazy var messageActionsContainerStackView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "messageActionsContainerStackView")
    
    /// Class used for buttons in `messageActionsContainerView`.
    open var actionButtonClass: ChatMessageActionControl.Type { ChatMessageActionControl.self }

    override open func setUpLayout() {
        super.setUpLayout()
        view.embed(messageActionsContainerStackView)
        messageActionsContainerStackView.axis = .vertical
        messageActionsContainerStackView.alignment = .fill
        messageActionsContainerStackView.spacing = 1

        // Fix safe area layout issue when message actions go below scroll view
        messageActionsContainerStackView.insetsLayoutMarginsFromSafeArea = false
        messageActionsContainerStackView.isLayoutMarginsRelativeArrangement = true
        messageActionsContainerStackView.layoutMargins = .zero
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        messageActionsContainerStackView.layer.cornerRadius = 16
        messageActionsContainerStackView.layer.masksToBounds = true
        messageActionsContainerStackView.backgroundColor = appearance.colorPalette.messageActionMenuSeparator
    }

    override open func updateContent() {
        messageActionsContainerStackView.removeAllArrangedSubviews()

        messageActions.forEach {
            let actionView = actionButtonClass.init()
            actionView.containerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            actionView.content = $0
            actionView.containerStackView.backgroundColor = appearance.colorPalette.messageActionMenuBackground
            messageActionsContainerStackView.addArrangedSubview(actionView)
            actionView.accessibilityIdentifier = "\(type(of: $0))"
        }
        messageActionsContainerStackView.layoutMarginsDidChange()
    }

    /// Array of `ChatMessageActionItem`s - override this to setup your own custom actions
    open var messageActions: [ChatMessageActionItem] {
        guard
            let currentUser = messageController.dataStore.currentUser(),
            let message = message,
            message.isDeleted == false
        else { return [] }

        switch message.localState {
        case nil:
            var actions: [ChatMessageActionItem] = []

            if channelConfig.quotesEnabled {
                actions.append(inlineReplyActionItem())
            }

            /*if channelConfig.repliesEnabled && !message.isPartOfThread {
                actions.append(threadReplyActionItem())
            }*/

            actions.append(copyActionItem())
            //actions.append(translateMessageItem())
            if message.isSentByCurrentUser {
                actions += [editActionItem(), deleteActionItem()]

            } else {
                actions += [flagActionItem()]

                if channelConfig.mutesEnabled {
                    let isMuted = currentUser.mutedUsers.contains(message.author)
                    actions.append(isMuted ? unmuteActionItem() : muteActionItem())
                }
            }

            return actions
        case .pendingSend, .sendingFailed, .pendingSync, .syncingFailed, .deletingFailed:
            return [
                message.localState == .sendingFailed ? resendActionItem() : nil,
                editActionItem(),
                deleteActionItem()
            ]
            .compactMap { $0 }
        case .sending, .syncing, .deleting:
            return []
        }
    }
    
    /// Returns `ChatMessageActionItem` for edit action
    open func editActionItem() -> ChatMessageActionItem {
        EditActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for pin Message action
    open func pinMessageActionItem() -> ChatMessageActionItem {
        PinMessageActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for forward action
    open func forwardActionItem() -> ChatMessageActionItem {
        ForwardMessageActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for delete action
    open func deleteActionItem() -> ChatMessageActionItem {
        DeleteActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageDeletionConfirmationAlert { confirmed in
                    guard confirmed else { return }

                    self.messageController.deleteMessage { _ in
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                }
            },
            appearance: appearance, title: L10n.Message.Actions.deleteMessage
        )
    }
    
    /// Returns `ChatMessageActionItem` for resend action.
    open func resendActionItem() -> ChatMessageActionItem {
        ResendActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.messageController.resendMessage { _ in
                    self.delegate?.chatMessageActionsVCDidFinish(self)
                }
            },
            appearance: appearance
        )
    }
    
    /// Returns `ChatMessageActionItem` for mute action.
    open func muteActionItem() -> ChatMessageActionItem {
        MuteUserActionItem(
            action: { [weak self] _ in
                guard
                    let self = self,
                    let author = self.message?.author
                else { return }

                self.messageController.client
                    .userController(userId: author.id)
                    .mute { _ in self.delegate?.chatMessageActionsVCDidFinish(self) }
            },
            appearance: appearance
        )
    }
    
    /// Returns `ChatMessageActionItem` for unmute action.
    open func unmuteActionItem() -> ChatMessageActionItem {
        UnmuteUserActionItem(
            action: { [weak self] _ in
                guard
                    let self = self,
                    let author = self.message?.author
                else { return }

                self.messageController.client
                    .userController(userId: author.id)
                    .unmute { _ in self.delegate?.chatMessageActionsVCDidFinish(self) }
            },
            appearance: appearance
        )
    }
    
    /// Returns `ChatMessageActionItem` for inline reply action.
    open func inlineReplyActionItem() -> ChatMessageActionItem {
        InlineReplyActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }
    
    /// Returns `ChatMessageActionItem` for thread reply action.
    open func threadReplyActionItem() -> ChatMessageActionItem {
        ThreadReplyActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }
    
    /// Returns `ChatMessageActionItem` for copy action.
    open func copyActionItem() -> ChatMessageActionItem {
        CopyActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                Snackbar.hide()
                UIPasteboard.general.string = self.message?.text
                DispatchQueue.main.async {
                    Snackbar.show(text: "", messageType: StreamChatMessageType.MessageCopied)
                    self.delegate?.chatMessageActionsVCDidFinish(self)
                }
            },
            appearance: appearance
        )
    }
    
    //TranslateMessageActionItem
    open func translateMessageItem() -> ChatMessageActionItem {
        TranslateMessageActionItem(action: { [weak self] _ in
            guard let self = self else { return }
            self.messageController.translate(to: .turkish) { error in
                self.delegate?.chatMessageActionsVCDidFinish(self)
            }
        }, appearance: appearance)
    }

    // More ActionItem
    open func moreItem() -> ChatMessageActionItem {
        MoreActionItem(action: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.chatMessageActionsVCDidFinish(self)
        }, appearance: appearance)
    }
    
    /// Returns `ChatMessageActionItem` for flag action.
    open func flagActionItem() -> ChatMessageActionItem {
        FlagActionItem(
            action: { [weak self] _ in
                guard let self = self else { return }
                self.alertsRouter.showMessageFlagConfirmationAlert { confirmed in
                    guard confirmed else { return }
                    
                    self.messageController.flag { _ in
                        self.delegate?.chatMessageActionsVCDidFinish(self)
                    }
                }
            },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for flag action.
    open func markAsReadActionItem() -> ChatMessageActionItem {
        MarkAsReadActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Triggered for actions which should be handled by `delegate` and not in this view controller.
    open func handleAction(_ actionItem: ChatMessageActionItem) {
        guard let message = message else { return }
        delegate?.chatMessageActionsVC(self, message: message, didTapOnActionItem: actionItem)
    }
}
