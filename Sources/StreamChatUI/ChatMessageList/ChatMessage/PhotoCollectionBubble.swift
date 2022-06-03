//
//  PhotoCollectionBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 20/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke
import AVKit

class PhotoCollectionBubble: _TableViewCell {

    // MARK: Variables
    var content: ChatMessage?
    var chatChannel: ChatChannel?
    var isSender = false
    weak var delegate: PhotoCollectionAction?
    private var isLoading = false
    private let stackedItemsView = StackedItemsView<StackedItem, MediaPreviewCollectionCell>()
    private var trailingConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    public private(set) var timestampLabel: UILabel?
    public var layoutOptions: ChatMessageLayoutOptions?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    public lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    public lazy var subContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    public lazy var stickerContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    public private(set) var authorAvatarView: ChatAvatarView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        mainContainer.addArrangedSubviews([createAvatarView(), subContainer])
        mainContainer.alignment = .bottom
        contentView.addSubview(mainContainer)
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            mainContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4)
        ])

        backgroundColor = .clear
        selectionStyle = .none
        stackedItemsView.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addArrangedSubviews([createTimestampLabel(), stackedItemsView])
        subContainer.heightAnchor.constraint(equalToConstant: 280).isActive = true
        subContainer.alignment = .fill
        subContainer.transform = .mirrorY
        stackedItemsView.transform = .mirrorY
        leadingConstraint = mainContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8)
        leadingConstraint?.isActive = true
        trailingConstraint = mainContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        trailingConstraint?.isActive = true
    }

    func configureCell(isSender: Bool) {
        removeGestureRecognizer(stackedItemsView.panGestureRecognizer)
        stackedItemsView.isUserInteractionEnabled = false
        let imgAttachments = content?.attachments(payloadType: ImageAttachmentPayload.self) ?? []
        let videoAttachments = content?.attachments(payloadType: VideoAttachmentPayload.self) ?? []
        if (!imgAttachments.filter { $0.uploadingState != nil }.isEmpty)
        || (!videoAttachments.filter { $0.uploadingState != nil }.isEmpty) {
            isLoading = true
            removeGestureRecognizer(stackedItemsView.panGestureRecognizer)
        } else {
            isLoading = false
            stackedItemsView.isUserInteractionEnabled = true
            addGestureRecognizer(stackedItemsView.panGestureRecognizer)
        }
        let imageAttachment = content?.imageAttachments.compactMap {
            StackedItem.init(
                id: $0.id.index,
                url: $0.imageURL,
                attachmentType: .image,
                attachmentId: $0.id.rawValue)
        } ?? []
        let videoAttachment = content?.videoAttachments.compactMap {
            StackedItem.init(
                id: $0.id.index,
                url: $0.videoURL,
                attachmentType: .video,
                attachmentId: $0.id.rawValue)
        } ?? []
        stackedItemsView.items = (imageAttachment + videoAttachment).sorted(by: { $0.id < $1.id })
        stackedItemsView.configureItemHandler = { item, cell in
            cell.configureMedia(
                attachment: item,
                isExpand: self.stackedItemsView.isExpand,
                isLoading: self.isLoading
            )
            cell.clipsToBounds = true
            cell.cornerRadius = 20
        }
        stackedItemsView.selectionHandler = { [weak self] type, selectedIndex in
            guard let `self` = self, let cell = self.stackedItemsView.cell(at: selectedIndex) else {
                return
            }
            if let id = AttachmentId(rawValue: "\(type.attachmentId ?? "")") {
                self.delegate?.didSelectAttachment(self.content, view: cell, id)
            }
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
                timestampLabel?.text = " " + authorName + "  " + dateFormatter.string(from: createdAt)
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
        if !isSender {
            stackedItemsView.horizontalAlignment = .leading
            timestampLabel?.textAlignment = .left
            stackedItemsView.collectionView.contentInset = .init(
                top: 0,
                left: (memberCount <= 2) ? 0 : -20,
                bottom: 0,
                right: 0
            )
        } else {
            stackedItemsView.horizontalAlignment = .trailing
            timestampLabel?.textAlignment = .right
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

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints

            timestampLabel?.textColor = Appearance.default.colorPalette.subtitleText
            timestampLabel?.font = Appearance.default.fonts.footnote
            timestampLabel?.transform = .mirrorY
        }
        return timestampLabel!
    }
}
