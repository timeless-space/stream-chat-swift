//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamChat
import SwiftUI

public struct MessageAvatarView: View {
    var author: ChatUser
    
    public var body: some View {
        if let url = author.imageURL?.absoluteString {
            LazyImage(source: url)
                .clipShape(Circle())
                .frame(width: 40, height: 40)
        } else {
            Image(systemName: "person.circle")
                .resizable()
                .frame(width: 40, height: 40)
        }
    }
}
