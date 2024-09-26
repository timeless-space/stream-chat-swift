//
//  StickerCollectionCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Stipop
import StreamChat
import Lottie
import dotLottieLoader
import dotLottie

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
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        embed(imgSticker,insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
        embed(indicatorView, insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
        indicatorView.startAnimating()
    }

    func configureSticker(sticker: Sticker) {
        let stickerImgUrl = (sticker.stickerImg ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url = URL(string: stickerImgUrl ?? "") {
            if url.path.contains(".lottie") {
                removeAnimationView()
                embed(indicatorView, insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
                indicatorView.isHidden = false
                animatedView = AnimationView()
                DotLottie.load(from: url, cache: DotLottieCache.cache, completion: { [weak self] (animation, file) in
                    guard let `self` = self else { return }
                    self.embed(self.animatedView ?? UIView(), insets: .init(top: 15, leading: 15, bottom: 15, trailing: 15))
                    self.animatedView?.animation = animation
                    self.animatedView?.respectAnimationFrameRate = true
                    self.animatedView?.play()
                    self.animatedView?.loopMode = .loop
                    self.animatedView?.backgroundBehavior = .pauseAndRestore
                    self.animatedView?.translatesAutoresizingMaskIntoConstraints = false
                    self.indicatorView.isHidden = true
                })
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
        animatedView?.removeFromSuperview()
        animatedView = nil
    }
}
