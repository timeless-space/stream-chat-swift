//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the message header.
public typealias ChatMessageHeaderView = _ChatMessageHeaderView<NoExtraData>

/// A view that displays the message header.
open class _ChatMessageHeaderView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    // MARK: Content && Actions
    
    /// The provider of cell index path which displays the current content view.
    public var indexPath: (() -> IndexPath?)?
        
    /// The string this view displays as the header.
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }
    
    /// The view used to display the content.
    open private(set) lazy var textLabel: UILabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withoutAutoresizingMaskConstraints
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        embed(textLabel, insets: .init(top: 10, leading: 10, bottom: 10, trailing: 10))
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        // TODO: Appearance customization
        textLabel.font = appearance.fonts.caption1
        textLabel.textColor = appearance.colorPalette.text
        textLabel.textAlignment = .center
        textLabel.backgroundColor = appearance.colorPalette.background1
    }
    
    override open func updateContent() {
        super.updateContent()
        
        textLabel.text = content
    }
    
    /// Cleans up the view so it is ready to display another message.
    /// We don't need to reset `content` because all subviews are always updated.
    func prepareForReuse() {
        indexPath = nil
    }
}
