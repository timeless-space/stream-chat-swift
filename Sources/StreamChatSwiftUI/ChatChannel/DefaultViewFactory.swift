//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import SwiftUI

public protocol ViewFactory: AnyObject {
    associatedtype Factory: ViewFactory
    static var shared: Factory { get }
    
    var chatClient: ChatClient { get }
    
    associatedtype NoContent: View
    func makeNoContentView() -> NoContent
    
    associatedtype LoadingContent: View
    func makeLoadingContentView() -> LoadingContent
    
    associatedtype ChannelDestination: View
    func makeDefaultChannelDestination() -> (ChatChannel) -> ChannelDestination
}

extension ViewFactory {
    public func makeNoContentView() -> NoContentView {
        NoContentView()
    }
    
    public func makeLoadingContentView() -> LoadingContentView {
        LoadingContentView()
    }
    
    public func makeDefaultChannelDestination() ->
        (ChatChannel) -> ChatChannelView<Self> {
        { [unowned self] channel in
            ChatChannelView(viewModel: makeViewModel(for: channel), viewFactory: self)
        }
    }
    
    private func makeViewModel(for channel: ChatChannel) -> ChatChannelViewModel {
        let controller = chatClient.channelController(
            for: channel.cid,
            messageOrdering: .topToBottom
        )
        let viewModel = ChatChannelViewModel(channelController: controller)
        return viewModel
    }
}

public class DefaultViewFactory: ViewFactory {
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = DefaultViewFactory()
}
