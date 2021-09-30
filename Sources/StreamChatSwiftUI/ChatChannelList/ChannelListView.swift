//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI
import Combine
import StreamChat

public struct ChannelListView: View {
    
    @StateObject var viewModel: ChannelListViewModel
    
    public init(viewModel: ChannelListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.channels) { channel in
                        NavigationLink {
                            ChatChannelView(viewModel: viewModel.makeViewModel(for: channel))
                        } label: {
                            HStack {
                                Text(viewModel.name(forChannel: channel))
                                Spacer()
                            }
                            .padding()
                        }
                        .foregroundColor(.black)
                    }
                }
            }
            .navigationTitle("Stream Chat")
        }
    }
    
}
