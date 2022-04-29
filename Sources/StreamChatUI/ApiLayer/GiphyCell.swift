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

class GiphyCell: UICollectionViewCell {

    // MARK: - Variables
    private var mediaView: GPHMediaView!

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
        setUpIndicatorView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mediaView)
        mediaView.pin(to: self)
    }

    func setUpIndicatorView() {
        addSubview(progressIndicator)
        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Custom functions
    func configureCell(giphyModel: GiphyModelItem?) {
        guard let giphyModel = giphyModel else {
            return
        }
        mediaView.loadAsset(at: giphyModel.images.fixedWidthSmall.url)
    }

}
