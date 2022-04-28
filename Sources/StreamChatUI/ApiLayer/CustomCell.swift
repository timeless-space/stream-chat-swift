//
//  CustomCell.swift
//  StreamChat
//
//  Created by Mohammed Hanif on 27/04/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import StreamChat
import GiphyUISDK
import UIKit
import Stipop

let mediaViewDelegate = MediaViewDelegate()

class GiphyCell: UICollectionViewCell {

    // MARK: - Variables
    private var mediaView: GPHMediaView!
//    SPUIStickerView
    var stipopView: SPUIStickerView!

//    fileprivate(set) var imageView: FLAnimatedImageView = FLAnimatedImageView()

    private var progressIndicator: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.color = .white
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.startAnimating()
        return indicatorView
    }()

    // MARK: - Lifecycle Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        mediaView = GPHMediaView()
        stipopView = SPUIStickerView()
        // setUpIndicatorView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        stipopView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(mediaView)
//        addSubview(stipopView)
//        stipopView.pin(to: self)
//        setUpImageView()
    }

    func setUpIndicatorView() {
        addSubview(progressIndicator)
        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

//    func setUpImageView() {
//        addSubview(imageView)
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.clipsToBounds = true
//
//        NSLayoutConstraint.activate([
//            imageView.leftAnchor.constraint(equalTo: self.leftAnchor),
//                imageView.topAnchor.constraint(equalTo: self.topAnchor),
//                imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
//                imageView.rightAnchor.constraint(equalTo: self.rightAnchor)
//            ])
//    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Custom functions
    func configureCell(giphyModel: GiphyModelItem?) {
        guard let giphyModel = giphyModel else {
            return
        }

        
//        stipopView.setSticker(giphyModel.images.fixedWidth.url)
//        mediaView.media = GPHMedia(giphyModel.id, type: .gif, url: giphyModel.images.downsized.url)
//        mediaView.setMedia(.init)
        mediaView.loadAsset(at: giphyModel.images.downsized.url, queueOriginalRendition: false)
        debugPrint("Current Url :- \(giphyModel.images.downsized.url)")
        debugPrint("Current Id :- \(giphyModel.id)")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
//        imageView.sd_cancelCurrentAnimationImagesLoad()
//        imageView.sd_cancelCurrentImageLoad()
//        imageView.sd_setImage(with: nil)
//        imageView.animatedImage = nil
//        imageView.image = nil

    }

    func configureFor(giphyModel: GiphyModelItem?) {
        guard let giphyModel = giphyModel else {
            return
        }
//        imageView.sd_cacheFLAnimatedImage = false
//        imageView.sd_setShowActivityIndicatorView(true)
//        imageView.sd_setIndicatorStyle(.gray)
//        imageView.sd_setImage(with: URL(string: giphyModel.images.downsized.url))
    }

}

class MediaViewDelegate: GPHMediaViewDelegate {

    func didPressMoreByUser(_ user: String) {
        debugPrint(user)
    }

}
