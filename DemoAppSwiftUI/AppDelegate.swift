//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatSwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var streamChat: StreamChat?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        connectUser(withCredentials: UserCredentials.mock)
        return true
    }
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    private func connectUser(withCredentials credentials: UserCredentials) {
        let token = try! Token(rawValue: credentials.token)
        LogConfig.level = .warning
        var config = ChatClientConfig(apiKey: .init(apiKeyString))
        config.isLocalStorageEnabled = true

        let client = ChatClient(config: config)
        streamChat = StreamChat(chatClient: client)
        
        client.connectUser(
            userInfo: .init(id: credentials.id, name: credentials.name, imageURL: credentials.avatarURL),
            token: token
        ) { error in
            if let error = error {
                log.error("connecting the user failed \(error)")
                return
            }
        }
    }
    
    // Change theme
    var chatTheme: ChatTheme = {
        let colors = StreamColors(appBackground: .gray.opacity(0.1))
        let chatTheme = ChatTheme(colors: colors)
        return chatTheme
    }()
    
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {}
