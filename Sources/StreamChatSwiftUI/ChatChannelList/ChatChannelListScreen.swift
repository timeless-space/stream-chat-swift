//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Screen component of the channel list.
/// It's the easiest way to integrate the SDK, but it provides the least customization options.
/// Use the `ChatChannelListView` for more customizations.
public struct ChatChannelListScreen: View {
    public var title: String
    
    public init(title: String = "Stream Chat") {
        self.title = title
    }
    
    public var body: some View {
        ChatChannelListView(
            viewFactory: DefaultViewFactory.shared,
            title: title
        )
    }
}
