//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat
import NukeUI

public struct ChatChannelView: View, KeyboardReadable {
    
    @StateObject var viewModel: ChatChannelViewModel
    
    @State var width: CGFloat?
    @State var height: CGFloat?
    @State var keyboardShown = false
        
    public init(viewModel: ChatChannelViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
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
                                MessageView(message: viewModel.channel.messages[index],
                                            spacerWidth: (self.width ?? 0) / 4)
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
            
            Divider()
            
            HStack {
                TextField("Send a message", text: $viewModel.text)
                Spacer()
                Button {
                    viewModel.sendMessage()
                } label: {
                    Text("Send")
                }
            }
            .padding()
        }
        .onReceive(keyboardPublisher) { visible in
            keyboardShown = visible
        }
        .modifier(HideKeyboardOnTapGesture(shouldAdd: keyboardShown))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.subscribeToChannelChanges()
        }
    }
}

struct MessageView: View {
    
    let message: ChatMessage
    var spacerWidth: CGFloat?
    
    var body: some View {
        HStack {
            if message.isSentByCurrentUser {
                MessageSpacer(spacerWidth: spacerWidth)
            } else {
                if let url = message.author.imageURL?.absoluteString {
                    LazyImage(source: url)
                        .clipShape(Circle())
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                }
            }
            
            if message.imageAttachments.count > 0 {
                if message.text.isEmpty {
                    LazyImage(source: message.imageAttachments[0].imagePreviewURL)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                } else {
                    VStack {
                        if message.imageAttachments.count > 0 {
                            LazyImage(source: message.imageAttachments[0].imagePreviewURL)
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(24)
                        }

                        Text(message.text)
                    }
                    .padding()
                    .background(message.isSentByCurrentUser ?
                                Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3))
                    .cornerRadius(24)
                }
            } else {
                Text(message.text)
                    .padding()
                    .background(message.isSentByCurrentUser ?
                                Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3))
                    .cornerRadius(24)
            }
            
            if !message.isSentByCurrentUser {
                MessageSpacer(spacerWidth: spacerWidth)
            }
        }
    }
    
}

struct MessageSpacer: View {
    
    var spacerWidth: CGFloat?
    
    var body: some View {
        Spacer()
            .frame(minWidth: spacerWidth)
            .layoutPriority(-1)
    }

}

struct FlippedUpsideDown: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.radians(Double.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
    
}

extension View {
    
    func flippedUpsideDown() -> some View{
        self.modifier(FlippedUpsideDown())
    }
    
}

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
    
}

struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
    
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
    
}
