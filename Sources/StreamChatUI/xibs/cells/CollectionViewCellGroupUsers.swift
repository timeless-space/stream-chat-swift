//
//  CollectionViewCellGroupUsers.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 07/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

public class CollectionViewCellGroupUsers: UICollectionViewCell {
    static let reuseID: String = "CollectionViewCellGroupUsers"
    let imageLoader = Components.default.imageLoader
    
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var avatarView: AvatarView!
    @IBOutlet public var removeUserButton: UIImageView!
    public func configCell(user: ChatUser) {
        if let imageURL = user.imageURL {
            imageLoader.loadImage(into: avatarView, url: imageURL, imageCDN: StreamImageCDN(), placeholder: Appearance.default.images.userAvatarPlaceholder4)
        }
        nameLabel.text = (user.name ?? user.id).capitalizingFirstLetter()
        nameLabel.setChatSubtitleBigColor()
    }
    // MARK: - LIFE CYCLE
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        removeUserButton.isHidden = true
    }
    // MARK: - METHOD
}
