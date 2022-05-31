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

class PhotoCollectionBubble: _TableViewCell {

    // MARK: Variables
    var content: ChatMessage?
    private let stackedItemsView = StackedItemsView<StackedItem, MediaPreviewCollectionCell>()
    weak var delegate: PhotoCollectionAction?

    public private(set) var timestampLabel: UILabel?
    public var layoutOptions: ChatMessageLayoutOptions?
    private var timestampLabelWidthConstraint: NSLayoutConstraint?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    public lazy var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    public lazy var subContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    public lazy var stickerContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    public private(set) var authorAvatarView: ChatAvatarView?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    var chatChannel: ChatChannel?
    var isSender = false
    public private(set) lazy var loadingIndicator = Components
        .default
        .loadingIndicator
        .init()
        .withoutAutoresizingMaskConstraints

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
        timestampLabelWidthConstraint = timestampLabel?.widthAnchor.constraint(equalToConstant: bounds.width)
        timestampLabelWidthConstraint?.isActive = true
        addGestureRecognizer(stackedItemsView.panGestureRecognizer)

        addSubview(loadingIndicator)
        loadingIndicator.centerYAnchor.pin(equalTo: subContainer.centerYAnchor).isActive = true
        loadingIndicator.centerXAnchor.pin(equalTo: subContainer.centerXAnchor).isActive = true
    }

    func configureCell(isSender: Bool) {
        let attachments = content?.attachments(payloadType: ImageAttachmentPayload.self) ?? []
        if !attachments.filter { $0.uploadingState != nil }.isEmpty {
            loadingIndicator.isVisible = true
            stackedItemsView.isHidden = true
        } else {
            loadingIndicator.isVisible = false
            stackedItemsView.isHidden = false
            stackedItemsView.items = content?.imageAttachments.compactMap {
                StackedItem.init(
                    id: $0.id.index,
                    imageUrl: $0.imageURL,
                    attachmentId: $0.id.rawValue)
            } ?? []
            stackedItemsView.configureItemHandler = { item, cell in
                cell.configureMedia(attachment: item)
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

open class MediaPreviewCollectionCell: UICollectionViewCell, GalleryItemPreview {
    // MARK: Variables
    public var attachmentId: AttachmentId? {
        return AttachmentId(rawValue: attachment.attachmentId ?? "")
    }

    public var imageView: UIImageView {
        return imgPreview
    }
    private var imageTask: Cancellable? {
        didSet { oldValue?.cancel() }
    }
    private var attachment: StackedItem!
    private(set) lazy var imgPreview: UIImageView = {
        let imgPreview = UIImageView()
        imgPreview.clipsToBounds = true
        imgPreview.contentMode = .scaleAspectFill
        imgPreview.translatesAutoresizingMaskIntoConstraints = false
        return imgPreview
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        embed(imgPreview)
    }

    public func configureMedia(attachment: StackedItem) {
        self.attachment = attachment
        imageTask?.cancel()
        imageTask = Components.default.imageLoader.loadImage(
            into: imgPreview,
            url: attachment.imageUrl,
            imageCDN: Components.default.imageCDN,
            placeholder: Appearance.default.images.videoAttachmentPlaceholder,
            completion: { [weak self] result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(_):
                    break
                }
                self?.imageTask = nil
            }
        )
    }
}

protocol PhotoCollectionAction: class  {
    func didSelectAttachment(_ message: ChatMessage?, view: GalleryItemPreview, _ id: AttachmentId)
}

public class StackedItem: Equatable {
    public static func == (lhs: StackedItem, rhs: StackedItem) -> Bool {
        return lhs.id == rhs.id
    }
    public var id: Int
    public var imageUrl: URL
    public var attachmentId: String?

    public init(id: Int, imageUrl: URL, attachmentId: String? = nil) {
        self.id = id
        self.imageUrl = imageUrl
        self.attachmentId = attachmentId
    }

    public static func staticData() -> [StackedItem] {
        var items = [StackedItem]()
        items.append(.init(id: 0, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/shh.png")!))
        items.append(.init(id: 1, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/celebrate.gif")!))
        items.append(.init(id: 2, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/cheers.gif")!))
        items.append(.init(id: 3, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/thanks.png")!))
        return items
    }
}
