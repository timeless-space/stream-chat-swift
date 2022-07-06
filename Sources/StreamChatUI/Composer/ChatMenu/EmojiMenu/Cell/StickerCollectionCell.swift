//
//  StickerCollectionCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Stipop
import StreamChat

class StickerCollectionCell: UICollectionViewCell {

    // MARK: Variables
    private var imgSticker: SPUIStickerView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpLayout()
    }

    func setUpLayout() {
        imgSticker = SPUIStickerView()
        imgSticker.translatesAutoresizingMaskIntoConstraints = false
        embed(imgSticker,insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
    }

    func configureSticker(sticker: Sticker) {
        let stickerImgUrl = (sticker.stickerImg ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        imgSticker.setSticker(stickerImgUrl ?? "", sizeOptimized: true)
        imgSticker.backgroundColor = .clear
    }
}
