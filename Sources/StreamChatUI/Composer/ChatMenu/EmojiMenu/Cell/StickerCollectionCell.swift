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
    private var animatedView: AnimationView?
    private var indicatorView = UIActivityIndicatorView()

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
        if let url = URL(string: stickerImgUrl ?? "") {
            if url.path.contains(".json") {
                removeAnimationView()
                embed(indicatorView, insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
                indicatorView.isHidden = false
                indicatorView.startAnimating()
                animatedView = .init(url: url, imageProvider: nil, closure: { [weak self] error in
                    guard let `self` = self else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        self.embed(self.animatedView ?? UIView(), insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
                        self.animatedView?.play()
                        self.animatedView?.backgroundBehavior = .pauseAndRestore
                        self.animatedView?.translatesAutoresizingMaskIntoConstraints = false
                        self.indicatorView.isHidden = true
                    })
                }, animationCache: LRUAnimationCache.sharedCache)
            } else {
                indicatorView.isHidden = true
                imgSticker.setSticker(stickerImgUrl ?? "", sizeOptimized: true)
                imgSticker.backgroundColor = .clear
            }
        }
    }

    private func removeAnimationView() {
        animatedView?.stop()
        indicatorView.removeFromSuperview()
        animatedView = nil
    }
}
