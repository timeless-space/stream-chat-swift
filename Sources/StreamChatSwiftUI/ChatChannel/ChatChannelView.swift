//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

public struct ChatChannelView<Factory: ViewFactory>: View {
    @StateObject private var viewModel: ChatChannelViewModel
    
    private var factory: Factory
    
    public init(
        viewFactory: Factory,
        channel: ChatChannel
    ) {
        _viewModel = StateObject(
            wrappedValue: ViewModelsFactory.makeChannelViewModel(for: channel)
        )
        factory = viewFactory
    }
    
    public var body: some View {
        Text("message view")
    }
}
