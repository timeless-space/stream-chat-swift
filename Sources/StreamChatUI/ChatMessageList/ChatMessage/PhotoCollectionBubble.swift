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
    private let stackedItemsView = StackedItemsView<ChatMessageImageAttachment, MediaPreviewCollectionCell>()
    private var leadingAnchorForSender: NSLayoutConstraint?
    private var trailingAnchorSender: NSLayoutConstraint?
    private var leadingAnchorReceiver: NSLayoutConstraint?
    private var trailingAnchorReceiver: NSLayoutConstraint?
    public private(set) var viewContainer: UIView!
    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
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
        heightConst = viewContainer.heightAnchor.constraint(equalToConstant: 230)
        heightConst?.isActive = true

        leadingAnchorForSender = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor)
        trailingAnchorSender = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        leadingAnchorReceiver = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8)
        trailingAnchorReceiver = viewContainer.trailingAnchor.constraint(
            equalTo: self.contentView.trailingAnchor)
    }

    func configureCell(isSender: Bool) {
        stackedItemsView.items = content?.imageAttachments ?? []
        heightConst?.constant = 260
        if stackedItemsView.items.count > 1 {
            heightConst?.constant = 280
        }
        stackedItemsView.configureItemHandler = { item, cell in
            cell.configureMedia(attachment: item)
            cell.clipsToBounds = true
            cell.cornerRadius = 20
        }
        stackedItemsView.selectionHandler = { [weak self] type, selectedIndex in
            guard let `self` = self, let cell = self.stackedItemsView.cell(at: selectedIndex) else {
                return
            }
            self.delegate?.didSelectAttachment(self.content, view: cell, type.id)
        }
        handleBubbleConstraints(isSender)
    }

    private func handleBubbleConstraints(_ isSender: Bool) {
        leadingAnchorForSender?.isActive = isSender
        trailingAnchorSender?.isActive = isSender
        leadingAnchorReceiver?.isActive = !isSender
        trailingAnchorReceiver?.isActive = !isSender
        if !isSender {
            stackedItemsView.horizontalAlignment = .leading
        } else {
            stackedItemsView.horizontalAlignment = .trailing
        }
    }
}

open class MediaPreviewCollectionCell: UICollectionViewCell, GalleryItemPreview {
    // MARK: Variables
    public var attachmentId: AttachmentId? {
        return attachment.id
    }

    public var imageView: UIImageView {
        return imgPreview
    }

    private var attachment: ChatMessageImageAttachment!
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

    public func configureMedia(attachment: ChatMessageImageAttachment) {
        self.attachment = attachment
        Nuke.loadImage(with: attachment.payload.imageURL, into: imgPreview)
    }

    public func configureMedia(attachment: StackedItems) {
        Nuke.loadImage(with: attachment.imageUrl, into: imgPreview)
    }
}

protocol PhotoCollectionAction: class  {
    func didSelectAttachment(_ message: ChatMessage?, view: MediaPreviewCollectionCell, _ id: AttachmentId)
}

public class StackedItems: Equatable {
    public static func == (lhs: StackedItems, rhs: StackedItems) -> Bool {
        return lhs.id == rhs.id
    }
    public var id: Int
    public var imageUrl: URL

    public init(id: Int, imageUrl: URL) {
        self.id = id
        self.imageUrl = imageUrl
    }

    public static func staticData() -> [StackedItems] {
        var items = [StackedItems]()
        items.append(.init(id: 0, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/shh.png")!))
        items.append(.init(id: 1, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/celebrate.gif")!))
        items.append(.init(id: 2, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/cheers.gif")!))
        items.append(.init(id: 3, imageUrl: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/thanks.png")!))
        return items
    }
}
