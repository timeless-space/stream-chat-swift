//
//  JoinPrivateGroupVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import CoreLocation

class JoinPrivateGroupVC: UIViewController {

    // MARK: - Variables
    var controller: ChatChannelListController?
    var passWord = ""
    private var channelMembers = [Member]()
    private var channelController: ChatChannelController?
    var userStatus: UserStatus?
    var groupInfo: ChatInviteInfo?
    var createChannelInfo: CreatePrivateGroup?
    var timer: Timer?

    // MARK: - enums
    enum UserStatus {
        case createGroup
        case joinGroup
        case alreadyJoined
    }

    // MARK: - Outlets
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblOTP: UILabel!
    @IBOutlet weak var cvUserList: UICollectionView!
    @IBOutlet weak var btnJoinGroup: UIButton!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var viewJoinOverlay: UIView!
    @IBOutlet weak var safeAreaHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomSafeAreaHeight: NSLayoutConstraint!
    @IBOutlet weak var viewSafeAreaBottom: UIView!
    
    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindClosure()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }

    // MARK: - IBOutlets
    @IBAction func btnBackAction(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func btnJoinGroupAction(_ sender: UIButton) {
        if userStatus == .joinGroup {
            viewJoinOverlay.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let `self` = self else { return }
                let parameter: [String: Any] = [kPrivateGroupPasscode: self.passWord,
                                                             kGroupId: self.groupInfo?.channel.cid ?? ""]
                NotificationCenter.default.post(name: .joinPrivateGroup, object: nil, userInfo: parameter)
            }
        } else {
            handleNavigation()
        }
    }

    // MARK: - Functions
    private func setupUI() {
        safeAreaHeight.constant = UIView.safeAreaTop
        bottomSafeAreaHeight.constant = UIView.safeAreaBottom
        btnBack.setTitle("", for: .normal)
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        viewSafeAreaBottom.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        lblOTP.text = passWord
        lblOTP.textColor = .white
        lblOTP.setTextSpacingBy(value: 10)
        btnJoinGroup.backgroundColor = Appearance.default.colorPalette.themeBlue
        btnJoinGroup.layer.cornerRadius = 20
        cvUserList?.register(UINib(nibName: PrivateGroupUsersCVCell.identifier, bundle: nil),
                             forCellWithReuseIdentifier: PrivateGroupUsersCVCell.identifier)
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = Appearance.default.images.handPointUp
        let joinString = NSMutableAttributedString(string: "Nearby friends can join by entering the ")
        joinString.append(NSAttributedString(attachment: imageAttachment))
        joinString.append(NSAttributedString(string: " secret code."))
        lblDescription.attributedText = joinString
        viewJoinOverlay.isHidden = true
        channelMembers = groupInfo?.members ?? []
        if userStatus == .createGroup {
            btnJoinGroup.setTitle("Go To Chat", for: .normal)
            guard let cid = try? ChannelId.init(cid: createChannelInfo?.cid ?? "") else { return }
            channelController = ChatClient.shared.channelController(for: .init(cid: cid))
            createPrivateChannel()
        } else if userStatus == .joinGroup {
            btnJoinGroup.setTitle("Join This Group", for: .normal)
            guard let cid = try? ChannelId.init(cid: groupInfo?.channel.cid ?? "") else { return }
            channelController = ChatClient.shared.channelController(for: .init(cid: cid))
        } else {
            guard let cid = try? ChannelId.init(cid: groupInfo?.channel.cid ?? "") else { return }
            channelController = ChatClient.shared.channelController(for: .init(cid: cid))
            btnJoinGroup.setTitle("Go To Chat", for: .normal)
        }
    }

    private func getPrivateGroupInfo() {
        let parameter: [String: Any] = [kPrivateGroupLat: Float(LocationManager.shared.location.value.coordinate.latitude),
                                        kPrivateGroupLon: Float(LocationManager.shared.location.value.coordinate.longitude),
                                   kPrivateGroupPasscode: self.passWord]
        NotificationCenter.default.post(name: .getPrivateGroup, object: nil, userInfo: parameter)
    }

    private func bindClosure() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let `self` = self else { return }
            self.getPrivateGroupInfo()
        }

        ChatClientConfiguration.shared.joinPrivateGroup = { [weak self] in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                self.viewJoinOverlay.isHidden = true
                self.handleNavigation()
            }
        }

        ChatClientConfiguration.shared.getPrivateGroup = { [weak self] groupInfo in
            guard let `self` = self else { return }
            self.channelMembers = groupInfo?.members ?? []
            self.cvUserList.reloadData()
        }
    }

    private func handleNavigation() {
        guard let channelController = channelController else {
            return
        }
        let arrViewControllers = navigationController?.viewControllers ?? []
        guard let rootViewController = arrViewControllers.first else {
            return
        }
        var newControllers: [UIViewController] = []
        newControllers.append(rootViewController)

        let chatChannelVC = ChatChannelVC.init()
        chatChannelVC.channelController = channelController
        newControllers.append(chatChannelVC)
        navigationController?.setViewControllers(newControllers, animated: true)
    }

    private func createPrivateChannel() {
        btnJoinGroup.isHidden = true
        channelController?.synchronize { [weak self] error in
            guard error == nil, let self = self else {
                return
            }
            self.btnJoinGroup.isHidden = false
            if self.channelController?.channel?.lastMessageAt == nil {
                var extraData = [String: RawJSON]()
                self.channelController?.createNewMessage(
                    text: "",
                    pinning: nil,
                    attachments: [],
                    extraData: ["adminMessage": .string(self.channelController?.channel?.createdBy?.name ?? ""),
                                "messageType": .string(AdminMessageType.privateChat.rawValue)])
                { _ in
                    self.getPrivateGroupInfo()
                }
            }
        }
    }
}


// MARK: - CollectionView delegates
extension JoinPrivateGroupVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channelMembers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PrivateGroupUsersCVCell.identifier, for: indexPath) as? PrivateGroupUsersCVCell
        else {
            return UICollectionViewCell()
        }
        let indexData = channelMembers[indexPath.row]
        cell.configData(data: indexData)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 4, height: (collectionView.frame.size.width / 4) + 25)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
