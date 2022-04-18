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

class GiftBubble: UITableViewCell {
    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbImageView: UIImageView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    public private(set) var sentCryptoLabel: UILabel!
    public private(set) var pickUpButton: UIButton!
    public private(set) var lblTotal: UILabel!
    public private(set) var lblMax: UILabel!
    public private(set) var lblDetails: UILabel!
    public private(set) var lblExpire: UILabel!
    private var detailsStack: UIStackView!
    var options: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var isSender = false
    public lazy var dateFormatter: DateFormatter = .makeDefault()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configureCell(isSender: Bool) {
        self.isSender = isSender
        if #available(iOS 13.0, *) {
            let uiview = UIHostingController(rootView: GiftPacketSendBubble())
            uiview.view?.backgroundColor = .clear
            uiview.view.transform = .mirrorY
            self.contentView.fit(subview: uiview.view)
        } else {
            // Fallback on earlier versions
        }
//        viewContainer = UIView()
//        viewContainer.translatesAutoresizingMaskIntoConstraints = false
//        viewContainer.backgroundColor = .clear
//        viewContainer.clipsToBounds = true
//        contentView.addSubview(viewContainer)
//        NSLayoutConstraint.activate([
//            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
//            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.MessageTopPadding)
//        ])
//        if isSender {
//            viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: cellWidth).isActive = true
//            viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true
//        } else {
//            viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
//            viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -cellWidth).isActive = true
//        }
//
//        subContainer = UIView()
//        subContainer.translatesAutoresizingMaskIntoConstraints = false
//        subContainer.backgroundColor = Appearance.default.colorPalette.background6
//        subContainer.layer.cornerRadius = 12
//        subContainer.clipsToBounds = true
//        viewContainer.addSubview(subContainer)
//        NSLayoutConstraint.activate([
//            subContainer.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor, constant: 0),
//            subContainer.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
//            subContainer.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
//        ])
//
//        sentThumbImageView = UIImageView()
//        sentThumbImageView.backgroundColor = Appearance.default.colorPalette.background6
//        sentThumbImageView.image = Appearance.default.images.redPacketThumb
//        sentThumbImageView.transform = .mirrorY
//        sentThumbImageView.contentMode = .scaleAspectFill
//        sentThumbImageView.translatesAutoresizingMaskIntoConstraints = false
//        sentThumbImageView.clipsToBounds = true
//        subContainer.addSubview(sentThumbImageView)
//        NSLayoutConstraint.activate([
//            sentThumbImageView.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
//            sentThumbImageView.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
//            sentThumbImageView.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
//            sentThumbImageView.heightAnchor.constraint(equalToConstant: 250)
//        ])
//
//        descriptionLabel = createDescLabel()
//        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
//        subContainer.addSubview(descriptionLabel)
//        NSLayoutConstraint.activate([
//            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
//            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
//            descriptionLabel.bottomAnchor.constraint(equalTo: sentThumbImageView.topAnchor, constant: -8),
//        ])
//        descriptionLabel.transform = .mirrorY
//        descriptionLabel.textAlignment = .left
//
//        lblTotal = createDetailsLabel()
//        lblExpire = createDetailsLabel()
//
//        detailsStack = UIStackView(arrangedSubviews: [lblTotal, lblExpire])
//        detailsStack.axis = .vertical
//        detailsStack.distribution = .fillEqually
//        detailsStack.spacing = 2
//        subContainer.addSubview(detailsStack)
//        detailsStack.transform = .mirrorY
//        detailsStack.alignment = .leading
//        detailsStack.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            detailsStack.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
//            detailsStack.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -10),
//            detailsStack.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -10)
//        ])
//
//        pickUpButton = UIButton()
//        pickUpButton.translatesAutoresizingMaskIntoConstraints = false
//        pickUpButton.setTitle("Claim", for: .normal)
//        pickUpButton.setTitleColor(.white, for: .normal)
//        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
//        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
//        pickUpButton.clipsToBounds = true
//        pickUpButton.layer.cornerRadius = 20
//        pickUpButton.isUserInteractionEnabled = true
//        pickUpButton.addTarget(self, action: #selector(btnPickButtonAction), for: .touchUpInside)
//        subContainer.addSubview(pickUpButton)
//        NSLayoutConstraint.activate([
//            pickUpButton.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 12),
//            pickUpButton.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -12),
//            pickUpButton.heightAnchor.constraint(equalToConstant: 40),
//            pickUpButton.bottomAnchor.constraint(equalTo: detailsStack.topAnchor, constant: -20),
//            pickUpButton.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 20)
//        ])
//        pickUpButton.transform = .mirrorY
//
//        timestampLabel = createTimestampLabel()
//        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
//        viewContainer.addSubview(timestampLabel)
//        timestampLabel.textAlignment = isSender ? .right : .left
//        NSLayoutConstraint.activate([
//            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
//            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
//            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
//            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
//            timestampLabel.heightAnchor.constraint(equalToConstant: 15)
//        ])
//        timestampLabel.transform = .mirrorY
    }

//    private var cellWidth: CGFloat {
//        return UIScreen.main.bounds.width * 0.3
//    }
//
//    private func createTimestampLabel() -> UILabel {
//        if timestampLabel == nil {
//            timestampLabel = UILabel()
//                .withAdjustingFontForContentSizeCategory
//                .withBidirectionalLanguagesSupport
//                .withoutAutoresizingMaskConstraints
//            timestampLabel.textAlignment = .right
//            timestampLabel!.textColor = Appearance.default.colorPalette.subtitleText
//            timestampLabel!.font = Appearance.default.fonts.footnote
//        }
//        return timestampLabel!
//    }
//
//    private func createDescLabel() -> UILabel {
//        if descriptionLabel == nil {
//            descriptionLabel = UILabel()
//                .withAdjustingFontForContentSizeCategory
//                .withBidirectionalLanguagesSupport
//                .withoutAutoresizingMaskConstraints
//            descriptionLabel.textAlignment = .center
//            descriptionLabel.numberOfLines = 0
//            descriptionLabel.textColor = Appearance.default.colorPalette.redPacketColor
//            descriptionLabel.font = Appearance.default.fonts.subheadlineBold.withSize(16)
//        }
//        return descriptionLabel
//    }
//
//    func createDetailsLabel() -> UILabel {
//        let lblDetails = UILabel()
//            .withAdjustingFontForContentSizeCategory
//            .withBidirectionalLanguagesSupport
//            .withoutAutoresizingMaskConstraints
//        lblDetails.textAlignment = .center
//        lblDetails.numberOfLines = 0
//        lblDetails.textColor = .white.withAlphaComponent(0.6)
//        lblDetails.font = Appearance.default.fonts.body.withSize(11)
//        return lblDetails
//    }
//
//    private func createSentCryptoLabel() -> UILabel {
//        if sentCryptoLabel == nil {
//            sentCryptoLabel = UILabel()
//                .withAdjustingFontForContentSizeCategory
//                .withBidirectionalLanguagesSupport
//                .withoutAutoresizingMaskConstraints
//            sentCryptoLabel.textAlignment = .center
//            sentCryptoLabel.numberOfLines = 0
//            sentCryptoLabel.textColor = Appearance.default.colorPalette.subtitleText
//            sentCryptoLabel.font = Appearance.default.fonts.footnote.withSize(11)
//        }
//        return sentCryptoLabel
//    }
//
//    func configData() {
//        if let createdAt = content?.createdAt {
//            timestampLabel?.text = dateFormatter.string(from: createdAt)
//        } else {
//            timestampLabel?.text = nil
//        }
//        configRedPacket()
//    }
//
//    private func configRedPacket() {
//        guard let extraData = content?.extraData else {
//            return
//        }
//        descriptionLabel.text = extraData.giftTitle
//        if let maxOne = extraData.giftAmount {
//            lblTotal.text = "Total: \(maxOne) ONE"
//        } else {
//            lblTotal.text = "Total: 0 ONE"
//        }
//        lblExpire.text = "Expires in \(Constants.redPacketExpireTime) minutes!"
//    }
//
//    private func getEndTime() -> Date? {
//        let strEndTime = content?.extraData.giftEndTime ?? ""
//        if let date = ISO8601DateFormatter.redPacketExpirationFormatter.date(from: "\(strEndTime)") {
//            return date
//        } else {
//            return nil
//        }
//    }
//
//    private func isAllowToPick() -> Bool {
//        // check userId
//        if content?.isSentByCurrentUser ?? false {
//            Snackbar.show(text: "You can not pickup your own packet")
//            return false
//        } else {
//            // check end time
//            if let endDate = getEndTime() {
//                let minutes = Date().minutesFromCurrentDate(endDate)
//                if minutes <= 0 {
//                    Snackbar.show(text: "", messageType: StreamChatMessageType.RedPacketExpired)
//                    return false
//                } else {
//                    return true
//                }
//            } else {
//                Snackbar.show(text: "", messageType: StreamChatMessageType.RedPacketExpired)
//                return false
//            }
//        }
//    }
//
//    @objc private func btnPickButtonAction() {
//        guard isAllowToPick(),
//              let extraData = content?.extraData,
//              isSender == false else {
//            return
//        }
//        NotificationCenter.default.post(name: .pickUpGiftPacket, object: nil, userInfo: extraData)
//    }
}

extension UIView {
    func fit(subview: UIView, horizontalPadding: CGFloat = 0, verticalPadding: CGFloat = 0) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.willMove(toSuperview: self)
        addSubview(subview)
        addConstraints(NSLayoutConstraint
                        .constraints(withVisualFormat: "H:|-(\(horizontalPadding))-[subview]-(\(horizontalPadding))-|",
                                     options: [],
                                     metrics: nil,
                                     views: ["subview": subview]))
        addConstraints(NSLayoutConstraint
                        .constraints(withVisualFormat: "V:|-(\(verticalPadding))-[subview]-(\(verticalPadding))-|",
                                     options: [],
                                     metrics: nil,
                                     views: ["subview": subview]))
        subview.didMoveToSuperview()
    }
}

@available(iOS 13.0.0, *)
struct GiftPacketSendBubble: View {
    var body: some View {
        HStack {
            Spacer()
            if #available(iOS 15.0, *) {
                VStack(alignment: .leading) {
                    Image(uiImage: Appearance.default.images.redPacket)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 274, height: 227)
                        .clipped()
                    HStack {
                        Text("Gift Card")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.white)
                        Spacer()
                        Text("50 ONE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.white)
                    }
                    .padding(.trailing, 31)
                    Text("Tap to claim the gift card")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .frame(width: 274, height: 282)
                .background(Color(uiColor: Appearance.default.colorPalette.background6).cornerRadius(20))
            } else {
                // Fallback on earlier versions
            }
        }
        .padding(.bottom, 20)
    }
}
