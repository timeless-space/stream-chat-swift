//
//  GiftPacketSentBubble.swift
//  StreamChatUI
//
//  Created by Tu Nguyen on 4/18/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit
import StreamChat
import StreamChatUI
import SwiftyGif
import AVKit
import BigInt

class GiftBubble: UITableViewCell {
    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbImageView: UIImageView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    public private(set) var amountLabel: UILabel!
    public private(set) var detailLabel: UILabel!
    public private(set) var titleLabel: UILabel!
    private var detailsStack: UIStackView!

    private var leadingAnchorForSender: NSLayoutConstraint?
    private var leadingAnchorForReceiver: NSLayoutConstraint?
    private var trailingAnchorForSender: NSLayoutConstraint?
    private var trailingAnchorForReceiver: NSLayoutConstraint?

    var options: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var isSender = false
    var player : AVPlayer!
    var playerLayer : AVPlayerLayer!
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    public lazy var claimedFormatter: DateFormatter = .claimedFormatter

    enum Constant {
        static let oneWeiUnit = 1_000_000_000_000_000_000
        static let tokenWeiUnit = 1_000_000
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupUI() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(tap:)))
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        viewContainer.addGestureRecognizer(gesture)
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.MessageTopPadding)
        ])

        leadingAnchorForSender = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: cellWidth)
        leadingAnchorForReceiver = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8)
        trailingAnchorForSender = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        trailingAnchorForReceiver = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -cellWidth)

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
        sentThumbImageView.backgroundColor = .black
        sentThumbImageView.transform = .mirrorY
        sentThumbImageView.contentMode = .scaleAspectFill
        sentThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbImageView.clipsToBounds = true
        subContainer.addSubview(sentThumbImageView)
        NSLayoutConstraint.activate([
            sentThumbImageView.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            sentThumbImageView.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            sentThumbImageView.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            sentThumbImageView.heightAnchor.constraint(equalToConstant: 250)
        ])

        titleLabel = createTitleLabel()
        amountLabel = createAmountLabel()
        detailLabel = createDetailsLabel()
        timestampLabel = createTimestampLabel()

        detailsStack = UIStackView(arrangedSubviews: [titleLabel, amountLabel])
        detailsStack.axis = .horizontal
        detailsStack.distribution = .equalSpacing
        detailsStack.spacing = 2
        subContainer.addSubview(detailsStack)
        detailsStack.transform = .mirrorY
        detailsStack.alignment = .leading
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsStack.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            detailsStack.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -31),
            detailsStack.bottomAnchor.constraint(equalTo: sentThumbImageView.topAnchor, constant: -8),
        ])
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(detailLabel)
        NSLayoutConstraint.activate([
            detailLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            detailLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            detailLabel.bottomAnchor.constraint(equalTo: detailsStack.topAnchor, constant: 0),
            detailLabel.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 10)
        ])
        detailLabel.transform = .mirrorY
        detailLabel.textAlignment = .left

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

    func configureCell(isSender: Bool) {
        self.isSender = isSender
        setBubbleConstraints(isSender)
        setFlair()
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
        timestampLabel.textAlignment = isSender ? .right : .left
    }

    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }

    private func setFlair() {
        guard let extraData = content?.extraData else {
            return
        }
        if self.isVideoType(extraData.flair ?? "") {
            NotificationCenter.default.removeObserver(self,
                                                      name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                      object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didEndPlayback),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: nil)
            let videoURL = URL(string: extraData.flair ?? "")
            player = AVPlayer(url: videoURL!)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = CGRect(x: 0, y: 0, width: 250, height: 250)
            playerLayer.videoGravity = .resizeAspectFill
            sentThumbImageView.layer.addSublayer(playerLayer)
            player.play()
        } else {
            let url = URL(string: extraData.flair ?? "")!
            let loader = UIActivityIndicatorView(style: .white)
            sentThumbImageView.setGifFromURL(url, customLoader: loader)
        }
    }

    private func isVideoType(_ path: String) -> Bool {
        let videos = ["mp4", "avi"]
        let type = String(path.split(separator: ".").last ?? "")
        return videos.contains(type)
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

    private func createTitleLabel() -> UILabel {
        if titleLabel == nil {
            titleLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.textColor = .white
            titleLabel.font = Appearance.default.fonts.bodyBold.withSize(18)
        }
        return titleLabel
    }

    func createAmountLabel() -> UILabel {
        let lblDetails = UILabel()
            .withAdjustingFontForContentSizeCategory
            .withBidirectionalLanguagesSupport
            .withoutAutoresizingMaskConstraints
        lblDetails.textAlignment = .center
        lblDetails.numberOfLines = 0
        lblDetails.textColor = .white
        lblDetails.font = Appearance.default.fonts.bodyBold.withSize(18)
        return lblDetails
    }

    func createDetailsLabel() -> UILabel {
        let lblDetails = UILabel()
            .withAdjustingFontForContentSizeCategory
            .withBidirectionalLanguagesSupport
            .withoutAutoresizingMaskConstraints
        lblDetails.textAlignment = .center
        lblDetails.numberOfLines = 0
        lblDetails.textColor = .white.withAlphaComponent(0.5)
        lblDetails.font = Appearance.default.fonts.body.withSize(13)
        return lblDetails
    }

    func configData() {
        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel?.text = nil
        }
        configGiftPacket()
    }

    private func configGiftPacket() {
        guard let extraData = content?.extraData else {
            return
        }
        titleLabel.text = "Gift Card"
        if let claimedTime = getClaimedAtTime() {
            detailLabel.text = "Claimed at \(claimedTime)"
        } else {
            detailLabel.text = "Tap to claim the gift card"
        }
        if let amount = extraData.giftAmount,
        let bigInt = BigUInt(amount) {
            if extraData.tokenAddress != nil {
                let double = amountFromWeiUnit(amount: bigInt, weiUnit: Constant.tokenWeiUnit)
                amountLabel.text = "\(double) USDC".replacingOccurrences(of: ".0", with: "")
            } else {
                let double = amountFromWeiUnit(amount: bigInt, weiUnit: Constant.oneWeiUnit)
                amountLabel.text = "\(double) ONE".replacingOccurrences(of: ".0", with: "")
            }
        }
    }

    private func getClaimedAtTime() -> String? {
        let claimedAt = content?.extraData.claimedAt ?? ""
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        guard let datee = dateFormatterGet.date(from: claimedAt) else { return nil }
        return claimedFormatter.string(from: datee)
    }

    private func isAllowToPick() -> Bool {
        // check userId
        if content?.isSentByCurrentUser ?? false {
            Snackbar.show(text: "You cannot pickup your own packet")
            return false
        }
        return true
    }

    private func decimalAmountFromWeiUnit(amount: BigUInt, weiUnit: Int) -> Decimal {
        let amountDict = amount.quotientAndRemainder(dividingBy: BigUInt(weiUnit))
        return (Decimal(string: String(amountDict.quotient))!
                + Decimal(string: String(amountDict.remainder))! / Decimal(weiUnit))
    }

    private func amountFromWeiUnit(amount: BigUInt, weiUnit: Int) -> Double {
        // rounding down to 10 decimal digits to avoid rounding issue
        var decimalAmount = decimalAmountFromWeiUnit(amount: amount, weiUnit: weiUnit)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &decimalAmount, 10, .down)
        return NSDecimalNumber(decimal: rounded).doubleValue
    }

    @objc func didTap(tap: UITapGestureRecognizer) {
        guard isAllowToPick(),
              let extraData = content?.extraData,
              extraData.claimedAt == nil,
              isSender == false else {
            return
        }
        NotificationCenter.default.post(name: .claimGiftCardPacketAction, object: nil, userInfo: extraData)
    }

    @objc func didEndPlayback(notification: Notification) {
        player.seek(to: .zero)
        player.play()
    }
}
