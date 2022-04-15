//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A Button subclass that should be used for closing.
open class CloseButton: _Button, AppearanceProvider {
    override open var isHighlighted: Bool {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        setImage(appearance.images.close, for: .normal)
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -20, dy: -20).contains(point)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        if isHighlighted {
            tintColor = appearance.colorPalette.highlightedColorForColor(
                .white//appearance.colorPalette.text
            )
        } else {
            tintColor = .white//appearance.colorPalette.text
        }
    }
}
