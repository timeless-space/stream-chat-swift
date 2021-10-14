//
//  CustomUserAvatar.swift
//  DemoAppSwiftUI
//
//  Created by Martin Mitrevski on 14.10.21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import NukeUI
import Nuke

struct CustomUserAvatar: View {
    var author: ChatUser
    
    public var body: some View {
        VStack {
            if let url = author.imageURL?.absoluteString {
                LazyImage(source: url)
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            Text(author.name ?? "")
                .font(.system(size: 13))
                .frame(maxWidth: 60)
        }
    }

}
