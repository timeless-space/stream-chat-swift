//
//  CollectionCellSelectedMembers.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 13/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke

class CollectionCellSelectedMembers: UICollectionViewCell {
    static let reuseID: String = "CollectionCellSelectedMembers"
    // MARK: - Outlets
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var avatarView: AvatarView!

    // MARK: - Fuction
    func configCell(user: ChatUser) {
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: avatarView)
        }
        //avatarView.backgroundColor = .blue
        nameLabel.text = (user.name ?? user.id).capitalizingFirstLetter()
        nameLabel.setChatSubtitleBigColor()
    }
}
