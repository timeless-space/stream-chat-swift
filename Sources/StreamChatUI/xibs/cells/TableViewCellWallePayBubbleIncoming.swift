//
//  TableViewCellWallePayBubbleIncoming.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 25/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke

public class TableViewCellWallePayBubbleIncoming: UITableViewCell {
    public static let nib: UINib = UINib.init(nibName: identifier, bundle: nil)
    // MARK: -  @IBOutlet
    @IBOutlet private weak var viewContainer: UIView!
    @IBOutlet private weak var subContainer: UIView!
    @IBOutlet private weak var sentThumbImageView: UIImageView!
    @IBOutlet private weak var payRequestImageView: UIImageView!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var pickUpButton: UIButton!
    @IBOutlet private weak var lblDetails: UILabel!
    @IBOutlet private weak var authorAvatarView: UIImageView!
    @IBOutlet private weak var authorAvatarSpacer: UIView!
    @IBOutlet private weak var authorNameLabel: UILabel!
    @IBOutlet private weak var avatarViewContainerView: UIView!
    @IBOutlet private weak var cellWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var AvatarContainerWidthConstraint: NSLayoutConstraint!
    
    // MARK: -  Variables
    private var cellWidth: CGFloat {
        return (UIScreen.main.bounds.width * 0.3)
    }
    public var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    var isSender = false
    var channel: ChatChannel?
    var client: ChatClient?
    var walletPaymentType: WalletAttachmentPayload.PaymentType = .pay
    
    // MARK: -  View Cycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentView.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        contentView.transform = .mirrorY
        viewContainer.backgroundColor = .clear
        avatarViewContainerView.isHidden = true
        cellWidthConstraint.constant = cellWidth
    }

    // MARK: -  Methods
    func configureCell(isSender: Bool) {
        self.isSender = isSender
        // Constraint
        viewContainerTopConstraint.constant = Constants.MessageTopPadding
        viewContainerLeadingConstraint.constant = Constants.MessageLeftPadding
        AvatarContainerWidthConstraint.constant = 0
        // authorAvatarView
        authorAvatarView.contentMode = .scaleAspectFill
        authorAvatarView.layer.cornerRadius = authorAvatarView.bounds.width / 2
        authorAvatarView.backgroundColor = .clear
        // viewContainer
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        // subContainer
        subContainer.backgroundColor = Appearance.default.colorPalette.background6
        subContainer.layer.cornerRadius = 12
        subContainer.clipsToBounds = true
        // sentThumbImageView
        sentThumbImageView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbImageView.contentMode = .scaleAspectFill
        sentThumbImageView.clipsToBounds = true
        payRequestImageView.backgroundColor = Appearance.default.colorPalette.background6
        payRequestImageView.contentMode = .scaleAspectFill
        payRequestImageView.clipsToBounds = true
        // lblDetails
        lblDetails.textAlignment = .center
        lblDetails.numberOfLines = 0
        lblDetails.textColor = .white.withAlphaComponent(0.6)
        lblDetails.font = Appearance.default.fonts.body.withSize(11)
        // timestampLabel
        timestampLabel.textAlignment = .left
        timestampLabel.textColor = Appearance.default.colorPalette.subtitleText
        timestampLabel.font = Appearance.default.fonts.footnote
        // authorNameLabel
        authorNameLabel.text = content?.author.name ?? ""
        authorNameLabel.textAlignment = .left
        authorNameLabel.textColor = Appearance.default.colorPalette.subtitleText
        authorNameLabel.font = Appearance.default.fonts.footnote
        // pickUpButton
        pickUpButton.setTitle("Pay", for: .normal)
        pickUpButton.addTarget(self, action: #selector(btnSendPacketAction), for: .touchUpInside)
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        pickUpButton.clipsToBounds = true
        pickUpButton.layer.cornerRadius = 20
        // walletPaymentType
        walletPaymentType = content?.attachments(payloadType: WalletAttachmentPayload.self).first?.paymentType ?? .pay
        if walletPaymentType == .request {
            let payload = content?.attachments(payloadType: WalletAttachmentPayload.self).first
            if isSender  {
                descriptionLabel.text = "Payment Requested"
            } else {
                descriptionLabel.text = "\(payload?.extraData?.recipientName ?? "-") Requests Payment"
            }
            if let themeURL = payload?.extraData?.requestedThemeUrl, let imageUrl = URL(string: themeURL) {
                if imageUrl.pathExtension == "gif" {
                    sentThumbImageView.isHidden = false
                    sentThumbImageView.setGifFromURL(imageUrl)
                } else {
                    sentThumbImageView.isHidden = true
                    Nuke.loadImage(with: themeURL, into: payRequestImageView)
                }
            }
            lblDetails.text = "REQUEST: \(payload?.extraData?.requestedAmount?.formattedOneBalance ?? "") ONE"

            if payload?.extraData?.requestedIsPaid ?? false {
                pickUpButton.alpha = 0.5
                pickUpButton.isEnabled = false
            } else {
                pickUpButton.alpha = 1.0
                pickUpButton.isEnabled = true
            }
        } else {
            pickUpButton.alpha = 1.0
            pickUpButton.isEnabled = true
        }
        payRequestImageView.isHidden = !sentThumbImageView.isHidden
        // pickUpButton
        pickUpButton.setTitle("Pay", for: .normal)
        pickUpButton.addTarget(self, action: #selector(btnSendPacketAction), for: .touchUpInside)
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        pickUpButton.clipsToBounds = true
        pickUpButton.layer.cornerRadius = 20
        // Avatar
        let placeholder = Appearance.default.images.userAvatarPlaceholder1
        if let imageURL = content?.author.imageURL {
            Components.default.imageLoader.loadImage(
                into: authorAvatarView,
                url: imageURL,
                imageCDN:  Components.default.imageCDN,
                placeholder: placeholder,
                preferredSize: .avatarThumbnailSize
            )
        } else {
            authorAvatarView.image = placeholder
        }
        avatarViewContainerView.isHidden = true
        if let options = layoutOptions {
            authorNameLabel.isHidden = !options.contains(.authorName)
            timestampLabel.isHidden = !options.contains(.timestamp)
        }
    }
    
    func configData() {
        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel?.text = nil
        }
    }

    @objc func btnSendPacketAction() {
        if walletPaymentType == .request {
            guard let payload = content?.attachments(payloadType: WalletAttachmentPayload.self).first,
                  payload.extraData?.requestedIsPaid == false else {
                return
            }
            if payload.extraData?.recipientUserId == ChatClient.shared.currentUserId {
                Snackbar.show(text: "You can not send one to your own wallet")
                return
            }
            var userInfo = [String: Any]()
            userInfo["transferAmount"] = payload.extraData?.requestedAmount
            userInfo["recipientName"] = payload.extraData?.recipientName
            userInfo["recipientUserId"] = payload.extraData?.recipientUserId
            userInfo["requestedImageUrl"] = payload.extraData?.requestedImageUrl
            userInfo["requestId"] = payload.requestId
            userInfo["channelId"] = channel?.cid
            NotificationCenter.default.post(name: .payRequestTapAction, object: nil, userInfo: userInfo)
        } else {
            guard let channelId = channel?.cid else { return }
            var userInfo = [String: Any]()
            userInfo["channelId"] = channelId
            NotificationCenter.default.post(name: .sendGiftPacketTapAction, object: nil, userInfo: userInfo)
        }
    }
}
