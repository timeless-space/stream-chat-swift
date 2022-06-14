//
//  AnnouncementTableViewCell.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import AVKit

class AnnouncementTableViewCell: ASVideoTableViewCell {

    // MARK: - Outlets
    //swiftlint:disable private_outlet
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imgPlay: UIImageView!
    @IBOutlet weak var lblHashTag: UILabel!
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var imgHeightConst: NSLayoutConstraint!
    @IBOutlet weak var btnContainer: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewAction: UIView!
    @IBOutlet weak var btnShowMore: UIButton!
    @IBOutlet weak var imgAspectConst: NSLayoutConstraint!

    // MARK: - Variables
    var content: ChatMessage?
    var message: ChatMessage?
    var cacheVideoThumbnail: Cache<URL, UIImage>?
    private let containerPadding = 65
    weak var delegate: AnnouncementAction?
    /// Object which is responsible for loading images
    let imageLoader = Components.default.imageLoader
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoLayer.frame = CGRect.init(x: playerView.frame.origin.x, y: playerView.frame.origin.y, width: self.frame.width - CGFloat(containerPadding), height: self.frame.width - CGFloat(containerPadding))

    }

    func configureCell(_ message: ChatMessage?) {
        selectionStyle = .none
        containerView.layer.cornerRadius = 12
        /*
        if let detailsText = message?.text.htmlToAttributedString {
            let mutableAttributedString = NSMutableAttributedString(attributedString: detailsText ?? .init())
            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSRange(location: 0,length: detailsText.length))
            lblInfo.attributedText = mutableAttributedString
        }
        */
        if let message = message?.text {
            let attributedString = NSMutableAttributedString(string: message)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 1.5
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
            lblInfo.attributedText = attributedString
        }

        imgView.image = nil
        // TODO: Hide Action
        /*
        if let clickAction = message?.extraData.cta, clickAction == "url" {
            viewAction.isHidden = false
        } else {
            viewAction.isHidden = true
        }
         */
        viewAction.isHidden = true
        if let hashTag = message?.extraData.tag, !hashTag.isEmpty {
            lblHashTag.text = "#" +  hashTag.joined(separator: " #")
        } else {
            lblHashTag.text = nil
        }
        if let imageAttachments = message?.imageAttachments.first {
            imgView.image = nil
            imgView.isHidden = false
            imgHeightConst.priority = .defaultLow
            imgAspectConst.priority = .defaultHigh
            btnShowMore.setTitle(getActionTitle(), for: .normal)
            imageUrl = imageAttachments.imageURL.absoluteString
            lblTitle.text = imageAttachments.title
            imageLoader.loadImage(
                into: imageView,
                url: imageAttachments.imageURL,
                imageCDN: StreamImageCDN(),
                placeholder: Appearance.default.images.videoAttachmentPlaceholder
            )
            playerView.isHidden = true
            videoURL = nil
        } else if let videoAttachment = message?.videoAttachments.first {
            videoURL = videoAttachment.videoURL.absoluteString
            imgHeightConst.priority = .defaultLow
            imgAspectConst.priority = .defaultHigh
            playerView.isHidden = false
            imgView.image = nil
            lblTitle.text = videoAttachment.title
            if let img = cacheVideoThumbnail?[videoAttachment.videoURL] {
                imageView.image = img
                imgPlay.isHidden = true
                imgView.isHidden = false
            } else {
                Components.default.videoLoader.loadPreviewForVideo(with: videoAttachment.videoURL, completion: { [weak self] result in
                    guard let `self` = self else { return }
                    switch result {
                    case .success(let image, let url):
                        self.cacheVideoThumbnail?[url] = image
                        self.delegate?.didRefreshCell(self, image)
                    case .failure(_):
                        break
                    }
                })
            }
        } else {
            videoURL = nil
            imgView.image = nil
            playerView.isHidden = true
            imgHeightConst.constant = 0
            imgHeightConst.priority = .defaultHigh
            imgAspectConst.priority = .defaultLow
            imgHeightConst.isActive = true
            lblTitle.text = nil
        }
        layoutIfNeeded()
    }

    func getImageFromCache(_ message: ChatMessage?) {
        if let videoAttachment = message?.videoAttachments.first {
            if let img = cacheVideoThumbnail?[videoAttachment.videoURL] {
                imageView.image = img
                imgPlay.isHidden = true
                imgView.isHidden = false
            }
        }
    }

    private func setupUI() {
        videoLayer.backgroundColor = UIColor.clear.cgColor
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.addSublayer(videoLayer)
        videoLayer.frame = CGRect.init(x: playerView.frame.origin.x, y: playerView.frame.origin.y, width: self.frame.width - CGFloat(containerPadding), height: playerView.frame.height)
    }
    
    private func getActionTitle() -> String {
        guard let cta = message?.extraData.cta else { return "Show More" }
        switch cta {
        case "url":  return "Show More"
        default: return ""
        }
    }

    @IBAction func btnContainerTapAction(_ sender: Any) {
        delegate?.didSelectAnnouncement(message, view: self)
    }
}

extension AnnouncementTableViewCell: GalleryItemPreview {
    var attachmentId: AttachmentId? {
        return message?.firstAttachmentId
    }
    
    override var imageView: UIImageView {
        self.imgView
    }
}

protocol AnnouncementAction: class  {
    func didSelectAnnouncement(_ message: ChatMessage?, view: AnnouncementTableViewCell)
    func didSelectAnnouncementAction(_ message: ChatMessage?)
    func didRefreshCell(_ cell: AnnouncementTableViewCell, _ img: UIImage)
}
