//
//  MusicBubbleView.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/07/22.
//

import SwiftUI
import Combine
import StreamChatUI

struct MusicBubbleView: View {

    var title: String
    var subTitle: String
    var imageUrl: String
    var uri: String

    var body: some View {
        HStack(spacing: 0) {
            mediaView()
                .padding(.init(10))
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 18))
                    .foregroundColor(Color.white)
                Text(subTitle)
                    .font(.system(size: 16))
                    .foregroundColor(Color.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(5)
        .cornerRadius(10)
    }

    private func mediaView() -> some View {
        ZStack {
            if let imageUrl = URL(string: imageUrl) {
                AsyncImage(
                    url: imageUrl,
                    content: { image in
                        image.resizable()
                            .cornerRadius(10)
                            .aspectRatio(contentMode: .fit)
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
                .frame(width: 80, height: 80)
            }

            Image("playMusic")
                .resizable()
                .foregroundColor(Color.white)
                .frame(width: 30, height: 30, alignment: .center)
        }
    }
}
