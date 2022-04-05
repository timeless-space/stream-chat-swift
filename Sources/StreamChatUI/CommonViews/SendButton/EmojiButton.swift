//
//  EmojiButton.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 26/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import Stipop

open class EmojiButton: _Button, AppearanceProvider {

    override open func setUpAppearance() {
        super.setUpAppearance()
        let normalStateImage = appearance.images.emojiIcon
        let selectedStateImage = appearance.images.menuKeyboard
        self.tintColor = .init(rgb: 0x737373)
        setImage(normalStateImage, for: .normal)
        setImage(selectedStateImage, for: .selected)
    }
}

