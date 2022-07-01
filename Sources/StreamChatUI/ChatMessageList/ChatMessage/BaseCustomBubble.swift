//
//  BaseCustomBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 08/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

class BaseCustomBubble: _TableViewCell {
    // MARK: Variables
    private var trailingAnchorSender: NSLayoutConstraint?
    private var leadingAnchorReceiver: NSLayoutConstraint?
    private var widthAnchorCell: NSLayoutConstraint?
    private var layoutOptions: ChatMessageLayoutOptions?
    private lazy var dateFormatter: DateFormatter = .makeDefault()
    private var authorAvatarView: ChatAvatarView?
    private var timestampLabel: UILabel!
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    private var timestampLabelWidthConstraint: NSLayoutConstraint?
    public var content: ChatMessage?
    private var chatChannel: ChatChannel?
    private lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    private lazy var container = UIView
        .init()
        .withoutAutoresizingMaskConstraints

    var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }
    private var imageLoader = Components.default.imageLoader

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setLayout() {
        contentView.transform = .mirrorY
        selectionStyle = .none
        backgroundColor = .clear
        mainContainer.addArrangedSubviews([createAvatarView(), container])
        mainContainer.backgroundColor = .yellow
        mainContainer.alignment = .bottom
        contentView.addSubview(mainContainer)
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            mainContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4),
            mainContainer.heightAnchor.constraint(equalToConstant: 200)
        ])
        trailingAnchorSender = mainContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: Constants.MessageRightPadding)
        leadingAnchorReceiver = mainContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: Constants.MessageLeftPadding)
        widthAnchorCell = container.widthAnchor.constraint(equalToConstant: cellWidth)
        widthAnchorCell?.isActive = true
    }

    public func addContainerView(_ view: UIView) {
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    private func handleBubbleConstraints(_ isSender: Bool) {
        trailingAnchorSender?.isActive = isSender
        leadingAnchorReceiver?.isActive = !isSender
        timestampLabelWidthConstraint?.constant = cellWidth
        widthAnchorCell?.constant = cellWidth
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

    func configureCell(
        isSender: Bool,
        content: ChatMessage?,
        chatChannel: ChatChannel?,
        layoutOptions: ChatMessageLayoutOptions?
    ) {
        self.content = content
        self.chatChannel = chatChannel
        self.layoutOptions = layoutOptions
        handleBubbleConstraints(isSender)
        if isSender {
            authorAvatarView?.isHidden = true
        } else {
            authorAvatarView?.isHidden = false
        }
        if let options = layoutOptions, let memberCount = chatChannel?.memberCount {
            // Hide Avatar view for one-way chat
            if memberCount <= 2 {
                authorAvatarView?.isHidden = true
            } else {
                authorAvatarView?.isHidden = false
                if !options.contains(.authorName) {
                    authorAvatarView?.imageView.image = nil
                } else {
                    imageLoader.loadImage(
                        into: authorAvatarView?.imageView ?? UIImageView(),
                        url: content?.author.imageURL,
                        imageCDN: Components.default.imageCDN,
                        placeholder: nil,
                        preferredSize: nil
                    )
                }
            }
            timestampLabel?.isHidden = !options.contains(.timestamp)
        }
        if let createdAt = content?.createdAt,
            let authorName = content?.author.name?.trimStringBy(count: 15),
            let memberCount = chatChannel?.memberCount {
            var authorName = (memberCount <= 2) ? "" : authorName
            // Add extra white space in leading
            if !isSender {
                timestampLabel?.text = " " + authorName + "  " + dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .left
            } else {
                timestampLabel?.text = dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .right
            }
        } else {
            timestampLabel?.text = nil
        }
    }

    private func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = Components.default
                .avatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        authorAvatarView?.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width).isActive = true
        authorAvatarView?.heightAnchor.pin(equalToConstant: messageAuthorAvatarSize.height).isActive = true
        return authorAvatarView!
    }

}
