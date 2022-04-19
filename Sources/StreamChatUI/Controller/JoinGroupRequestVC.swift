//
//  JoinGroupRequestVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 05/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI
import Nuke

public class JoinGroupRequestVC: UIViewController {
    // MARK: - OUTLEST
    @IBOutlet private weak var groupImageView: ChatChannelAvatarView!
    @IBOutlet private weak var groupNameLabel: UILabel!
    @IBOutlet private weak var joinGroupButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var lblGroupDetails: UILabel!
    @IBOutlet private weak var backgroundView: UIView!

    // MARK: - VARIBALES
    public var channelController: ChatChannelController!
    public var callbackUserJoined:(() -> Void)?
    public var inviteCode: String?

    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        groupImageView.layer.cornerRadius = groupImageView.bounds.width / 2
        groupImageView.content = (channelController.channel, nil)
        groupNameLabel.text = channelController.channel?.name?.capitalizingFirstLetter() ?? ""
        lblGroupDetails.text = channelController.channel?.extraData.channelDescription ?? ""
        joinGroupButton.layer.cornerRadius = joinGroupButton.bounds.height/2
        closeButton.setImage(Appearance.default.images.closePopup, for: .normal)
        backgroundView.backgroundColor = Appearance.default.colorPalette.panModelColor
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func joinGroupButtonAction(_ sender: UIButton) {
        ChatClientConfiguration.shared.joinInviteGroup = { [weak self] isSuccess in
            guard let self = self, isSuccess else {
                return
            }
            guard isSuccess else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.callbackUserJoined?()
        }
        let parameter = [kInviteGroupID: channelController.channel?.cid.description, kInviteId: inviteCode]
        NotificationCenter.default.post(name: .joinInviteGroup, object: nil, userInfo: parameter)
    }
}

extension JoinGroupRequestVC: PanModalPresentable {
    public var panScrollable: UIScrollView? {
        return nil
    }

    public var shortFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(447)
    }

    public var longFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(447)
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
