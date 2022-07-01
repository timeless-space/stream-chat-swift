//
//  ChatMessageStickerBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 25/03/22.
//

import StreamChat
import AVKit
import Stipop
import GiphyUISDK
import Lottie
import dotLottie
import dotLottieLoader

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
    private var imageLoader = Components.default.imageLoader
    var content: ChatMessage?
    var chatChannel: ChatChannel?
    var isSender = false
    private var cellWidth: CGFloat = 100.0
    var sentThumbStickerView: AnimationView?
    var tapGesture: UITapGestureRecognizer?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(onTapOfLottie))
        tapGesture?.numberOfTapsRequired = 1
    }

    @objc func onTapOfLottie() {
        if !(sentThumbStickerView?.isAnimationPlaying ?? true) {
            sentThumbStickerView?.play(completion: nil)
        }
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
        } else if content?.extraData.stickerUrl?.contains(".lottie") ?? false, let lottie = URL(string: content?.extraData.stickerUrl ?? "") {
            sentThumbStickerView = AnimationView()
            DotLottie.load(from: lottie, cache: DotLottieCache.cache, completion: { [weak self] (animation, file) in
                guard let `self` = self else { return }
                self.sentThumbStickerView?.animation = animation
                self.sentThumbStickerView?.respectAnimationFrameRate = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.sentThumbStickerView?.play()
                    self.sentThumbStickerView?.loopMode = .loop
                    self.sentThumbStickerView?.backgroundBehavior = .pauseAndRestore
                }
            })
            if let stickerView = sentThumbStickerView {
                stickerView.backgroundColor = Appearance.default.colorPalette.background6
                stickerView.transform = .mirrorY
                stickerView.contentMode = .scaleAspectFill
                stickerView.layer.cornerRadius = 12
                stickerView.translatesAutoresizingMaskIntoConstraints = false
                stickerView.clipsToBounds = true
                stickerView.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
                stickerView.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
                stickerContainer.addArrangedSubview(stickerView)
                if let tapGesture = tapGesture {
                    stickerView.addGestureRecognizer(tapGesture)
                }
            }
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
                    imageLoader.loadImage(
                        into: authorAvatarView?.imageView ?? .init(),
                        url: content?.author.imageURL,
                        imageCDN: Components.default.imageCDN,
                        placeholder: nil,
                        preferredSize: nil
                    )
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

    func clearAll() {
        sentThumbStickerView?.animation = nil
        sentThumbStickerView?.removeFromSuperview()
        sentThumbStickerView = nil
    }
}
