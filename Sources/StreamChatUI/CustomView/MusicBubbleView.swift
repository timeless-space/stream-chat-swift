//
//  MusicBubbleView.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/07/22.
//

import SwiftUI

struct MusicBubbleView: View {

    var body: some View {
        HStack(spacing: 0) {
            mediaView()
                .padding(.init(10))
            VStack(alignment: .leading) {
                Text("Song Name here")
                    .foregroundColor(Color.white)
                Text("Artist name here")
                    .foregroundColor(Color.white)
                Text("Album here")
                    .foregroundColor(Color.gray)
                    .frame(alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(5)
        .cornerRadius(10)
    }

    private func mediaView() -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.yellow)
                .frame(width: 80, height: 80)
                .cornerRadius(10)

//            Image(uiImage: UIImage(systemName: "pencil")!)
//                .resizable()
//                .cornerRadius(10)
//                .frame(width: 50, height: 50)

            Image(uiImage: UIImage(systemName: "play")!)
                .resizable()
                .foregroundColor(Color.white)
                .frame(width: 30, height: 30, alignment: .center)
        }
    }
}
