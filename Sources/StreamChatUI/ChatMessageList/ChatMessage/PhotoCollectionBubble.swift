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

class PhotoCollectionBubble: UITableViewCell {

    // MARK: Variables
    var content: ChatMessage?
    private var heightConst: NSLayoutConstraint?
    private let stackedItemsView = StackedItemsView<StackedItem, MediaPreviewCollectionCell>()
    public private(set) var viewContainer: UIView!
    weak var delegate: PhotoCollectionAction?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        viewContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        viewContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        backgroundColor = .clear
        selectionStyle = .none
        viewContainer.addSubview(stackedItemsView)
        stackedItemsView.translatesAutoresizingMaskIntoConstraints = false
        stackedItemsView.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 15).isActive = true
        stackedItemsView.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: -15).isActive = true
        stackedItemsView.topAnchor.constraint(equalTo: viewContainer.topAnchor).isActive = true
        stackedItemsView.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor).isActive = true
        addGestureRecognizer(stackedItemsView.panGestureRecognizer)
        heightConst = viewContainer.heightAnchor.constraint(equalToConstant: 280)
        heightConst?.isActive = true

        viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true
        viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
        viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
    }

    func configureCell(isSender: Bool) {
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
        handleBubbleConstraints(isSender)
    }

    private func handleBubbleConstraints(_ isSender: Bool) {
        stackedItemsView.horizontalAlignment = .middle
        stackedItemsView.collectionView.contentInset = .zero
        if stackedItemsView.items.count == 1 {
            if !isSender {
                stackedItemsView.collectionView.contentInset = .init(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    right: stackedItemsView.bounds.width - 250
                )
            } else {
                stackedItemsView.collectionView.contentInset = .init(
                    top: 0,
                    left: stackedItemsView.bounds.width - 250,
                    bottom: 0,
                    right: 0
                )
            }
        } else {
            if !isSender {
                stackedItemsView.horizontalAlignment = .leading
            } else {
                stackedItemsView.horizontalAlignment = .trailing
            }
        }
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
        Nuke.loadImage(with: attachment.imageUrl, into: imgPreview)
    }
}

protocol PhotoCollectionAction: class  {
    func didSelectAttachment(_ message: ChatMessage?, view: MediaPreviewCollectionCell, _ id: AttachmentId)
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
