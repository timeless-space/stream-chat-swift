//
//  PrivateGroupUsersCVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke

class PrivateGroupUsersCVCell: UICollectionViewCell {

    static let identifier = "PrivateGroupUsersCVCell"
    // MARK: - Outlets
    @IBOutlet private weak var imgAvatar: UIImageView!
    @IBOutlet private weak var lblUserName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK: - Functions
    func configData(data: Member) {
        NukeImageLoader().loadImage(
            into: imgAvatar,
            url: URL(string: data.user?.image ?? ""),
            imageCDN: StreamImageCDN(),
            placeholder: Appearance.default.images.userAvatarPlaceholder4,
            resize: true
        )
        lblUserName.text = data.user?.name
        imgAvatar.cornerRadius = 35
        imgAvatar.layoutIfNeeded()
    }

}
