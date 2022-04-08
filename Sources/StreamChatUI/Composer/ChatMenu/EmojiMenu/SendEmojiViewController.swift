//
//  SendEmojiViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 06/04/22.
//

import UIKit
import StreamChat
import Nuke

@available(iOS 13.0, *)
class SendEmojiViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var imgSticker: UIImageView!
    @IBOutlet weak var lblStickerName: UILabel!

    // MARK: Variables
    var packageInfo: PackageList?
    var chatChannelController: ChatChannelController?

    override func viewDidLoad() {
        super.viewDidLoad()
        Nuke.loadImage(with: packageInfo?.packageImg ?? "", into: imgSticker)
        lblStickerName.text = packageInfo?.packageName ?? ""
    }

    private func sendStickerGift(chatMembers: ChatChannelMember, cid: ChannelId) {
        StickerApiClient.sendGiftSticker(packageId: self.packageInfo?.packageID ?? 0, sendUserId: ChatClient.shared.currentUserId?.string ?? "", receiveUserId: chatMembers.id ?? "") { result in
            var sendStickerParam = [String: RawJSON]()
            sendStickerParam["giftPackageId"] = .string(self.packageInfo?.packageID?.string ?? "")
            sendStickerParam["giftPackageName"] = .string(self.packageInfo?.packageName ?? "")
            sendStickerParam["giftPackageImage"] = .string(self.packageInfo?.packageImg ?? "")
            sendStickerParam["giftSenderId"] = .string(ChatClient.shared.currentUserId?.string ?? "")
            sendStickerParam["giftSenderName"] = .string(ChatClient.shared.currentUserController().currentUser?.name ?? "")
            sendStickerParam["channelId"] = .string(cid.description)
            sendStickerParam["giftReceiverId"] = .string(chatMembers.id ?? "")
            sendStickerParam["giftReceiverName"] = .string(chatMembers.name ?? "")
            ChatClient.shared.channelController(for: cid)
                .createNewMessage(
                    text: "",
                    pinning: nil,
                    attachments: [],
                    extraData: ["sendStickerGift": .dictionary(sendStickerParam)],
                    completion: nil)
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func btnSendSticker(_ sender: Any) {
        //TODO: handle send flow
        guard let cid = chatChannelController?.channel?.cid else { return }

        let channelMember = chatChannelController?.client.memberListController(query: .init(cid: cid))
        channelMember?.synchronize({ [weak self] error in
            guard error == nil, let self = self else { return }
            let chatMembers = channelMember?.members.filter({ (member: ChatChannelMember) -> Bool in
                return member.id != self.chatChannelController?.client.currentUserId
            })
            if chatMembers?.count ?? 0 > 1 {
                if let groupPicker = GroupListPickerViewController.instantiateController(storyboard: .wallet) as? GroupListPickerViewController {
                    groupPicker.controller = self.chatChannelController
                    groupPicker.didSelectMember = { [weak self] member in
                        guard let `self` = self else { return }
                        self.sendStickerGift(chatMembers: member, cid: cid)
                    }
                    self.presentPanModal(groupPicker)
                }
            } else {
                guard let member = chatMembers?.first else { return }
                self.sendStickerGift(chatMembers: member, cid: cid)
            }
        })
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

@available(iOS 13.0, *)
extension SendEmojiViewController: PanModalPresentable {
    public var panScrollable: UIScrollView? {
        return nil
    }

    public var shortFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(450)
    }

    public var longFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(450)
    }

    public var anchorModalToLongForm: Bool {
        return true
    }

    public var showDragIndicator: Bool {
        return false
    }

    public var allowsExtendedPanScrolling: Bool {
        return false
    }

    public var allowsDragToDismiss: Bool {
        return true
    }

    public var cornerRadius: CGFloat {
        return 34
    }

    public var isHapticFeedbackEnabled: Bool {
        return true
    }
}
