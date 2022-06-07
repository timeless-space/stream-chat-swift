//
//  MediaPreviewCollectionCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 02/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import AVKit

open class MediaPreviewCollectionCell:
    UICollectionViewCell,
    ASAutoPlayVideoLayerContainer {
    
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
    private lazy var loadingIndicator = UIActivityIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints
    private(set) lazy var btnPlay: UIButton = {
        let btnPlay = UIButton()
        btnPlay.addTarget(self, action: #selector(btnPlayAction), for: .touchUpInside)
        btnPlay.setImage(Appearance.default.images.play, for: .normal)
        return btnPlay
    }()
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

    private var btnCollapse: UIButton = {
        let btnCollapse = UIButton()
        btnCollapse.setImage(Appearance.default.images.collapseStack, for: .normal)
        btnCollapse.translatesAutoresizingMaskIntoConstraints = false
        btnCollapse.isUserInteractionEnabled = false
        return btnCollapse
    }()

    private(set) lazy var videoPreview: UIImageView = {
        let videoPreview = UIImageView()
        videoPreview.clipsToBounds = true
        videoPreview.contentMode = .scaleAspectFill
        videoPreview.translatesAutoresizingMaskIntoConstraints = false
        return videoPreview
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
        embed(videoPreview)
        addSubview(btnCollapse)
        btnCollapse.translatesAutoresizingMaskIntoConstraints = false
        btnPlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(btnPlay)
        btnPlay.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        btnPlay.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        videoLayer.backgroundColor = UIColor.clear.cgColor
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoLayer.frame = bounds
        addSubview(loadingIndicator)
        btnCollapse.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        btnCollapse.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -30).isActive = true
        loadingIndicator.centerYAnchor.pin(equalTo: self.centerYAnchor).isActive = true
        loadingIndicator.centerXAnchor.pin(equalTo: self.centerXAnchor).isActive = true
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        videoLayer.frame = bounds
    }

    public func configureMedia(attachment: StackedItem, isExpand: Bool, isLoading: Bool) {
        self.attachment = attachment
        btnCollapse.isHidden = true
        imgPreview.image = nil
        imageTask?.cancel()
        btnPlay.isHidden = true
        loadingIndicator.isVisible = true
        loadingIndicator.startAnimating()
        videoURL = nil
        if attachment.attachmentType == .image {
            btnPlay.isHidden = true
            videoPreview.isHidden = true
            imgPreview.isHidden = false
            imageTask = Components.default.imageLoader.loadImage(
                into: imgPreview,
                url: attachment.url,
                imageCDN: Components.default.imageCDN,
                completion: { [weak self] result in
                    self?.loadingIndicator.isVisible = isLoading
                    switch result {
                    case .failure:
                        self?.imgPreview.image = Appearance.default.images.videoAttachmentPlaceholder
                    case .success:
                        break
                    }
                    self?.imageTask = nil
                }
            )
        } else {
            btnPlay.isHidden = isLoading
            videoPreview.isHidden = false
            imgPreview.isHidden = true
            loadingIndicator.isVisible = isLoading
            if !isExpand {
                videoURL = attachment.url.absoluteString
            } else {
                videoURL = nil
            }
            Components.default.videoLoader.loadPreviewForVideo(
                with: attachment.url,
                completion: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let image, let url):
                    self.videoPreview.image = image
                case .failure:
                    self.imgPreview.image = Appearance.default.images.videoAttachmentPlaceholder
                    self.videoPreview.image = nil
                }
            })
        }
        imgPreview.alpha = isLoading ? 0.5 : 1
        videoPreview.alpha = isLoading ? 0.5 : 1
    }

    public func configureLastAction() {
        imgPreview.image = nil
        imageTask?.cancel()
        btnPlay.isHidden = true
        loadingIndicator.isVisible = false
        backgroundColor = .clear
        videoURL = nil
        btnCollapse.isHidden = false
    }

    @objc private func btnPlayAction() {
        btnPlay.isHidden = true
        videoLayer.player?.play()
    }
}

protocol PhotoCollectionAction: class  {
    func didSelectAttachment(_ message: ChatMessage?, view: GalleryItemPreview, _ id: AttachmentId)
}

extension MediaPreviewCollectionCell: GalleryItemPreview {
    public var attachmentId: AttachmentId? {
        return AttachmentId(rawValue: attachment.attachmentId ?? "")
    }

    public var imageView: UIImageView {
        return imgPreview
    }
}
