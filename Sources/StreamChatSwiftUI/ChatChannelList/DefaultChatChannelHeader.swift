//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// View modifier for customizing the channel header.
public protocol ChannelHeaderViewModifier: ViewModifier {
    var title: String { get }
}

/// The default channel header.
public struct DefaultChatChannelHeader: ToolbarContent {
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    
    public var title: String
    
    public var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(title)
                .font(fonts.bodyBold)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                NewChatView()
            } label: {
                Image(uiImage: images.messageActionEdit)
                    .resizable()
            }
        }
    }
}

/// The default header modifier.
public struct DefaultHeaderModifier: ChannelHeaderViewModifier {
    public var title: String
    
    public func body(content: Content) -> some View {
        content.toolbar {
            DefaultChatChannelHeader(title: title)
        }
    }
}
