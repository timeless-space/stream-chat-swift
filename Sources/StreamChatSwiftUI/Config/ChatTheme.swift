//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

public class ChatTheme {
    public var colors: StreamColors
    public var images: Images
    
    public init(
        colors: StreamColors = StreamColors.defaultColors,
        images: Images = Images()
    ) {
        self.colors = colors
        self.images = images
    }
}

public struct ChatThemeKey: EnvironmentKey {
    public static let defaultValue: ChatTheme = ChatTheme()
}

extension EnvironmentValues {
    public var chatTheme: ChatTheme {
        get {
            self[ChatThemeKey.self]
        }
        set {
            self[ChatThemeKey.self] = newValue
        }
    }
}
