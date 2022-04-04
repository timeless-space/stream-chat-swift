//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    
    /// Class used for buttons in `messageActionsContainerView`.
    open var actionButtonClass: ChatMessageActionControl.Type { ChatMessageActionControl.self }

    override open func setUpLayout() {
        super.setUpLayout()
        
        messageActionsContainerStackView.axis = .vertical
        messageActionsContainerStackView.alignment = .fill
        messageActionsContainerStackView.spacing = 1
        view.embed(messageActionsContainerStackView)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        messageActionsContainerStackView.layer.cornerRadius = 16
        messageActionsContainerStackView.layer.masksToBounds = true
        messageActionsContainerStackView.backgroundColor = Appearance.default.colorPalette.messageActionMenuSeparator
    }

    override open func updateContent() {
        messageActionsContainerStackView.subviews.forEach {
            messageActionsContainerStackView.removeArrangedSubview($0)
        }

        messageActions.forEach {
            let actionView = actionButtonClass.init()
            actionView.containerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            actionView.content = $0
            actionView.containerStackView.backgroundColor = Appearance.default.colorPalette.messageActionMenuBackground
            messageActionsContainerStackView.addArrangedSubview(actionView)
        }
    }

    /// Array of `ChatMessageActionItem`s - override this to setup your own custom actions
    open var messageActions: [ChatMessageActionItem] {
        guard
            messageController.dataStore.currentUser() != nil,
            let message = message,
            message.isDeleted == false
        else { return [] }
        var actions: [ChatMessageActionItem] = []
        actions.append(inlineReplyActionItem())
        actions.append(copyActionItem())
        if message.isSentByCurrentUser {
            actions.append(editActionItem())
        }
        actions.append(pinMessageActionItem())
        actions.append(forwardActionItem())
        return actions
    }
    
    /// Returns `ChatMessageActionItem` for edit action
    open func editActionItem() -> ChatMessageActionItem {
        EditActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for edit action
    open func pinMessageActionItem() -> ChatMessageActionItem {
        PinMessageActionItem(
            action: { [weak self] in self?.handleAction($0) },
            appearance: appearance
        )
    }

    /// Returns `ChatMessageActionItem` for edit action
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
            appearance: appearance
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
                UIPasteboard.general.string = self.message?.text

                self.delegate?.chatMessageActionsVCDidFinish(self)
            },
            appearance: appearance
        )
    }
    //TranslateMessageActionItem
    open func translateMessageItem() -> ChatMessageActionItem {
        TranslateMessageActionItem(action: { [weak self] _ in
            guard let self = self else { return }
            print("------------>>>>>>>>")
            self.delegate?.chatMessageActionsVCDidFinish(self)
            // ToDo:
        }, appearance: appearance)
    }

    // More ActionItem
    open func moreItem() -> ChatMessageActionItem {
        MoreActionItem(action: { [weak self] _ in
            guard let self = self else { return }
            print("------------>>>>>>>> more tapped")
            self.delegate?.chatMessageActionsVCDidFinish(self)
        }, appearance: appearance)
    }

    /// Triggered for actions which should be handled by `delegate` and not in this view controller.
    open func handleAction(_ actionItem: ChatMessageActionItem) {
        guard let message = message else { return }
        delegate?.chatMessageActionsVC(self, message: message, didTapOnActionItem: actionItem)
    }
}
