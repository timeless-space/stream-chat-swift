//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct MessageListAnyView: View, KeyboardReadable {
    @StateObject var viewModel: ChatChannelAnyViewModel
    
    @State var width: CGFloat?
    @State var height: CGFloat?
    @State var keyboardShown = false
    
    var body: some View {
        ZStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    GeometryReader { proxy in
                        let frame = proxy.frame(in: .named("scrollArea"))
                        let offset = frame.minY
                        let width = frame.width
                        let height = frame.height
                        Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
                        Color.clear.preference(key: WidthPreferenceKey.self, value: width)
                        Color.clear.preference(key: HeightPreferenceKey.self, value: height)
                    }
                    
                    LazyVStack {
                        ForEach(viewModel.channel.messages.indices, id: \.self) { index in
                            MessageView(
                                message: viewModel.channel.messages[index],
                                width: self.width,
                                onDoubleTap: {}
                            )
                            .padding()
                            .flippedUpsideDown()
                            .onAppear {
                                viewModel.checkForNewMessages(index: index)
                                viewModel.save(lastDate: viewModel.channel.messages[index].createdAt)
                            }
                            .id(viewModel.channel.messages[index].id)
                        }
                    }
                }
                .coordinateSpace(name: "scrollArea")
                .onPreferenceChange(WidthPreferenceKey.self) { value in
                    if let value = value, value != width {
                        self.width = value
                    }
                }
                .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                    viewModel.showScrollToLatestButton = value ?? 0 < -20
                }
                .onPreferenceChange(HeightPreferenceKey.self) { value in
                    if let value = value, value != height {
                        self.height = value
                    }
                }
                .flippedUpsideDown()
                .frame(minWidth: self.width, minHeight: height)
                .onChange(of: viewModel.scrolledId) { scrolledId in
                    if let scrolledId = scrolledId {
                        viewModel.scrolledId = nil
                        withAnimation {
                            scrollView.scrollTo(scrolledId, anchor: .bottom)
                        }
                    }
                }
            }
            
            if viewModel.showScrollToLatestButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.scrollToLastMessage()
                        } label: {
                            Image(systemName: "arrow.down")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.all, 8)
                                .background(Color.white.clipShape(Circle()))
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                        }
                        .padding()
                    }
                }
            }
            
            if let date = viewModel.currentDateString {
                VStack {
                    Text(date)
                        .padding(.all, 4)
                        .foregroundColor(.white)
                        .background(Color.gray)
                        .cornerRadius(8)
                        .padding(.all, 4)
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.subscribeToChannelChanges()
        }
        .onReceive(keyboardPublisher) { visible in
            keyboardShown = visible
        }
        .modifier(HideKeyboardOnTapGesture(shouldAdd: keyboardShown))
    }
}
