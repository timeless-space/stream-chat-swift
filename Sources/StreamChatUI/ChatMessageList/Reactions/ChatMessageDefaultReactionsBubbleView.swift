//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageDefaultReactionsBubbleView: ChatReactionPickerBubbleView {
    // MARK: - Subviews

    public let contentViewBackground = UIView().withoutAutoresizingMaskConstraints
    public let tailBehind = UIImageView().withoutAutoresizingMaskConstraints
    public let tailInFront = UIImageView().withoutAutoresizingMaskConstraints

    override open var tailLeadingAnchor: NSLayoutXAxisAnchor { tailBehind.leadingAnchor }
    override open var tailTrailingAnchor: NSLayoutXAxisAnchor { tailBehind.trailingAnchor }

    // MARK: - Overrides

    override open func layoutSubviews() {
        super.layoutSubviews()

        contentViewBackground.layer.cornerRadius = contentViewBackground.bounds.height / 2
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        contentViewBackground.layer.borderWidth = 0
    }
    
    override open func setUpLayout() {
        addSubview(tailBehind)
        contentViewBackground.addSubview(contentView)
        contentViewBackground.insetsLayoutMarginsFromSafeArea = false
        contentView.pin(to: contentViewBackground.layoutMarginsGuide)
        embed(contentViewBackground)
        addSubview(tailInFront)

        NSLayoutConstraint.activate([
            tailBehind.centerXAnchor.pin(equalTo: contentViewBackground.centerXAnchor).with(priority: .defaultLow),
            tailBehind.centerYAnchor.pin(equalTo: contentViewBackground.bottomAnchor),
            tailInFront.centerXAnchor.pin(equalTo: tailBehind.centerXAnchor),
            tailInFront.centerYAnchor.pin(equalTo: tailBehind.centerYAnchor)
        ])
    }

    override open func updateContent() {
        super.updateContent()

        tailBehind.image = tailBackImage
        tailInFront.image = tailFrontImage
        contentViewBackground.backgroundColor = contentBackgroundColor
        contentViewBackground.layer.borderColor = UIColor.clear.cgColor//contentBorderColor.cgColor
        contentViewBackground.directionalLayoutMargins = contentLayoutMargins
    }

    open var contentLayoutMargins: NSDirectionalEdgeInsets {
        guard let content = content else { return .zero }

        return content.style.isBig ?
            .init(top: 10, leading: 16, bottom: 10, trailing: 16) :
            .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    }
    
    open var contentBackgroundColor: UIColor {
        guard let content = content else { return .clear }

        switch content.style {
        case .bigIncoming, .bigOutgoing, .smallOutgoing:
            return Appearance.default.colorPalette.messageActionMenuBackground
        case .smallIncoming:
            return Appearance.default.colorPalette.messageActionMenuBackground
        }
    }

    open var contentBorderColor: UIColor {
        guard let content = content else { return .clear }

        let color: UIColor
        switch content.style {
        case .smallOutgoing:
            color = contentBackgroundColor
        case .smallIncoming:
            color = contentBackgroundColor
        default:
            color = contentBackgroundColor
        }
        return resolvedColor(color)
    }

    open var tailBackImage: UIImage? {
        guard let content = content else { return nil }

        switch content.style {
        case .bigIncoming, .bigOutgoing:
            return .tail(
                options: .large(flipped: content.style.isIncoming),
                colors: .init(
                    outlineColor: .clear,
                    borderColor: .clear,
                    innerColor: contentBorderColor
                )
            )
        case .smallIncoming, .smallOutgoing:
            let borderColor = content.style.isIncoming ?
            contentBackgroundColor :
            contentBackgroundColor
            
            let innerColor = content.style.isIncoming ?
            contentBackgroundColor :
            contentBackgroundColor
            
            return .tail(
                options: .small(flipped: content.style.isIncoming),
                colors: .init(
                    outlineColor: resolvedColor(contentBackgroundColor),
                    borderColor: resolvedColor(borderColor),
                    innerColor: resolvedColor(innerColor)
                )
            )
        }
    }

    open var tailFrontImage: UIImage? {
        guard let content = content else { return nil }

        switch content.style {
        case .bigIncoming, .bigOutgoing:
            return nil
        case .smallIncoming, .smallOutgoing:
            let innerColor = content.style.isIncoming ?
            contentBackgroundColor :
            contentBackgroundColor
            return .tail(
                options: .small(flipped: content.style.isIncoming),
                colors: .init(
                    outlineColor: .clear,
                    borderColor: .clear,
                    innerColor: resolvedColor(innerColor)
                )
            )
        }
    }
    
    /// Returns color resolved with current `traitCollection`.
    /// This is needed when a `cgColor` is used which can not be resolved by the view itself.
    private func resolvedColor(_ color: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return color.resolvedColor(with: traitCollection)
        } else {
            return color
        }
    }
}
