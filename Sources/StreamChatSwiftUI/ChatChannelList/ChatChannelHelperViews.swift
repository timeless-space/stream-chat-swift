//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// View for displaying subtitle text.
public struct SubtitleText: View {
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    
    var text: String
    
    public var body: some View {
        Text(text)
            .lineLimit(1)
            .font(fonts.caption1)
            .foregroundColor(Color(colors.subtitleText))
    }
}

/// View container that allows injecting another view in its top right corner.
public struct TopRightView<Content: View>: View {
    var content: () -> Content
    
    public var body: some View {
        HStack {
            Spacer()
            VStack {
                content()
                Spacer()
            }
        }
    }
}

/// View representing the user's avatar.
public struct AvatarView: View {
    var avatar: UIImage
    
    public var body: some View {
        Image(uiImage: avatar)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(
                width: 48,
                height: 48
            )
            .clipShape(Circle())
    }
}
