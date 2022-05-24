//
//  ChatMessageStickerBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 25/03/22.
//

import StreamChat
import Nuke
import AVKit
import Stipop
import GiphyUISDK

class ChatMessageStickerBubble: _TableViewCell {

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
    private var leadingMainContainer: NSLayoutConstraint?
    private var trailingMainContainer: NSLayoutConstraint?
    private var timestampLabelWidthConstraint: NSLayoutConstraint?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    var content: ChatMessage?
    var chatChannel: ChatChannel?
    var isSender = false
    private var cellWidth: CGFloat = 100.0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }



    private func setLayout() {
        selectionStyle = .none
        backgroundColor = .clear

        mainContainer.addArrangedSubviews([createAvatarView(), subContainer])
        mainContainer.alignment = .bottom
        contentView.addSubview(mainContainer)
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            mainContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4)
        ])

        subContainer.addArrangedSubviews([createTimestampLabel(), stickerContainer])
        subContainer.alignment = .leading
        subContainer.transform = .mirrorY
        leadingMainContainer = mainContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8)
        trailingMainContainer = mainContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        timestampLabelWidthConstraint = timestampLabel?.widthAnchor.constraint(equalToConstant: cellWidth)
        timestampLabelWidthConstraint?.isActive = true
    }

    private func setBubbleConstraints(_ isSender: Bool) {
        leadingMainContainer?.isActive = !isSender
        trailingMainContainer?.isActive = isSender
        timestampLabelWidthConstraint?.constant = cellWidth
    }

    private func setStickerViews() {
        stickerContainer.removeAllArrangedSubviews()
        if let giphyUrl = content?.extraData.giphyUrl, let gifUrl = URL(string: giphyUrl) {
            let sentThumbGifView = GPHMediaView()
            sentThumbGifView.backgroundColor = Appearance.default.colorPalette.background6
            sentThumbGifView.transform = .mirrorY
            sentThumbGifView.contentMode = .scaleAspectFill
            sentThumbGifView.layer.cornerRadius = 12
            sentThumbGifView.translatesAutoresizingMaskIntoConstraints = false
            sentThumbGifView.clipsToBounds = true
            sentThumbGifView.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
            sentThumbGifView.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
            sentThumbGifView.setGifFromURL(gifUrl)
            stickerContainer.addArrangedSubview(sentThumbGifView)
        } else if let sticker = content?.extraData.stickerUrl?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let sentThumbStickerView = SPUIStickerView()
            sentThumbStickerView.backgroundColor = Appearance.default.colorPalette.background6
            sentThumbStickerView.transform = .mirrorY
            sentThumbStickerView.contentMode = .scaleAspectFill
            sentThumbStickerView.layer.cornerRadius = 12
            sentThumbStickerView.translatesAutoresizingMaskIntoConstraints = false
            sentThumbStickerView.clipsToBounds = true
            sentThumbStickerView.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
            sentThumbStickerView.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
            sentThumbStickerView.setSticker(sticker, sizeOptimized: true)
            stickerContainer.addArrangedSubview(sentThumbStickerView)
        }
    }

    func configureCell(isSender: Bool) {

        if let giphyUrl = content?.extraData.giphyUrl {
            cellWidth = 200
        } else {
            cellWidth = 150
        }
        setBubbleConstraints(isSender)
        if isSender {
            authorAvatarView?.isHidden = true
        } else {
            authorAvatarView?.isHidden = false
        }
        setStickerViews()
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
