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

class AttachmentPreviewBubble: UITableViewCell {
    var layoutOptions: ChatMessageLayoutOptions?
    weak var delegate: PhotoCollectionAction?
    var content: ChatMessage?
    var isSender = false
    var chatChannel: ChatChannel?
    private lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    private lazy var subContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    private lazy var loadingIndicator = UIActivityIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints
    public private(set) var imagePreview: UIImageView!
    public private(set) var videoPreview: VideoAttachmentGalleryPreview!
    public private(set) var timestampLabel: UILabel!
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    public private(set) var authorAvatarView: ChatAvatarView?
    private var leadingMainContainer: NSLayoutConstraint?
    private var trailingMainContainer: NSLayoutConstraint?
    private var timestampLabelWidthConstraint: NSLayoutConstraint?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    private var isImagePreview: Bool {
        return content?.attachmentCounts[.image] != nil
    }
    private var imageTask: Cancellable? {
        didSet { oldValue?.cancel() }
    }

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
        mainContainer.addArrangedSubviews([createAvatarView(), subContainer])
        mainContainer.alignment = .bottom
        mainContainer.transform = .mirrorY

        contentView.addSubview(mainContainer)
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8),
            mainContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8)
        ])

        subContainer.alignment = .fill
        subContainer.transform = .mirrorY
        leadingMainContainer = mainContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8)
        trailingMainContainer = mainContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        timestampLabelWidthConstraint = timestampLabel?.widthAnchor.constraint(equalToConstant: cellWidth)
        timestampLabelWidthConstraint?.isActive = true
        subContainer.heightAnchor.constraint(equalToConstant: 200).isActive = true
        subContainer.widthAnchor.constraint(equalToConstant: 260).isActive = true

        addSubview(loadingIndicator)
        if #available(iOS 13.0, *) {
            loadingIndicator.style = .medium
        } else {
            // Fallback on earlier versions
        }
        loadingIndicator.tintColor = .white
        loadingIndicator.centerYAnchor.constraint(equalTo: subContainer.centerYAnchor).isActive = true
        loadingIndicator.centerXAnchor.constraint(equalTo: subContainer.centerXAnchor).isActive = true
        loadingIndicator.startAnimating()
        loadingIndicator.transform = .mirrorY

        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(btnTapAttachment))
        mainContainer.addGestureRecognizer(tapGesture)
    }

    @objc private func btnTapAttachment() {
        if let attachmentId = attachmentId {
            delegate?.didSelectAttachment(content, view: self, attachmentId)
        }
    }

    func configureCell(isSender: Bool) {
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = true
        subContainer.removeAllArrangedSubviews()
        if content?.attachmentCounts[.image] == 1 {
            if imagePreview != nil {
                imagePreview.removeFromSuperview()
            }
            imagePreview = UIImageView()
            imagePreview.backgroundColor = Appearance.default.colorPalette.background6
            imagePreview.contentMode = .scaleAspectFill
            imagePreview.transform = .mirrorY
            imagePreview.clipsToBounds = true
            imagePreview.layer.cornerRadius = 12
            loadingIndicator.isHidden = false
            imageTask = Components.default.imageLoader.loadImage(
                into: imagePreview,
                url: content?.imageAttachments.first?.payload.imagePreviewURL,
                imageCDN: Components.default.imageCDN,
                completion: { [weak self] _ in
                    self?.imageTask = nil
                    self?.loadingIndicator.isHidden = true
                }
            )
            subContainer.addArrangedSubviews([createTimestampLabel(), imageView])
        } else {
            // Remove videoPreview to avoid thumbnail duplication issue
            if videoPreview != nil {
                videoPreview.removeFromSuperview()
            }
            videoPreview = VideoAttachmentGalleryPreview()
            videoPreview.transform = .mirrorY
            videoPreview.clipsToBounds = true
            videoPreview.layer.cornerRadius = 12
            subContainer.addArrangedSubviews([createTimestampLabel(), videoPreview])
            videoPreview.didTapOnAttachment = { [weak self] attachment in
                guard let `self` = self else { return }
                self.delegate?.didSelectAttachment(self.content, view: self, attachment.id)
            }
            let videoAttachments = content?.attachments(payloadType: VideoAttachmentPayload.self).first
            videoPreview.content = videoAttachments
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
        if let authorAvatarView = authorAvatarView {
            mainContainer.setCustomSpacing((memberCount <= 2) ? 20 : 8, after: authorAvatarView)
        }
        leadingMainContainer?.isActive = !isSender
        trailingMainContainer?.isActive = isSender
        timestampLabelWidthConstraint?.constant = cellWidth
        timestampLabel.textAlignment = !isSender ? .left : .right
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

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            timestampLabel.textAlignment = .left
            timestampLabel!.textColor = Appearance.default.colorPalette.subtitleText
            timestampLabel!.font = Appearance.default.fonts.footnote
            timestampLabel.numberOfLines = 1
        }
        timestampLabel.transform = .mirrorY
        timestampLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        timestampLabel.trailingAnchor.constraint(equalTo: self.subContainer.leadingAnchor, constant: -30)
        return timestampLabel!
    }
}

extension AttachmentPreviewBubble: GalleryItemPreview {
    var attachmentId: AttachmentId? {
        return isImagePreview
        ? content?.imageAttachments.first?.id
        : content?.videoAttachments.first?.id
    }

    override var imageView: UIImageView {
        return isImagePreview
        ? imagePreview
        : videoPreview.imageView
    }
}
