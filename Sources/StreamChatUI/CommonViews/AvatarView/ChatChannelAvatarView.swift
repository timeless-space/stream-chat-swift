//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import SkeletonView

/// A view that shows a channel avatar including an online indicator if any user is online.
open class ChatChannelAvatarView: _View, ThemeProvider, SwiftUIRepresentable {
    /// A view that shows the avatar image
    open private(set) lazy var presenceAvatarView: ChatPresenceAvatarView = components
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints
    // Shimmer effect View
    open private(set) lazy var shimmerView: UIView = UIView()
        .withoutAutoresizingMaskConstraints
    // avatar corner radius
    open var avatarCornerRadius: CGFloat = 24
    /// The data this view component shows.
    open var content: (channel: ChatChannel?, currentUserId: UserId?) {
        didSet { updateContentIfNeeded() }
    }
    
    /// The maximum number of images that combine to form a single avatar
    private let maxNumberOfImagesInCombinedAvatar = 4
    
    /// Object responsible for providing functionality of merging images.
    /// Used when creating compound avatars from channel members individual avatars
    open var imageMerger: ImageMerging = {
        DefaultImageMerger()
    }()
    private lazy var imageProcessor: ImageProcessor = {
        return NukeImageProcessor()
    }()
    private lazy var imageCDN: ImageCDN = {
        return StreamImageCDN()
    }()

    // MARK: - Layout
    open override func setUp() {
        super.setUp()
        setUpShimmerView()
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)
        embed(shimmerView)
    }

    open override func setUpAppearance() {
        super.setUpAppearance()
        presenceAvatarView
            .avatarView
            .imageView
            .backgroundColor =  SkeletonAppearance.Settings.shimmerBackgroundColor
    }

    open func setUpShimmerView() {
        shimmerView.isSkeletonable = true
        shimmerView.layer.cornerRadius = avatarCornerRadius
        shimmerView.skeletonCornerRadius = Float(avatarCornerRadius)
        shimmerView.showAnimatedGradientSkeleton()
        shimmerView.isHidden = true
    }

    override open func updateContent() {
        super.updateContent()
        guard let channel = content.channel else {
            loadIntoAvatarImageView(from: nil, placeholder: nil)
            presenceAvatarView.isOnlineIndicatorVisible = false
            return
        }
        loadAvatar(for: channel)
    }

    open func loadAvatar(for channel: ChatChannel) {
        // If the channel has an avatar set, load that avatar
        if let channelAvatarUrl = channel.imageURL {
            loadChannelAvatar(from: channelAvatarUrl)
            return
        }

        // Use the appropriate method to load avatar based on channel type
        if channel.isDirectMessageChannel {
            loadDirectMessageChannelAvatar(channel: channel)
        } else {
            loadMergedAvatars(channel: channel)
        }
    }

    /// Loads the avatar from the URL. This function is used when the channel has a non-nil `imageURL`
    /// - Parameter url: The `imageURL` of the channel
    open func loadChannelAvatar(from url: URL) {
        if let imageContainer = ImagePipeline.shared.cachedImage(for: url) {
            loadIntoAvatarImageView(from: nil, placeholder: imageContainer.image)
            return
        }
        loadIntoAvatarImageView(from: url, placeholder: nil)
    }
    
    /// Loads avatar for a directMessageChannel
    /// - Parameter channel: The channel
    open func loadDirectMessageChannelAvatar(channel: ChatChannel) {
        let lastActiveMembers = self.lastActiveMembers()
        
        // If there are no members other than the current user in the channel, load a placeholder
        guard !lastActiveMembers.isEmpty, let otherMember = lastActiveMembers.first else {
            presenceAvatarView.isOnlineIndicatorVisible = false
            loadIntoAvatarImageView(from: nil, placeholder: nil)
            return
        }
        guard let imageUrl = otherMember.imageURL else {
            loadIntoAvatarImageView(from: nil, placeholder: nil)
            return
        }
        var customKeyForCache = (otherMember.imageURL?.absoluteString ?? "") + (otherMember.extraData.userProfileHash ?? "")
        presenceAvatarView.isOnlineIndicatorVisible = otherMember.isOnline
        if let imageContainer = ImagePipeline.shared.cache.cachedImage(for: customKeyForCache) {
            loadIntoAvatarImageView(from: nil, placeholder: imageContainer.image)
            return
        }
        shimmerView.showAnimatedGradientSkeleton()
        shimmerView.isHidden = false
        loadAvatarsFrom(urls: [otherMember.imageURL], channelId: channel.cid) { [weak self] avatars, channelId in
            guard let weakSelf = self else { return }
            let imageContainer = ImageContainer.init(
                image: avatars.first ?? .init(),
                type: nil,
                isPreview: false,
                data: nil,
                userInfo: ["count": 1])
            ImagePipeline.shared.cache.storeCachedImage(imageContainer, for: customKeyForCache)
            weakSelf.loadIntoAvatarImageView(from: nil, placeholder: imageContainer.image)
        }
    }
    
    /// Loads an avatar which is merged (tiled) version of the first four active members of the channel
    /// - Parameter channel: The channel
    open func loadMergedAvatars(channel: ChatChannel) {
        // The channel is a non-DM channel, hide the online indicator
        presenceAvatarView.isOnlineIndicatorVisible = false
        let lastActiveMembers = self.lastActiveMembers()
        // If there are no members other than the current user in the channel, load a placeholder
        guard !lastActiveMembers.isEmpty else {
            loadIntoAvatarImageView(from: channel.createdBy?.imageURL, placeholder: nil)
            return
        }
        
        var urls = lastActiveMembers.map(\.imageURL)
        var profileHash = lastActiveMembers.map(\.extraData.userProfileHash)

        if urls.isEmpty {
            loadIntoAvatarImageView(from: nil, placeholder: nil)
            return
        }
        
        // We show a combination of at max 4 images combined
        urls = Array(urls.prefix(maxNumberOfImagesInCombinedAvatar))
        var activeUsers = Array(lastActiveMembers.prefix(maxNumberOfImagesInCombinedAvatar))
        let customKeyForCache = activeUsers.compactMap({ $0.extraData.userProfileHash ?? $0.imageURL?.lastPathComponent }).joined()
        // Checked if avatar already cached
        if let imageContainer = ImagePipeline.shared.cache.cachedImage(for: customKeyForCache),
           let cachedUrlCount = imageContainer.userInfo["count"] as? Int,
            urls.count == cachedUrlCount {
                loadIntoAvatarImageView(from: nil, placeholder: imageContainer.image)
                shimmerView.hideSkeleton()
                return
        }
        // showing shimmer effect while loading avatar
        shimmerView.showAnimatedGradientSkeleton()
        shimmerView.isHidden = false
        lastActiveMembers.forEach {
            ImageCache.shared[$0.imageURL] = nil
        }
        loadAvatarsFrom(urls: urls, channelId: channel.cid) { [weak self] avatars, channelId in
            guard let weakSelf = self, channelId == weakSelf.content.channel?.cid
            else { return }
            weakSelf.createMergeAvatarInBackground(avatars: avatars) { combinedImage in
                DispatchQueue.main.async {
                    weakSelf.loadIntoAvatarImageView(from: nil, placeholder: combinedImage)
                    weakSelf.shimmerView.hideSkeleton()
                    if let image = combinedImage {
                        let imageContainer = ImageContainer.init(
                            image: image,
                            type: nil,
                            isPreview: false,
                            data: nil,
                            userInfo: ["count": urls.count])
                        ImagePipeline.shared.cache.storeCachedImage(imageContainer, for: customKeyForCache)
                    }
                }
            }
        }
    }

    private func createMergeAvatarInBackground(
        avatars: [UIImage],
        completion: @escaping ((UIImage?) -> Void)) {
        completion(createMergedAvatar(from: avatars))
    }
    
    /// Loads avatars for the given URLs
    /// - Parameters:
    ///   - urls: The avatar urls
    ///   - channelId: The channelId of the channel
    ///   - completion: Completion that gets called with an array of `UIImage`s when all the avatars are loaded
    open func loadAvatarsFrom(
        urls: [URL?],
        channelId: ChannelId,
        completion: @escaping ([UIImage], ChannelId)
            -> Void
    ) {

        var avatarUrls: [URL] = []
        
        for url in urls.prefix(maxNumberOfImagesInCombinedAvatar) {
            if let avatarUrl = url {
                avatarUrls.append(avatarUrl)
            }
        }

        components.imageLoader.loadImages(
            from: avatarUrls,
            placeholders: [],
            imageCDN: imageCDN
        ) { images in
            completion(images, channelId)
        }
    }
    
    /// Creates a merged avatar from the given images
    /// - Parameter avatars: The individual avatars
    /// - Returns: The merged avatar
    open func createMergedAvatar(from avatars: [UIImage]) -> UIImage? {
        guard !avatars.isEmpty else {
            return nil
        }
        var combinedImage: UIImage?
        let images = avatars.map {
            imageProcessor.scale(image: $0, to: .avatarThumbnailSize)
        }
        // The half of the width of the avatar
        let halfContainerSize = CGSize(width: CGSize.avatarThumbnailSize.width / 2, height: CGSize.avatarThumbnailSize.height)

        if images.count == 1 {
            combinedImage = images[0]
        } else if images.count == 2 {
            let leftImage = imageProcessor.crop(image: images[0], to: halfContainerSize)
            ?? images[0]
            let rightImage = imageProcessor.crop(image: images[1], to: halfContainerSize)
            ?? images[1]
            combinedImage = imageMerger.merge(
                images: [
                    leftImage,
                    rightImage
                ],
                orientation: .horizontal
            )
        } else if images.count == 3 {
            let leftImage = imageProcessor.crop(image: images[0], to: halfContainerSize)

            let rightCollage = imageMerger.merge(
                images: [
                    images[1],
                    images[2]
                ],
                orientation: .vertical
            )

            let rightImage = imageProcessor.crop(
                image: imageProcessor
                    .scale(image: rightCollage ?? images[2], to: .avatarThumbnailSize),
                to: halfContainerSize
            )

            combinedImage = imageMerger.merge(
                images:
                    [
                        leftImage ?? images[0],
                        rightImage ?? images[1]
                    ],
                orientation: .horizontal
            )
        } else if images.count == 4 {
            let leftCollage = imageMerger.merge(
                images: [
                    images[0],
                    images[2]
                ],
                orientation: .vertical
            )

            let leftImage = imageProcessor.crop(
                image: imageProcessor
                    .scale(image: leftCollage ?? images[0], to: .avatarThumbnailSize),
                to: halfContainerSize
            )

            let rightCollage = imageMerger.merge(
                images: [
                    images[1],
                    images[3]
                ],
                orientation: .vertical
            )

            let rightImage = imageProcessor.crop(
                image: imageProcessor
                    .scale(image: rightCollage ?? images[1], to: .avatarThumbnailSize),
                to: halfContainerSize
            )

            combinedImage = imageMerger.merge(
                images: [
                    leftImage ?? images[1],
                    rightImage ?? images[2]
                ],
                orientation: .horizontal
            )
        }

        return combinedImage
    }

    open func lastActiveMembers() -> [ChatChannelMember] {
        guard let channel = content.channel else { return [] }
        return channel.lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .filter { $0.id != content.currentUserId }
    }
    
    open func loadIntoAvatarImageView(from url: URL?, placeholder: UIImage?) {
        if url == nil {
            shimmerView.isHidden = true
            shimmerView.hideSkeleton()
        } else {
            shimmerView.showAnimatedGradientSkeleton()
            shimmerView.isHidden = false
        }
        components.imageLoader.loadImage(
            into: presenceAvatarView.avatarView.imageView,
            url: url,
            imageCDN: components.imageCDN,
            placeholder: placeholder,
            preferredSize: .avatarThumbnailSize
        ) { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.shimmerView.hideSkeleton()
            weakSelf.shimmerView.isHidden = true
        }
    }
}
