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
                Text("Wolves")
                    .font(.system(size: 18))
                    .foregroundColor(Color.white)
                Text("Selena Gomez")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white)
                Text("Album here")
                    .font(.system(size: 14))
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
            Image("test")
                .resizable()
                .cornerRadius(10)
                .frame(width: 80, height: 80)

            Image("playMusic")
                .resizable()
                .foregroundColor(Color.white)
                .frame(width: 30, height: 30, alignment: .center)
        }
    }
}
