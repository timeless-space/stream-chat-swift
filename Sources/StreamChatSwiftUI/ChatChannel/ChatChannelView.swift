//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamChat

public struct ChatChannelView: View {
    
    @StateObject var viewModel: ChatChannelViewModel
    
    public init(viewModel: ChatChannelViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        GeometryReader { proxy in
                            let offset = proxy.frame(in: .named("scrollArea")).minY
                            Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: offset)
                            
                        }
                        
                        LazyVStack {
                            ForEach(viewModel.channel.messages) { message in
                                MessageView(message: message)
                                    .padding()
                                    .flippedUpsideDown()
                            }
                        }
                    }
                    .coordinateSpace(name: "scrollArea")
                    .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                        viewModel.showScrollToLatestButton = value ?? 0 < -20
                    }
                    .flippedUpsideDown()
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
                                Image(systemName: "arrow.down.circle")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        }
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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.subscribeToChannelChanges()
        }
    }
}

struct MessageView: View {
    
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isSentByCurrentUser {
                Spacer()
            }
            
            Text(message.text)
                .padding()
                .background(message.isSentByCurrentUser ?
                            Color.secondary.opacity(0.7) : Color.secondary.opacity(0.3))
                .cornerRadius(24)
            
            if !message.isSentByCurrentUser {
                Spacer()
            }
        }
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
