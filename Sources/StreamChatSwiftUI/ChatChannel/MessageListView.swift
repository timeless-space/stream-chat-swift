//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

struct MessageListView<Factory: ViewFactory>: View, KeyboardReadable {
    var factory: Factory
    @Binding var messages: LazyCachedMapCollection<ChatMessage>
    @Binding var scrolledId: String?
    @Binding var showScrollToLatestButton: Bool
    @Binding var currentDateString: String?
    
    var onMessageAppear: (Int) -> Void
    var onScrollToBottom: () -> Void
    
    @State private var width: CGFloat?
    @State private var height: CGFloat?
    @State private var keyboardShown = false
    
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
                        ForEach(messages.indices, id: \.self) { index in
                            MessageView(
                                factory: factory,
                                message: messages[index],
                                width: width,
                                onDoubleTap: {
                                    // viewModel.addReaction(to: viewModel.messages[index])
                                }
                            )
                            .padding()
                            .flippedUpsideDown()
                            .onAppear {
                                onMessageAppear(index)
                            }
                            .id(messages[index].id)
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
                    showScrollToLatestButton = value ?? 0 < -20
                }
                .onPreferenceChange(HeightPreferenceKey.self) { value in
                    if let value = value, value != height {
                        self.height = value
                    }
                }
                .flippedUpsideDown()
                .frame(minWidth: self.width, minHeight: height)
                .onChange(of: scrolledId) { scrolledId in
                    if let scrolledId = scrolledId {
                        self.scrolledId = nil
                        withAnimation {
                            scrollView.scrollTo(scrolledId, anchor: .bottom)
                        }
                    }
                }
            }
            
//            if !viewModel.typingUsers.isEmpty {
//                VStack {
//                    Spacer()
//                    HStack {
//                        Text("\(viewModel.typingUsers[0]) is typing...")
//                            .padding(.horizontal)
//                            .padding(.vertical, 2)
//                        Spacer()
//                    }
//                    .background(Color.white.opacity(0.9))
//                }
//            }
//
            if showScrollToLatestButton {
                ScrollToBottomButton(onScrollToBottom: onScrollToBottom)
            }
            
            if let date = currentDateString {
                DateIndicatorView(date: date)
            }
        }
        .onReceive(keyboardPublisher) { visible in
            keyboardShown = visible
        }
        .modifier(HideKeyboardOnTapGesture(shouldAdd: keyboardShown))
    }
}

public struct ScrollToBottomButton: View {
    var onScrollToBottom: () -> Void
    
    public var body: some View {
        BottomRightView {
            Button {
                onScrollToBottom()
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

public struct DateIndicatorView: View {
    var date: String
    
    public var body: some View {
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
