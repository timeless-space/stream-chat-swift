//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

@main
struct DemoAppSwiftUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ChannelListView(viewModel: ChannelListViewModel(chatClient: ChatClient.shared))
        }
    }
}
