//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

@main
struct DemoAppSwiftUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Using global type erased views.
    /*
    private var components: Components = {
        let messageComponents = MessageComponents()
        messageComponents.inject(
            noContentView:
                AnyView(
                    CustomNoContentView()
                )
        )
        return Components(messageComponents: messageComponents)
    }()
            
    
    var body: some Scene {
        WindowGroup {
            ChannelListView(viewModel: ChannelListViewModel(chatClient: ChatClient.shared))
                .environment(\.components, components)
        }
    }
     */

    @StateObject var channelListViewModel = ChannelListViewModel(chatClient: ChatClient.shared)
    
    var body: some Scene {
        WindowGroup {
            ChannelListView(viewModel: channelListViewModel) { chatChannel in
                ChatChannelView(
                    viewModel: channelListViewModel.makeViewModel(for: chatChannel),
                    noContentView: CustomNoContentView()
                )
            }
        }
    }
    
}
