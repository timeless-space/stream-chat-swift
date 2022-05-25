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
    @IBOutlet weak var stickerCollectionView: UICollectionView!
    @IBOutlet weak var lblCreatedBy: UILabel!

    private var stickers = [Sticker]()

    // MARK: Variables
    var packageInfo: PackageList?
    var chatChannelController: ChatChannelController?

    override func viewDidLoad() {
        super.viewDidLoad()
        Nuke.loadImage(with: packageInfo?.packageImg ?? "", into: imgSticker)
        lblStickerName.text = packageInfo?.packageName ?? ""
        lblCreatedBy.text = "Created by :- \(packageInfo?.artistName ?? "Unknown")"
        guard let stickerId = packageInfo?.packageID else {
            return
        }
        loadSticker(stickerId: "\(stickerId)")
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        stickerCollectionView.collectionViewLayout = flowLayout
    }

    deinit {
        debugPrint("Deinit called")
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

    private func loadSticker(stickerId: String) {
        // Retrieve from userdefault
        if let stickers = UserDefaults.standard.retrieve(object: [Sticker].self, fromKey: stickerId) {
            self.stickers = stickers
            stickerCollectionView.reloadData()
        } else {
            StickerApiClient.stickerInfo(stickerId: stickerId) { [weak self] result in
                guard let `self` = self else { return }
                self.stickers = result.body?.package?.stickers ?? []
                // Cache sticker in userdefault
                UserDefaults.standard.save(customObject: self.stickers, inKey: stickerId)
                UserDefaults.standard.synchronize()
                self.stickerCollectionView.reloadData()
            }
        }
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Collection view delegate
@available(iOS 13.0, *)
extension SendEmojiViewController: UICollectionViewDelegate {

}

// MARK: - Collection view datasource
@available(iOS 13.0, *)
extension SendEmojiViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionCell", for: indexPath) as? StickerCollectionCell else {
            return UICollectionViewCell()
        }
        cell.configureSticker(sticker: stickers[indexPath.row])
        return cell
    }

}

@available(iOS 13.0, *)
extension SendEmojiViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width / 4)
        return .init(width: width, height: width)
    }

}
