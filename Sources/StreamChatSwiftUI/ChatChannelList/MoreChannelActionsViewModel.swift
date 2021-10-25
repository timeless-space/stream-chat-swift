//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

/// View model for the more channel actions.
public class MoreChannelActionsViewModel: ObservableObject {
    /// Context provided values.
    @Injected(\.utils) var utils
    @Injected(\.chatClient) var chatClient
    @Injected(\.images) var images
    
    /// Private vars.
    private lazy var channelNamer = utils.channelNamer
    private lazy var imageLoader = utils.imageLoader
    private lazy var imageCDN = utils.imageCDN
    private lazy var placeholder2 = images.userAvatarPlaceholder2
    
    /// Published vars.
    @Published var channelActions: [ChannelAction]
    @Published var alertShown = false
    @Published var alertAction: ChannelAction? {
        didSet {
            alertShown = alertAction != nil
        }
    }

    @Published var memberAvatars = [String: UIImage]()
    @Published var members = [ChatChannelMember]()
    
    /// Computed vars.
    public var chatName: String {
        name(forChannel: channel)
    }
    
    public var subtitleText: String {
        guard let currentUserId = chatClient.currentUserId else {
            return ""
        }

        if channel.isDirectMessageChannel {
            guard let member = channel
                .lastActiveMembers
                .first(where: { $0.id != currentUserId })
            else {
                return ""
            }

            if member.isOnline {
                return L10n.Message.Title.online
            } else if let lastActiveAt = member.lastActiveAt,
                      let timeAgo = lastSeenDateFormatter(lastActiveAt) {
                return timeAgo
            } else {
                return L10n.Message.Title.offline
            }
        }

        return L10n.Message.Title.group(channel.memberCount, channel.watcherCount)
    }
    
    private let channel: ChatChannel
    
    private var lastSeenDateFormatter: (Date) -> String? {
        DateUtils.timeAgo
    }
    
    public init(
        channel: ChatChannel,
        channelActions: [ChannelAction]
    ) {
        self.channelActions = channelActions
        self.channel = channel
        members = channel.lastActiveMembers.filter { [unowned self] member in
            member.id != chatClient.currentUserId
        }
    }
    
    /// Returns an image for a member.
    ///
    /// - Parameter member: the chat channel member.
    /// - Returns: downloaded image or a placeholder.
    func image(for member: ChatChannelMember) -> UIImage {
        if let image = memberAvatars[member.id] {
            return image
        }
        
        imageLoader.loadImage(
            url: member.imageURL,
            imageCDN: imageCDN,
            resize: true,
            preferredSize: .avatarThumbnailSize
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(image):
                self.memberAvatars[member.id] = image
            case let .failure(error):
                // TODO: proper logger.
                print("error loading image: \(error.localizedDescription)")
            }
        }
        
        return placeholder2
    }
    
    // MARK: - private
    
    private func name(forChannel channel: ChatChannel) -> String {
        channelNamer(channel, chatClient.currentUserId) ?? ""
    }
}

/// Model describing a channel action.
public struct ChannelAction: Identifiable {
    public var id: String {
        "\(title)-\(iconName)"
    }

    public let title: String
    public let iconName: String
    public let action: () -> Void
    public let confirmationPopup: ConfirmationPopup?
    public let isDestructive: Bool
}

/// Model describing confirmation popup data.
public struct ConfirmationPopup {
    let title: String
    let message: String?
    let buttonTitle: String
}
