//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button used for sending a message, or any type of content.
open class SendButton: _Button, AppearanceProvider {
    /// Override this variable to enable custom behavior upon button enabled.
    /*override open var isEnabled: Bool {
        didSet {
            isEnabledChangeAnimation(isEnabled)
        }
    }*/

    override open func setUpAppearance() {
        super.setUpAppearance()
        //paperplane.fill
        if #available(iOS 13.0, *) {
            setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        } else {
            let normalStateImage = appearance.images.sendArrow.tinted(with: .white)
            setImage(normalStateImage, for: .normal)
        }
        tintColor = appearance.colorPalette.themeBlue
        /*let normalStateImage = appearance.images.sendArrow.tinted(with: .white)
        setImage(normalStateImage, for: .normal)
        let buttonColor: UIColor = .darkGray
        let disabledStateImage = appearance.images.sendArrow.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)*/
    }
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -15, dy: -15).contains(point)
    }

    /// The animation when the `isEnabled` state changes.
    open func isEnabledChangeAnimation(_ isEnabled: Bool) {
        Animate {
            self.transform = isEnabled
                ? CGAffineTransform(rotationAngle: -CGFloat.pi / 2.0)
                : .identity
        }
    }
}
