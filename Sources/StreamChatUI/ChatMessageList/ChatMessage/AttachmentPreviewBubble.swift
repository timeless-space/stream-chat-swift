//
//  AttachmentPreviewBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 30/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke

class AttachmentPreviewBubble: UITableViewCell, GalleryItemPreview {
    var attachmentId: AttachmentId? {
        return content?.imageAttachments.first?.id
    }

    override var imageView: UIImageView {
        return imagePreview
    }

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var imagePreview: UIImageView!
    public private(set) var timestampLabel: UILabel!
    private var leadingAnchorForSender: NSLayoutConstraint?
    private var trailingAnchorSender: NSLayoutConstraint?
    private var leadingAnchorReceiver: NSLayoutConstraint?
    private var trailingAnchorReceiver: NSLayoutConstraint?
    var layoutOptions: ChatMessageLayoutOptions?
    weak var delegate: PhotoCollectionAction?
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    var isSender = false
    var chatChannel: ChatChannel?
    public private(set) var authorAvatarView: ChatAvatarView?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    private var imageTask: Cancellable? {
        didSet { oldValue?.cancel() }
    }
    public private(set) lazy var loadingIndicator = Components
        .default
        .loadingIndicator
        .init()
        .withoutAutoresizingMaskConstraints

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

        imagePreview = UIImageView()
        imagePreview.backgroundColor = Appearance.default.colorPalette.background6
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        imagePreview.clipsToBounds = true
        imagePreview.transform = .mirrorY
        subContainer.addSubview(imagePreview)
        NSLayoutConstraint.activate([
            imagePreview.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            imagePreview.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            imagePreview.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            imagePreview.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 0),
            imagePreview.heightAnchor.constraint(equalToConstant: 200)
        ])

        timestampLabel = createTimestampLabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(timestampLabel)
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
            timestampLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 15),
        ])
        timestampLabel.transform = .mirrorY

        leadingAnchorForSender = viewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: cellWidth)
        trailingAnchorSender = viewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        leadingAnchorReceiver = viewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)
        trailingAnchorReceiver = viewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -cellWidth)
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(btnTapAttachment))
        viewContainer.addGestureRecognizer(tapGesture)
        addSubview(loadingIndicator)
        loadingIndicator.centerYAnchor.pin(equalTo: imagePreview.centerYAnchor).isActive = true
        loadingIndicator.centerXAnchor.pin(equalTo: imagePreview.centerXAnchor).isActive = true
    }

    @objc private func btnTapAttachment() {
        if let attachmentId = attachmentId {
            delegate?.didSelectAttachment(content, view: self, attachmentId)
        }
    }

    func configureCell(isSender: Bool) {
        loadingIndicator.isVisible = true
        imageTask = Components.default.imageLoader.loadImage(
            into: imagePreview,
            url: content?.imageAttachments.first?.payload.imagePreviewURL,
            imageCDN: Components.default.imageCDN,
            completion: { [weak self] _ in
                self?.imageTask = nil
                self?.loadingIndicator.isVisible = false
            }
        )
        if let options = layoutOptions, let memberCount = chatChannel?.memberCount {
            // Hide Avatar view for one-way chat
            if memberCount <= 2 {
                authorAvatarView?.isHidden = true
            } else {
                authorAvatarView?.isHidden = false
                if !options.contains(.authorName) {
                    authorAvatarView?.imageView.image = nil
                } else {
                    Nuke.loadImage(with: content?.author.imageURL, into: authorAvatarView?.imageView ?? .init())
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
                timestampLabel?.text = authorName + "  " + dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .left
            } else {
                timestampLabel?.text = dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .right
            }
        } else {
            timestampLabel?.text = nil
            timestampLabel?.isHidden = true
        }
        handleBubbleConstraints(isSender)
    }

    private func handleBubbleConstraints(_ isSender: Bool) {
        let memberCount = chatChannel?.memberCount ?? 0
        leadingAnchorForSender?.isActive = isSender
        trailingAnchorSender?.isActive = isSender
        leadingAnchorReceiver?.isActive = !isSender
        trailingAnchorReceiver?.isActive = !isSender
        leadingAnchorReceiver?.constant = memberCount <= 2 ? 25 : 20
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
}
