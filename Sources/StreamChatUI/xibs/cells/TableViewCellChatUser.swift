//
//  TableViewCellChatUser.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 07/02/22.
//

import StreamChat
import StreamChatUI
import UIKit
import SkeletonView

public class TableViewCellChatUser: _TableViewCell, AppearanceProvider {
    static var nib: UINib {
        return UINib(nibName: reuseId, bundle: nil)
    }
    public static let reuseId: String = "TableViewCellChatUser"
    
    // MARK: - OUTLETS
    @IBOutlet public var containerView: UIView!
    @IBOutlet public var nameLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var avatarView: AvatarView!
    @IBOutlet public var accessoryImageView: UIImageView!
    @IBOutlet public var lblRole: UILabel!

    // MARK: - Variables
    private var user: ChatUser?
    let imageLoader = Components.default.imageLoader

    //MARK: - LIFE CYCEL
    public override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        nameLabel.setChatTitleColor()
        descriptionLabel.setChatSubtitleBigColor()
        lblRole.isHidden = true
        avatarView.layer.cornerRadius = avatarView.bounds.height / 2
        accessoryImageView.layer.cornerRadius = accessoryImageView.bounds.height / 2
        containerView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
    }
}
// MARK: - Config
extension TableViewCellChatUser {
    private func getOwnerName(name: String) -> NSMutableAttributedString? {
        guard let iconImage = appearance.images.crown?.tinted(with: .white) else {
            return nil
        }
        let title = NSMutableAttributedString(string: "\(name) ")
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = iconImage
        imageAttachment.bounds = .init(
            x: 0,
            y: -((nameLabel.font.capHeight - iconImage.size.height).rounded() / 2) - 3,
            width: iconImage.size.width,
            height: iconImage.size.height)
        let imageString = NSAttributedString(attachment: imageAttachment)
        title.append(imageString)
        return title
    }

    public func config(user: ChatUser, selectedImage: UIImage?) {
        if let imageURL = user.imageURL {
            imageLoader.loadImage(
                into: avatarView,
                url: imageURL,
                imageCDN: StreamImageCDN(),
                placeholder: Appearance.default.images.userAvatarPlaceholder4
            )
        }
        avatarView.backgroundColor = .clear
        nameLabel.setChatTitleColor()
        descriptionLabel.setChatSubtitleBigColor()
        let name = (user.name ?? user.id)
        if name.lowercased() == user.id.lowercased()  {
            let last = user.id.suffix(5)
            let first = user.id.prefix(7)
            nameLabel.text = "\(first)...\(last)".capitalizingFirstLetter()
        } else {
            nameLabel.text = name.capitalizingFirstLetter()
        }
        if user.isOnline {
            descriptionLabel.textColor = Appearance.default.colorPalette.statusColorBlue
            descriptionLabel.text = "Online"
        } else if let lastActive = user.lastActiveAt {
            descriptionLabel.text = "Last seen: " + Appearance.default.formatters.chatUserList.format(lastActive)
        } else if let lastActive = user.lastActiveAt {
            descriptionLabel.text = "Last seen: " + Appearance.default.formatters.chatUserList.format(lastActive)
        } else {
            descriptionLabel.text = "Never seen"
        }
        accessoryImageView.image = selectedImage
        lblRole.text = ""
        lblRole.isHidden = true
        // asigned user
        self.user = user
    }
    
    public func configGroupDetails(channelMember: ChatChannelMember, selectedImage: UIImage?) {
        self.config(user: channelMember, selectedImage: selectedImage)
        lblRole.text = ""
        lblRole.isHidden = true
        /// userName
        let name = (channelMember.name ?? channelMember.id)
        if name.lowercased() == channelMember.id.lowercased()  {
            let last = channelMember.id.suffix(5)
            let first = channelMember.id.prefix(7)
            if channelMember.memberRole == .owner {
                nameLabel.attributedText = getOwnerName(name: name.capitalizingFirstLetter())
            } else {
                nameLabel.text = "\(first)...\(last)".capitalizingFirstLetter()
            }
        } else {
            if channelMember.memberRole == .owner {
                nameLabel.attributedText = getOwnerName(name: name.capitalizingFirstLetter())
            } else {
                nameLabel.text = name.capitalizingFirstLetter()
            }
        }
        /// owner tag
        if channelMember.memberRole == .owner {
            lblRole.text = "Owner"
            lblRole.textColor = Appearance.default.colorPalette.statusColorBlue
            lblRole.isHidden = false
        } else if channelMember.isInvited {
           lblRole.text = "Invited"
           lblRole.textColor = Appearance.default.colorPalette.statusColorBlue
           lblRole.isHidden = false
        }
    }
}
