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

    private(set) lazy var imgPreview: UIImageView = {
        let imgPreview = UIImageView()
        imgPreview.clipsToBounds = true
        imgPreview.contentMode = .scaleAspectFill
        imgPreview.translatesAutoresizingMaskIntoConstraints = false
        return imgPreview
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(stackedItemsView)
        stackedItemsView.translatesAutoresizingMaskIntoConstraints = false
        stackedItemsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        stackedItemsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        stackedItemsView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        stackedItemsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        addGestureRecognizer(stackedItemsView.panGestureRecognizer)
        heightConst = stackedItemsView.heightAnchor.constraint(equalToConstant: 285)
        heightConst?.isActive = true

        contentView.addSubview(imgPreview)
        imgPreview.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imgPreview.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imgPreview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        imgPreview.widthAnchor.constraint(equalToConstant: 200).isActive = true
    }

    func configureCell(isSender: Bool) {
        if content?.imageAttachments.count == 1 {
            Nuke.loadImage(with: content?.imageAttachments.first?.imageURL, into: imgPreview)
            heightConst?.constant = 200
            imgPreview.isHidden = false
            stackedItemsView.isHidden = true
        } else {
            stackedItemsView.items = content?.imageAttachments ?? []
            heightConst?.constant = 300
            stackedItemsView.configureItemHandler = { item, cell in
                cell.configureMedia(attachment: item)
                cell.clipsToBounds = true
                cell.cornerRadius = 20
            }
            stackedItemsView.selectionHandler = { [weak self] type, selectedIndex in
                guard let `self` = self else { return }
                self.stackedItemsView.expandView(index: selectedIndex)
            }
            imgPreview.isHidden = true
            stackedItemsView.isHidden = false
        }
    }
}

class MediaPreviewCollectionCell: UICollectionViewCell {

    // MARK: Variables
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        embed(imgPreview)
    }

    func configureMedia(attachment: ChatMessageImageAttachment) {
        Nuke.loadImage(with: attachment.payload.imageURL, into: imgPreview)
    }
}
