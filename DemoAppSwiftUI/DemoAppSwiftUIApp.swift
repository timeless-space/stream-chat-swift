//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

@main
struct DemoAppSwiftUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Injected(\.chatClient) public var chatClient: ChatClient
    
    var body: some Scene {
        WindowGroup {
            ChatChannelListView(viewFactory: CustomFactory.shared)
            /*
            //Example of custom query filters.
            ChatChannelListView(
                viewFactory: CustomFactory.shared,
                channelListController: customChannelListController
            )
            */
            /*
            // Example for the channel list screen.
            ChatChannelListScreen()
            */
            
        }
    }
    
    private var customChannelListController: ChatChannelListController {
        let controller = chatClient.channelListController(
            query: .init(
                filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: [chatClient.currentUserId!])]),
                sort: [.init(key: .lastMessageAt, isAscending: true)],
                pageSize: 10
            )
        )
        return controller
    }
}

class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = CustomFactory()
    
    func makeChannelListHeaderViewModifier(title: String) -> some ChannelListHeaderViewModifier {
        CustomChannelModifier(title: title)
    }
    
    /*
    // Example for an injected action. Uncomment to see it in action.
    func suppotedMoreChannelActions(
        for channel: ChatChannel,
        onDismiss: @escaping () -> Void
    ) -> [ChannelAction] {
        var defaultActions = ChannelAction.defaultActions(
            for: channel,
            chatClient: chatClient,
            onDismiss: onDismiss
        )
        
        let injectedAction = ChannelAction(
            title: "Injected",
            iconName: "plus",
            action: onDismiss,
            confirmationPopup: nil,
            isDestructive: false
        )
        
        defaultActions.insert(injectedAction, at: 0)
        return defaultActions
    }
     */
    
}
