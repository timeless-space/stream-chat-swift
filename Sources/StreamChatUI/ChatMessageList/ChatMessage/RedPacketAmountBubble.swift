//
//  RedPacketAmountBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 06/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class RedPacketAmountBubble: UITableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    private var leadingAnchorForSender: NSLayoutConstraint?
    private var leadingAnchorForReceiver: NSLayoutConstraint?
    private var trailingAnchorForSender: NSLayoutConstraint?
    private var trailingAnchorForReceiver: NSLayoutConstraint?
    var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var client: ChatClient?
    public lazy var dateFormatter = Appearance.default.formatters.messageTimestamp
    public var blockExpAction: ((URL) -> Void)?
    private(set) lazy var btnExplore: UIButton = {
        let exploreButton = UIButton()
        exploreButton.addTarget(self, action: #selector(btnTapExploreAction), for: .touchUpInside)
        exploreButton.setTitle("", for: .normal)
        exploreButton.backgroundColor = .clear
        return exploreButton
    }()

    var isSender = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
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
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.MessageTopPadding)
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

        descriptionLabel = createDescLabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            descriptionLabel.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 8),
            descriptionLabel.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: -8),
        ])
        descriptionLabel.transform = .mirrorY
        descriptionLabel.textAlignment = .left

        btnExplore.translatesAutoresizingMaskIntoConstraints = false
        subContainer.insertSubview(btnExplore, aboveSubview: descriptionLabel)

        btnExplore.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor).isActive = true
        btnExplore.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor).isActive = true
        btnExplore.heightAnchor.constraint(equalToConstant: 25).isActive = true
        btnExplore.topAnchor.constraint(equalTo: descriptionLabel.topAnchor).isActive = true

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

        leadingAnchorForSender = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: cellWidth)
        trailingAnchorForSender = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        leadingAnchorForReceiver = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8)
        trailingAnchorForReceiver = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -cellWidth)
    }

    private func setBubbleConstraints(_ isSender: Bool) {
        leadingAnchorForSender?.isActive = isSender
        leadingAnchorForSender?.constant = cellWidth
        trailingAnchorForSender?.isActive = isSender
        trailingAnchorForSender?.constant = -8
        leadingAnchorForReceiver?.isActive = !isSender
        leadingAnchorForReceiver?.constant = 8
        trailingAnchorForReceiver?.isActive = !isSender
        trailingAnchorForReceiver?.constant = -cellWidth
    }

    @objc func btnTapExploreAction() {
        if let txID = content?.extraData.otherAmountTxId {
            if let blockExpURL = URL(string: "\(Constants.blockExplorer)\(txID)") {
                blockExpAction?(blockExpURL)
            }
        }
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
            descriptionLabel.font = .systemFont(ofSize: 17)
        }
        return descriptionLabel
    }

    func createDetailsLabel() -> UILabel {
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

    func configData(isSender: Bool) {
        setBubbleConstraints(isSender)
        timestampLabel.textAlignment = isSender ? .right : .left
        var nameAndTimeString: String? = ""
        if let options = layoutOptions {
            if options.contains(.authorName), let name = content?.author.name {
                nameAndTimeString?.append("\(name)   ")
            }
            if options.contains(.timestamp) , let createdAt = content?.createdAt {
                nameAndTimeString?.append("\(dateFormatter.format(createdAt))")
            }
        }
        timestampLabel?.text = nameAndTimeString
        configOtherAmount()
    }

    private func configOtherAmount() {
        let strUserId = content?.extraData.otherAmountUserId ?? ""
        var descriptionText = ""
        if strUserId == client?.currentUserId ?? "" {
            // I picked up other amount
            descriptionText = "\(content?.extraData.otherAmountReceivedCongratesKey ?? "") \nYou just picked up \(content?.extraData.otherReceivedAmount?.formattedOneBalance ?? "") ONE! \n\n🧧Red Packet"
        } else {
            // someone pickup amount
            descriptionText = "\(content?.extraData.otherAmountReceivedCongratesKey ?? "") \n\(content?.extraData.otherAmuntReceivedUserName ?? "") just picked up \(content?.extraData.otherReceivedAmount?.formattedOneBalance ?? "") ONE! \n\n🧧Red Packet"
        }

        let imageAttachment = NSTextAttachment()
        if #available(iOS 13.0, *) {
            imageAttachment.image = Appearance.default.images.arrowUpRightSquare?.withTintColor(.white)
        } else {
            // Fallback on earlier versions
        }
        let fullString = NSMutableAttributedString(string: descriptionText + "  ")
        fullString.append(NSAttributedString(attachment: imageAttachment))
        descriptionLabel.attributedText = fullString
    }
}
