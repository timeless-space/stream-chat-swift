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
            ChannelListView(viewModel: ChannelListViewModel())
                .environment(\.components, components)
        }
    }
    */

    // Bound components
    
    @StateObject var channelListViewModel = ChannelListViewModel()
    
    var body: some Scene {
        WindowGroup {
            ChannelListView(viewModel: channelListViewModel)
        }
    }
    
    
//    var body: some Scene {
//        WindowGroup {
//            ChannelsScreen()
//        }
//    }
    
}

class CustomFactory: ViewFactory {
    
    @Injected(\.chatClient) public var chatClient
    
    private init() {}
    
    public static let shared = CustomFactory()

    func makeNoContentView() -> some View {
        CustomNoContentView()
    }
    
}
