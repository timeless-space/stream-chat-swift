//
//  CryptoSentBubble.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 29/10/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

class CryptoSentBubble: UITableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbImageView: UIImageView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    public private(set) var sentCryptoLabel: UILabel!
    public private(set) var blockExplorerButton: UIButton!
    var options: ChatMessageLayoutOptions?
    var content: ChatMessage?
    let imageLoader = Components.default.imageLoader
    public lazy var dateFormatter = Appearance.default.formatters.messageTimestamp
    public var blockExpAction: ((URL) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setLayout() {
        selectionStyle = .none
        backgroundColor = .clear

        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.MessageTopPadding),
            viewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: cellWidth),
            viewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        ])

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

        sentThumbImageView = UIImageView()
        sentThumbImageView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbImageView.image = nil
        sentThumbImageView.contentMode = .scaleAspectFill
        sentThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbImageView.clipsToBounds = true
        subContainer.addSubview(sentThumbImageView)
        NSLayoutConstraint.activate([
            sentThumbImageView.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            sentThumbImageView.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            sentThumbImageView.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            sentThumbImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        sentThumbImageView.transform = .mirrorY
        descriptionLabel = createDescLabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            descriptionLabel.bottomAnchor.constraint(equalTo: sentThumbImageView.topAnchor, constant: -8),
        ])
        descriptionLabel.transform = .mirrorY

        sentCryptoLabel = createSentCryptoLabel()
        sentCryptoLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(sentCryptoLabel)
        NSLayoutConstraint.activate([
            sentCryptoLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 4),
            sentCryptoLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            sentCryptoLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -6),
        ])
        sentCryptoLabel.transform = .mirrorY

        blockExplorerButton = UIButton()
        blockExplorerButton.addTarget(self, action: #selector(check), for: .touchUpInside)
        blockExplorerButton.translatesAutoresizingMaskIntoConstraints = false
        blockExplorerButton.setTitle("Block Explorer", for: .normal)
        blockExplorerButton.setTitleColor(.white, for: .normal)
        blockExplorerButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        blockExplorerButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        blockExplorerButton.clipsToBounds = true
        blockExplorerButton.layer.cornerRadius = 16
        subContainer.addSubview(blockExplorerButton)
        NSLayoutConstraint.activate([
            blockExplorerButton.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 12),
            blockExplorerButton.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -12),
            blockExplorerButton.heightAnchor.constraint(equalToConstant: 32),
            blockExplorerButton.bottomAnchor.constraint(equalTo: sentCryptoLabel.bottomAnchor, constant: -30),
            blockExplorerButton.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 22)
        ])
        blockExplorerButton.transform = .mirrorY

        timestampLabel = createTimestampLabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(timestampLabel)
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
            timestampLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
        timestampLabel.transform = .mirrorY
    }

    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }

    @objc private func check() {
        let rawTxId = content?.extraData.sentOneTxId as? String ?? ""
        if let blockExpURL = URL(string: "\(Constants.blockExplorer)\(rawTxId)") {
            blockExpAction?(blockExpURL)
        }
    }

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            timestampLabel.textAlignment = .right
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

    private func createSentCryptoLabel() -> UILabel {
        if sentCryptoLabel == nil {
            sentCryptoLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            sentCryptoLabel.textAlignment = .center
            sentCryptoLabel.numberOfLines = 0
            sentCryptoLabel.textColor = .white.withAlphaComponent(0.6)
            sentCryptoLabel.font = Appearance.default.fonts.footnote.withSize(11)
        }
        return sentCryptoLabel
    }

    func configData() {
        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.format(createdAt)
        } else {
            timestampLabel?.text = nil
        }
        configOneWallet()
    }

    private func configOneWallet() {
        let recipientName = content?.extraData.sentOneRecipientName ?? ""
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = Appearance.default.images.senOneImage
        let fullString = NSMutableAttributedString(string: "You ")
        fullString.append(NSAttributedString(attachment: imageAttachment))
        fullString.append(NSAttributedString(string: " \(recipientName)"))
        descriptionLabel.attributedText = fullString
        let one = content?.extraData.sentOneTransferAmount ?? "0"
        sentCryptoLabel.text = "SENT: \(one.formattedOneBalance) ONE"
        let defaultURL = WalletAttachmentPayload.PaymentTheme.none.getPaymentThemeUrl()
        let themeURL = content?.extraData.sentOnePaymentTheme ?? "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/shh.png"
        if let imageUrl = URL(string: themeURL) {
            if imageUrl.pathExtension == "gif" {
                sentThumbImageView.setGifFromURL(imageUrl)
            } else {
                imageLoader.loadImage(
                    into: sentThumbImageView,
                    url: imageUrl,
                    imageCDN: StreamImageCDN(),
                    placeholder: nil)
            }
        } else {
            imageLoader.loadImage(
                into: sentThumbImageView,
                url: URL(string: defaultURL),
                imageCDN: StreamImageCDN(),
                placeholder: nil)
        }
    }
}
