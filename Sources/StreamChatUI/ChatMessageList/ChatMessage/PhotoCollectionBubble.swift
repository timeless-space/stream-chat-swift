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
        stackedItemsView.items = imageAttachment + videoAttachment
        stackedItemsView.configureItemHandler = { item, cell in
            cell.configureMedia(attachment: item, isExpand: self.stackedItemsView.isExpand)
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

open class MediaPreviewCollectionCell: UICollectionViewCell, GalleryItemPreview, ASAutoPlayVideoLayerContainer {

    // MARK: Variables
    public var videoURL: String? {
        didSet {
            if let videoURL = videoURL {
                ASVideoPlayerController.sharedVideoPlayer.setupVideoFor(url: videoURL)
            }
            videoLayer.isHidden = videoURL == nil
        }
    }

    public var imageUrl: String?
    public var isVideoPlaying: Bool = false
    public var videoLayer = AVPlayerLayer()
    private(set) lazy var btnPlay: UIButton = {
        let btnPlay = UIButton()
        btnPlay.addTarget(self, action: #selector(btnPlayAction), for: .touchUpInside)
        btnPlay.setImage(Appearance.default.images.play, for: .normal)
        return btnPlay
    }()
    
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

    open override func prepareForReuse() {
        super.prepareForReuse()
        videoLayer.player?.pause()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        embed(imgPreview)
        btnPlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(btnPlay)
        btnPlay.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        btnPlay.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        videoLayer.backgroundColor = UIColor.clear.cgColor
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.addSublayer(videoLayer)
        videoLayer.frame = bounds
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        videoLayer.frame = bounds
    }

    public func configureMedia(attachment: StackedItem, isExpand: Bool) {
        imgPreview.image = nil
        self.attachment = attachment
        btnPlay.isHidden = true
        videoURL = nil
        if attachment.attachmentType == .image {
            btnPlay.isHidden = true
            Nuke.loadImage(with: attachment.url, into: imgPreview)
        } else {
            btnPlay.isHidden = false
            if !isExpand {
                videoURL = attachment.url.absoluteString
            }
            Components.default.videoLoader.loadPreviewForVideo(with: attachment.url, completion: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let image, let url):
                    self.imgPreview.image = image
                case .failure(_):
                    break
                }
            })
        }
    }

    @objc func btnPlayAction() {
        btnPlay.isHidden = true
        videoLayer.player?.play()
    }

}

protocol PhotoCollectionAction: class  {
    func didSelectAttachment(_ message: ChatMessage?, view: MediaPreviewCollectionCell, _ id: AttachmentId)
}

public class StackedItem: Equatable {

    public enum AttachmentType {
        case video
        case image
    }

    public static func == (lhs: StackedItem, rhs: StackedItem) -> Bool {
        return lhs.id == rhs.id
    }
    public var id: Int
    public var url: URL
    public var attachmentId: String?
    public var attachmentType: AttachmentType?

    public init(id: Int, url: URL, attachmentType: AttachmentType, attachmentId: String? = nil) {
        self.id = id
        self.attachmentType = attachmentType
        self.url = url
        self.attachmentId = attachmentId
    }

    public static func staticData() -> [StackedItem] {
        var items = [StackedItem]()
        items.append(.init(id: 0, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/shh.png")!, attachmentType: .image))
        items.append(.init(id: 1, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/celebrate.gif")!, attachmentType: .image))
        items.append(.init(id: 2, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/cheers.gif")!, attachmentType: .image))
        items.append(.init(id: 3, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/thanks.png")!, attachmentType: .image))
        items.append(.init(id: 4, url: URL.init(string: "https://res.cloudinary.com/timeless/video/upload/v1644831818/app/Wallet/shopping-travel.mp4")!, attachmentType: .video))
        items.append(.init(id: 5, url: URL.init(string: "https://res.cloudinary.com/timeless/video/upload/v1644831819/app/Wallet/wellbeing-calm.mp4")!, attachmentType: .video))
        return items
    }
}
