//
//  StickerGiftTableViewCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 06/04/22.
//

import UIKit
import StreamChat
import Nuke
import Stipop

class StickerGiftBubble: UITableViewCell {

    // MARK: - Variables
    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var imgStickerPreview: UIImageView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    public private(set) var pickUpButton: UIButton!
    public private(set) var lblDetails: UILabel!
    private var detailsStack: UIStackView!
    var content: ChatMessage?
    var isSender = false
    var channel: ChatChannel?
    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }

    // MARK: - Overrides
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Custom functions
    func configureCell(isSender: Bool) {
        self.isSender = isSender
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.MessageTopPadding)
        ])
        if isSender {
            viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: cellWidth).isActive = true
            viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: Constants.MessageRightPadding).isActive = true
        } else {
            viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: Constants.MessageLeftPadding).isActive = true
            viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -cellWidth).isActive = true
        }
        // SubContainer view
        subContainer = UIView()
        subContainer.translatesAutoresizingMaskIntoConstraints = false
        subContainer.backgroundColor = Appearance.default.colorPalette.background6
        subContainer.layer.cornerRadius = 12
        subContainer.clipsToBounds = true
        viewContainer.addSubview(subContainer)
        NSLayoutConstraint.activate([
            subContainer.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor, constant: 0),
            subContainer.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            subContainer.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
        ])
        // Sticker preview
        imgStickerPreview = UIImageView()
        imgStickerPreview.backgroundColor = Appearance.default.colorPalette.background6
        imgStickerPreview.transform = .mirrorY
        imgStickerPreview.contentMode = .scaleAspectFit
        imgStickerPreview.translatesAutoresizingMaskIntoConstraints = false
        imgStickerPreview.clipsToBounds = true
        subContainer.addSubview(imgStickerPreview)
        NSLayoutConstraint.activate([
            imgStickerPreview.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            imgStickerPreview.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            imgStickerPreview.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            imgStickerPreview.heightAnchor.constraint(equalToConstant: 200)
        ])
        // Desc label
        descriptionLabel = createDescLabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            descriptionLabel.bottomAnchor.constraint(equalTo: imgStickerPreview.topAnchor, constant: -11),
        ])
        descriptionLabel.transform = .mirrorY
        descriptionLabel.textAlignment = .center
        lblDetails = createDetailsLabel()
        Nuke.loadImage(with: content?.extraData.giftPackageImage, into: imgStickerPreview)
        lblDetails.text = content?.extraData.giftPackageName
        // Details stack
        detailsStack = UIStackView(arrangedSubviews: [lblDetails])
        detailsStack.axis = .vertical
        detailsStack.distribution = .fillEqually
        detailsStack.spacing = 0
        subContainer.addSubview(detailsStack)
        detailsStack.transform = .mirrorY
        detailsStack.alignment = .center
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsStack.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            detailsStack.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -10),
            detailsStack.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -6)
        ])
        // Sent/Accept button
        pickUpButton = UIButton()
        pickUpButton.translatesAutoresizingMaskIntoConstraints = false
        if content?.extraData.giftSenderId == ChatClient.shared.currentUserId?.string {
            pickUpButton.alpha = 0.5
            pickUpButton.isEnabled = false
            pickUpButton.setTitle("Sent", for: .normal)
        } else {
            pickUpButton.alpha = 1.0
            pickUpButton.isEnabled = true
            pickUpButton.setTitle("Accept", for: .normal)
        }
        pickUpButton.addTarget(self, action: #selector(btnGifPickupAction), for: .touchUpInside)
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        pickUpButton.clipsToBounds = true
        pickUpButton.layer.cornerRadius = 16
        subContainer.addSubview(pickUpButton)
        NSLayoutConstraint.activate([
            pickUpButton.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 12),
            pickUpButton.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -12),
            pickUpButton.heightAnchor.constraint(equalToConstant: (content?.extraData.isDownloaded ?? false) ? 0 : 32),
            pickUpButton.bottomAnchor.constraint(equalTo: detailsStack.topAnchor, constant: -15),
            pickUpButton.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 20)
        ])
        pickUpButton.transform = .mirrorY
        // TimeStamp
        timestampLabel = createTimestampLabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(timestampLabel)
        timestampLabel.textAlignment = isSender ? .right : .left
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
            timestampLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
        if content?.extraData.isDownloaded ?? false {
            if isSender {
                descriptionLabel.text = "You have downloaded \(content?.extraData.giftPackageName ?? "") sticker."
            } else {
                descriptionLabel.text = "\(content?.extraData.giftReceiverName?.firstUppercased ?? "") has downloaded \(content?.extraData.giftPackageName ?? "") sticker."
            }
        } else {
            if isSender {
                descriptionLabel.text = "You sent sticker to \(content?.extraData.giftSenderName ?? "")"
            } else {
                descriptionLabel.text = "\(content?.extraData.giftSenderName?.firstUppercased ?? "") has sent you sticker gift."
            }
        }
        timestampLabel.transform = .mirrorY
    }

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            timestampLabel.textAlignment = .left
            timestampLabel!.textColor = Appearance.default.colorPalette.subtitleText
            timestampLabel!.font = Appearance.default.fonts.footnote
        }
        return timestampLabel!
    }

    private func createDescLabel() -> UILabel {
        if descriptionLabel == nil {
            descriptionLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            descriptionLabel.textAlignment = .center
            descriptionLabel.numberOfLines = 0
            descriptionLabel.textColor = .white
            descriptionLabel.font = Appearance.default.fonts.subheadlineBold.withSize(16)
        }
        return descriptionLabel
    }

    private func createDetailsLabel() -> UILabel {
        let lblDetails = UILabel()
            .withAdjustingFontForContentSizeCategory
            .withBidirectionalLanguagesSupport
            .withoutAutoresizingMaskConstraints
        lblDetails.textAlignment = .center
        lblDetails.numberOfLines = 0
        lblDetails.textColor = .white.withAlphaComponent(0.6)
        lblDetails.font = Appearance.default.fonts.body.withSize(11)
        return lblDetails
    }

    @objc private func btnGifPickupAction() {
        if content?.extraData.giftSenderId == ChatClient.shared.currentUserId?.string {
            Snackbar.show(text: "You can not send sticker to your own account")
        } else {
            if #available(iOS 13.0, *) {
                StickerApiClient.confirmGiftSticker(
                    packageId: Int(content?.extraData.giftPackageId ?? "0") ?? 0,
                    sendUserId: content?.extraData.giftSenderId ?? "",
                    receiveUserId: content?.extraData.giftReceiverId ?? ""
                ) { result in
                    // download gift package
                    StickerApiClient.downloadGiftPackage(packageId: Int(self.content?.extraData.giftPackageId ?? "0") ?? 0, receiverUserId: ChatClient.shared.currentUserId ?? "") { [weak self] result in
                        guard let `self` = self else { return }
                        if result.header?.status == ResultType.warning.rawValue {
                            Snackbar.show(text: "duplicate Purchase Sticker!", messageType: nil)
                        } else {
                            Snackbar.show(text: "Stickers added!", messageType: nil)
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

    private func sendDownloadSticker() {
        guard let cidDescription = content?.extraData.channelId,
              var extraData = content?.extraData.sendStickerGiftExtraData as? [String: RawJSON],
              let cid = try? ChannelId(cid: cidDescription) else { return }
        var downloadExtraData = extraData
        downloadExtraData["isDownloaded"] = RawJSON.bool(true)
        ChatClient.shared.channelController(for: cid)
            .createNewMessage(
            text: "",
            pinning: nil,
            attachments: [],
            extraData: ["sendStickerGift": .dictionary(downloadExtraData)],
            completion: nil)
    }
}
