//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a channel avatar including an online indicator if any user is online.
public typealias ChatChannelAvatarView = _ChatChannelAvatarView<NoExtraData>

/// A view that shows a channel avatar including an online indicator if any user is online.
open class _ChatChannelAvatarView<ExtraData: ExtraDataTypes>: _View, ThemeProvider, SwiftUIRepresentable {
    /// A view indicating whether the user this view represents is online.
    ///
    /// The type of `onlineIndicatorView` is UIView & MaskProviding in Components.
    /// Xcode is failing to compile due to `Segmentation fault: 11` when used here.
    open private(set) lazy var onlineIndicatorView: UIView = components
        .onlineIndicatorView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Bool to determine if the indicator should be shown.
    open var isOnlineIndicatorVisible: Bool = false {
        didSet {
            onlineIndicatorView.isVisible = isOnlineIndicatorVisible
            setUpMask(indicatorVisible: isOnlineIndicatorVisible)
        }
    }
    
    /// The data this view component shows.
    open var content: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet { updateContentIfNeeded() }
    }
    
    // Avatar indices locations:
    // When one avatar is available:
    // -------
    // |     |
    // |  0  |
    // |     |
    // -------
    // When two avatars are available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // When three avatars are available:
    // -------------
    // |     |     |
    // |     |  1  |
    // |     |     |
    // |  0  |------
    // |     |     |
    // |     |  2  |
    // |     |     |
    // -------------
    // When four (or more) avatars are available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // |     |     |
    // |  3  |  2  |
    // |     |     |
    // -------------
    
    /// The spots the avatars take.
    public private(set) lazy var avatarImageViews = [
        UIImageView().withoutAutoresizingMaskConstraints,
        UIImageView().withoutAutoresizingMaskConstraints,
        UIImageView().withoutAutoresizingMaskConstraints,
        UIImageView().withoutAutoresizingMaskConstraints
    ]
    
    /// The spots that are occupied. The key denotes the spot(index of the image in the `avatarImageViews` and the value denotes whether the spot
    /// is occupied by some image
    public private(set) lazy var occupiedAvatarSpots: [Int: Bool] = [:]
    
    /// Container holding all the left and right avatar containers.
    public private(set) lazy var avatarsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    /// Left container for avatars.
    public private(set) lazy var leftAvatarsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    /// Right container for avatars.
    public private(set) lazy var rightAvatarsContainerView = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        onlineIndicatorView.isHidden = true
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        avatarImageViews.forEach { $0.contentMode = .scaleAspectFill }
        avatarsContainerView.axis = .horizontal
        avatarsContainerView.distribution = .equal
        avatarsContainerView.alignment = .fill
        avatarsContainerView.spacing = 0
        avatarsContainerView.clipsToBounds = true
        embed(avatarsContainerView)
        
        leftAvatarsContainerView.axis = .vertical
        leftAvatarsContainerView.distribution = .equal
        leftAvatarsContainerView.alignment = .fill
        leftAvatarsContainerView.clipsToBounds = true
        avatarsContainerView.addArrangedSubview(leftAvatarsContainerView)
        
        leftAvatarsContainerView.addArrangedSubview(avatarImageViews[0])
        leftAvatarsContainerView.addArrangedSubview(avatarImageViews[3])
        
        rightAvatarsContainerView.axis = .vertical
        rightAvatarsContainerView.distribution = .equal
        rightAvatarsContainerView.alignment = .fill
        rightAvatarsContainerView.clipsToBounds = true
        avatarsContainerView.addArrangedSubview(rightAvatarsContainerView)
        
        rightAvatarsContainerView.addArrangedSubview(avatarImageViews[1])
        rightAvatarsContainerView.addArrangedSubview(avatarImageViews[2])
        
        // Add online indicator view
        addSubview(onlineIndicatorView)
        
        onlineIndicatorView.topAnchor
            .pin(equalTo: topAnchor, constant: 1)
            .isActive = true
        onlineIndicatorView.rightAnchor
            .pin(equalTo: rightAnchor, constant: -1)
            .isActive = true
        onlineIndicatorView.widthAnchor
            .pin(equalTo: widthAnchor, multiplier: 0.2)
            .isActive = true
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()

        avatarsContainerView.layer.cornerRadius = min(avatarsContainerView.bounds.width, avatarsContainerView.bounds.height) / 2
    }
    
    override open func updateContent() {
        super.updateContent()
        
        // Clear all spots
        avatarImageViews.forEach { $0.image = nil }
        occupiedAvatarSpots.removeAll()
        
        // After the needed avatars are loaded, hide the unused spots
        defer {
            hideUnusedSpots()
        }
        
        // If we have no valid channel in the content, load a placeholder and return
        guard let channel = content.channel else {
            loadAvatar(into: 0, from: nil, placeholder: appearance.images.userAvatarPlaceholder1)
            return
        }
        
        // If the channel has an avatar set, load that avatar
        if let channelAvatarUrl = channel.imageURL {
            loadAvatar(into: 0, from: channelAvatarUrl, placeholder: appearance.images.userAvatarPlaceholder1)
            return
        }
        
        let lastActiveMembers = channel.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .filter { $0.id != content.currentUserId }
        
        // If there are no members other than the current user in the channel, load a placeholder
        if lastActiveMembers.isEmpty {
            loadAvatar(into: 0, from: nil, placeholder: appearance.images.userAvatarPlaceholder1)
            return
        }
        
        // If the channel is a direct message channel, load the other user's avatar
        // and also set the online indicator visible
        if channel.isDirectMessageChannel {
            let otherMember = lastActiveMembers.first
            loadAvatar(into: 0, from: otherMember?.imageURL, placeholder: appearance.images.userAvatarPlaceholder1)
            isOnlineIndicatorVisible = otherMember?.isOnline ?? false
            return
        }
        
        let placeholderImages = [
            appearance.images.userAvatarPlaceholder1,
            appearance.images.userAvatarPlaceholder2,
            appearance.images.userAvatarPlaceholder3,
            appearance.images.userAvatarPlaceholder4
        ]
        
        // Load the avatars for the 4 last active members.
        for currentSpot in 0..<lastActiveMembers.count where currentSpot < 4 {
            loadAvatar(
                into: currentSpot,
                from: lastActiveMembers[currentSpot].imageURL,
                placeholder: placeholderImages[currentSpot]
            )
        }
    }
    
    /// Hides the unused spots
    open func hideUnusedSpots() {
        // Show taken spots, hide empty ones
        for spotCounter in 0..<avatarImageViews.count {
            avatarImageViews[spotCounter].isHidden = !(occupiedAvatarSpots[spotCounter] ?? false)
        }
        
        rightAvatarsContainerView.isHidden = rightAvatarsContainerView.subviews
            .allSatisfy(\.isHidden)
        leftAvatarsContainerView.isHidden = leftAvatarsContainerView.subviews
            .allSatisfy(\.isHidden)
        avatarsContainerView.isHidden = avatarsContainerView.subviews
            .allSatisfy(\.isHidden)
    }
    
    /// Creates space for indicator view in avatar view by masking path provided by the indicator view.
    /// - Parameter visible: Bool to determine if the indicator should be shown. The avatar view won't be masked if the indicator is not visible.
    open func setUpMask(indicatorVisible: Bool) {
        guard
            indicatorVisible,
            let path = (onlineIndicatorView as? MaskProviding)?.maskingPath?.mutableCopy()
        else { return avatarsContainerView.layer.mask = nil }
        
        path.addRect(bounds)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        maskLayer.fillRule = .evenOdd
        
        avatarsContainerView.layer.mask = maskLayer
    }
    
    /// Loads the avatar from given URL into the specific spot.
    /// - Parameters:
    ///   - spot: The spot in the avatarView where the avatar is to be loaded
    ///   - url: The URL from which the avatar is to be loaded
    ///   - placeholder: The placeholder to be shown if the avatar is not available
    open func loadAvatar(into spot: Int, from url: URL?, placeholder: UIImage) {
        avatarImageViews[spot].loadImage(
            from: url,
            placeholder: placeholder,
            preferredSize: .avatarThumbnailSize,
            components: components
        )
        // Set the spot to occupied
        occupiedAvatarSpots[spot] = true
    }
}
