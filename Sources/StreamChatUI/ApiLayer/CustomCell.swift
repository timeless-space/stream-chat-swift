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

class GiphyCell: UICollectionViewCell {

    // MARK: - Variables
    private var mediaView = GPHMediaView()

    // MARK: - Lifecycle Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mediaView)
        mediaView.pin(to: self)
        mediaView.backgroundColor = .red
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Custom functions

    /// Setup UI Constraints for the screen

    /// Configure with data
    /// - Parameter feedData: feedData contents individual content description
    func configureCell(giphyModel: GiphyModelItem?) {
        guard let giphyModel = giphyModel else {
            return
        }

        mediaView.media = GPHMedia(giphyModel.id, type: GPHMediaType(rawValue: giphyModel.type)!, url: giphyModel.url)
    }

}
