//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

@main
struct DemoAppSwiftUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ChatChannelListView(viewFactory: CustomFactory.shared)
            /*
            // Example for the channel list screen. Uncomment 
            ChatChannelListScreen()
             */
            
        }
    }
}

class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = CustomFactory()
    
    func makeChannelHeaderViewModifier(title: String) -> some ChannelHeaderViewModifier {
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
