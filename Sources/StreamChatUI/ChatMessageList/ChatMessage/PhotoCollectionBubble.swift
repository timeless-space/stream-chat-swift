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
        let imgAttachments = content?.attachments(payloadType: ImageAttachmentPayload.self) ?? []
        let videoAttachments = content?.attachments(payloadType: VideoAttachmentPayload.self) ?? []
        if (!imgAttachments.filter { $0.uploadingState != nil }.isEmpty)
        &&
        (!videoAttachments.filter { $0.uploadingState != nil }.isEmpty) {
            loadingIndicator.isVisible = true
            stackedItemsView.isHidden = true
        } else {
            loadingIndicator.isVisible = false
            stackedItemsView.isHidden = false
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
        self.attachment = attachment
        imgPreview.image = nil
        imageTask?.cancel()
        btnPlay.isHidden = true
        videoURL = nil
        if attachment.attachmentType == .image {
            btnPlay.isHidden = true
            imageTask = Components.default.imageLoader.loadImage(
                into: imgPreview,
                url: attachment.url,
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
        } else {
            btnPlay.isHidden = false
            if !isExpand {
                videoURL = attachment.url.absoluteString
            } else {
                videoURL = nil
            }
            Components.default.videoLoader.loadPreviewForVideo(with: attachment.url, completion: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let image, let url):
                    self.imgPreview.image = image
                case .failure(_):
                    self.imgPreview.image = nil
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
    func didSelectAttachment(_ message: ChatMessage?, view: GalleryItemPreview, _ id: AttachmentId)
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
