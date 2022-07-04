//
//  BaseBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 24/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat

class BaseBubble: _TableViewCell {
    /// The delegate responsible for action handling.
    public weak var contentActionDelegate: ChatMessageContentViewDelegate?
    public private(set) var authorAvatarView: ChatAvatarView?
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    var content: ChatMessage?

    func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = Components.default
                .avatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        authorAvatarView?.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width).isActive = true
        authorAvatarView?.heightAnchor.pin(equalToConstant: messageAuthorAvatarSize.height).isActive = true
        authorAvatarView?.addTarget(self, action: #selector(handleTapOnAvatarView), for: .touchUpInside)
        return authorAvatarView!
    }

    /// Handles tap on `avatarView` and forwards the action to the delegate.
    @objc open func handleTapOnAvatarView() {
        contentActionDelegate?.messageContentViewDidTapOnAvatarView(content)
    }
}
