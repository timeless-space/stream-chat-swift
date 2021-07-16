//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The cell that displays the message content of a dynamic type and layout.
/// Once the cell is set up it is expected to be dequeued for messages with
/// the same content and layout the cell has already been configured with.
public typealias ChatMessageCell = _ChatMessageCell<NoExtraData>

/// The cell that displays the message content of a dynamic type and layout.
/// Once the cell is set up it is expected to be dequeued for messages with
/// the same content and layout the cell has already been configured with.
public final class _ChatMessageCell<ExtraData: ExtraDataTypes>: _TableViewCell {
    public static var reuseId: String { "\(self)" }
    
    /// The message header view the cell is showing
    public private(set) var messageHeaderView: _ChatMessageHeaderView<ExtraData>?
    
    /// The message content view the cell is showing.
    public private(set) var messageContentView: _ChatMessageContentView<ExtraData>?
    
    /// The minimum spacing below the cell.
    public var minimumSpacingBelow: CGFloat = 2 {
        didSet { updateBottomSpacing() }
    }
    
    override public func setUp() {
        super.setUp()
        
        selectionStyle = .none
    }
    
    override public func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = .clear
        backgroundView = nil
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        messageContentView?.prepareForReuse()
        messageHeaderView?.prepareForReuse()
    }

    /// Creates a message content view
    /// - Parameters:
    ///   - contentViewClass: The type of message content view.
    ///   - headerViewClass: The type of message header view.
    ///   - attachmentViewInjectorType: The type of attachment injector.
    ///   - options: The layout options describing the message content view layout.
    public func setMessageContentIfNeeded(
        headerViewClass: _ChatMessageHeaderView<ExtraData>.Type,
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        options: ChatMessageLayoutOptions
    ) {
        guard messageContentView == nil else {
            log.assert(type(of: messageContentView!) == contentViewClass, """
            Attempt to setup different content class: ("\(contentViewClass)")
            """)
            return
        }
        
        guard messageHeaderView == nil else {
            log.assert(type(of: messageHeaderView!) == headerViewClass, """
            Attempt to setup different header class: ("\(headerViewClass)")
            """)
            return
        }

        messageContentView = contentViewClass.init().withoutAutoresizingMaskConstraints
        // We add the content view to the view hierarchy before invoking `setUpLayoutIfNeeded`
        // (where the subviews are instantiated and configured) to use `components` and `appearance`
        // taken from the responder chain.
        contentView.addSubview(messageContentView!)
        
        if options.contains(.header) {
            messageHeaderView = headerViewClass.init().withoutAutoresizingMaskConstraints
            contentView.addSubview(messageHeaderView!)
            messageHeaderView!.pin(anchors: [.leading, .top, .trailing], to: contentView)
            messageContentView!.pin(anchors: [.leading, .trailing, .bottom], to: contentView)
            messageContentView!.topAnchor.constraint(equalTo: messageHeaderView!.bottomAnchor).isActive = true
        } else {
            messageContentView!.pin(anchors: [.leading, .top, .trailing, .bottom], to: contentView)
        }
        
        messageContentView!.setUpLayoutIfNeeded(options: options, attachmentViewInjectorType: attachmentViewInjectorType)
        updateBottomSpacing()
    }
    
    private func updateBottomSpacing() {
        guard let contentView = messageContentView else { return }
        
        contentView.mainContainer.layoutMargins.bottom = max(
            contentView.mainContainer.layoutMargins.bottom,
            minimumSpacingBelow
        )
    }
}
