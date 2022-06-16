//
//  PhotoCollectionBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 20/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import AVKit

class PhotoCollectionBubble: _TableViewCell {

    // MARK: Variables
    var content: ChatMessage?
    var chatChannel: ChatChannel?
    var isSender = false
    let stackedItemsView = StackedItemsView<StackedItem, MediaPreviewCollectionCell>()
    weak var delegate: PhotoCollectionAction?
    private var isLoading = false
    private var trailingConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    public private(set) var timestampLabel: UILabel?
    public var layoutOptions: ChatMessageLayoutOptions?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    private lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    private lazy var subContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    private var authorAvatarView: ChatAvatarView?
    private let imageLoader = Components.default.imageLoader

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
            mainContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8),
            mainContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8)
        ])

        backgroundColor = .clear
        selectionStyle = .none
        stackedItemsView.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addArrangedSubviews([createTimestampLabel(), stackedItemsView])
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
        handleBubbleConstraints(isSender)
        stackedItemsView.items = (imageAttachment + videoAttachment).sorted(by: { $0.id < $1.id })
        stackedItemsView.configureItemHandler = { item, cell in
            cell.clipsToBounds = true
            cell.cornerRadius = 20
            guard let item = item else {
                cell.configureLastAction()
                return
            }
            cell.configureMedia(
                attachment: item,
                isExpand: self.stackedItemsView.isExpand,
                isLoading: self.isLoading
            )
        }
        stackedItemsView.setupCollectionFlowLayout(isSender)
        stackedItemsView.selectionHandler = { [weak self] type, selectedIndex in
            guard let `self` = self,
                  let cell = self.stackedItemsView.cell(at: selectedIndex),
                  let type = type else {
                      self?.stackedItemsView.setupCollectionFlowLayout(isSender, animation: true)
                      UIView.animate(withDuration: 0.5) {
                        self?.stackedItemsView.layoutSubviews()
                      }
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
                    imageLoader.loadImage(
                        into: authorAvatarView?.imageView ?? .init(),
                        url: content?.author.imageURL,
                        imageCDN: StreamImageCDN(),
                        placeholder: Appearance.default.images.userAvatarPlaceholder4)

                }
            }
            timestampLabel?.isHidden = !options.contains(.timestamp)
        }
        if let createdAt = content?.createdAt,
            let authorName = content?.author.name?.trimStringBy(count: 15),
            let memberCount = chatChannel?.memberCount {
            var authorName = (memberCount <= 2) ? "     " : authorName
            // Add extra white space in leading
            if !isSender {
                timestampLabel?.text = " " + authorName + "  " + dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .left
                authorAvatarView?.isHidden = false
            } else {
                timestampLabel?.text = dateFormatter.string(from: createdAt)
                timestampLabel?.textAlignment = .right
                authorAvatarView?.isHidden = true
            }
        } else {
            timestampLabel?.text = nil
            timestampLabel?.isHidden = true
        }
    }

    private func handleBubbleConstraints(_ isSender: Bool) {
        let memberCount = chatChannel?.memberCount ?? 0
        if !isSender {
            stackedItemsView.horizontalAlignment = .leading
            timestampLabel?.textAlignment = .left
            stackedItemsView.leftPadding = (memberCount <= 2) ? -20 : 0
        } else {
            stackedItemsView.horizontalAlignment = .trailing
            timestampLabel?.textAlignment = .right
            stackedItemsView.leftPadding = 0
        }
        stackedItemsView.layoutSubviews()
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
