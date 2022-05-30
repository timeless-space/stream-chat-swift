//
//  StickerCollectionCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Stipop
import StreamChat
import Lottie

class StickerCollectionCell: UICollectionViewCell {

    // MARK: Variables
    private var imgSticker: SPUIStickerView!
    private var animatedView: AnimationView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        imgSticker = SPUIStickerView()
        imgSticker.translatesAutoresizingMaskIntoConstraints = false
        embed(imgSticker,insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configureSticker(sticker: Sticker) {
        let stickerImgUrl = (sticker.stickerImg ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url = URL(string: stickerImgUrl ?? "") {
            if url.path.contains(".json") {
                animatedView = .init(url: url, closure: { [weak self] _ in
                    guard let `self` = self else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animatedView.play()
                        self.animatedView.loopMode = .loop
                    }
                })
                animatedView.translatesAutoresizingMaskIntoConstraints = false
                embed(animatedView,insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
            } else {
                imgSticker.setSticker(stickerImgUrl ?? "", sizeOptimized: true)
                imgSticker.backgroundColor = .clear
            }
        }
    }

    func remove() {
        if animatedView != nil {
            animatedView.removeFromSuperview()
        }
    }
}
