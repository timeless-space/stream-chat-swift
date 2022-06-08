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

class ChatMessageStickerBubble: BaseCustomBubble {

    public lazy var subContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    public lazy var stickerContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints

    override var cellWidth: CGFloat {
        if let giphyUrl = content?.extraData.giphyUrl {
            return 200
        } else {
            return 150
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setLayout() {
        addContainerView(stickerContainer)
    }

    private func setStickerViews() {
        stickerContainer.removeAllArrangedSubviews()
        if let giphyUrl = content?.extraData.giphyUrl, let gifUrl = URL(string: giphyUrl) {
            let sentThumbGifView = GPHMediaView()
            sentThumbGifView.backgroundColor = Appearance.default.colorPalette.background6
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

    override func configureCell(
        isSender: Bool,
        content: ChatMessage?,
        chatChannel: ChatChannel?,
        layoutOptions: ChatMessageLayoutOptions?
    ) {
        super.configureCell(
            isSender: isSender,
            content: content,
            chatChannel: chatChannel,
            layoutOptions: layoutOptions
        )
        setStickerViews()
    }
}
