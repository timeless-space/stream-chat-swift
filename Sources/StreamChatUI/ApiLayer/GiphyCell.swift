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

    // MARK: - Lifecycle Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        mediaView = GPHMediaView()
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaView.backgroundColor = Appearance.default.colorPalette.emojiBg
        self.embed(mediaView, insets: .init(top: 4, leading: 0, bottom: 0, trailing: 4))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Custom functions
    func configureCell(giphyModel: GiphyModelItem?) {
        mediaView.clear()
        guard let giphyModel = giphyModel else {
            return
        }
        mediaView.loadAsset(at: giphyModel.images.fixedWidthDownsampled.url)
    }

    func clearData() {
        mediaView.clear()
    }

}
