//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import SwiftUI

/// Factory used to create views.
public protocol ViewFactory: AnyObject {
    var chatClient: ChatClient { get }
    
    /// Returns the navigation bar display mode.
    func navigationBarDisplayMode() -> NavigationBarItem.TitleDisplayMode
    
    associatedtype HeaderViewModifier: ChannelHeaderViewModifier
    /// Creates the channel header view modifier.
    func makeChannelHeaderViewModifier(title: String) -> HeaderViewModifier
    
    associatedtype NoChannels: View
    /// Creates the view that is displayed when there are no channels available.
    func makeNoChannelsView() -> NoChannels
    
    associatedtype ChannelDestination: View
    /// Creates the  channel destination.
    func makeChannelDestination() -> (ChatChannel) -> ChannelDestination
    
    associatedtype LoadingContent: View
    /// Creates the loading view.
    func makeLoadingView() -> LoadingContent
    
    associatedtype MoreActionsView: View
    func makeMoreChannelActionsView(
        for channel: ChatChannel,
        onDismiss: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) -> MoreActionsView
    
    func suppotedMoreChannelActions(
        for channel: ChatChannel,
        onDismiss: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) -> [ChannelAction]
}

/// Default implementations for the `ViewFactory`.
extension ViewFactory {
    public func makeNoChannelsView() -> NoChannelsView {
        NoChannelsView()
    }
    
    public func makeChannelDestination() -> (ChatChannel) -> ChatChannelView<Self> {
        { [unowned self] channel in
            ChatChannelView(viewFactory: self, channel: channel)
        }
    }
    
    public func makeLoadingView() -> LoadingView {
        LoadingView()
    }
    
    public func navigationBarDisplayMode() -> NavigationBarItem.TitleDisplayMode {
        .inline
    }
    
    public func makeChannelHeaderViewModifier(title: String) -> some ChannelHeaderViewModifier {
        DefaultHeaderModifier(title: title)
    }
    
    public func suppotedMoreChannelActions(
        for channel: ChatChannel,
        onDismiss: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) -> [ChannelAction] {
        ChannelAction.defaultActions(
            for: channel,
            chatClient: chatClient,
            onDismiss: onDismiss,
            onError: onError
        )
    }
    
    public func makeMoreChannelActionsView(
        for channel: ChatChannel,
        onDismiss: @escaping () -> Void,
        onError: @escaping (Error) -> Void
    ) -> MoreChannelActionsView {
        MoreChannelActionsView(
            channel: channel,
            channelActions: suppotedMoreChannelActions(
                for: channel,
                onDismiss: onDismiss,
                onError: onError
            ),
            onDismiss: onDismiss
        )
    }
}

/// Default class conforming to `ViewFactory`, used throughout the SDK.
public class DefaultViewFactory: ViewFactory {
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = DefaultViewFactory()
}
