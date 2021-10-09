//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

public struct InjectableView<Default>: View where Default: View {
    var injectedView: AnyView?
    var defaultView: Default
    
    @ViewBuilder
    public var body: some View {
        if let injectedView = injectedView {
            injectedView
        } else {
            defaultView
        }
    }
}

public struct InjectableNoContentView: View {
    var injectedView: AnyView?
    
    public var body: some View {
        InjectableView(
            injectedView: injectedView,
            defaultView: NoContentView()
        )
    }
}

public class MessageComponents {
    public init() {}
        
    public var noContentView = InjectableNoContentView()
    
    public func inject(noContentView injected: AnyView) {
        noContentView = InjectableNoContentView(injectedView: injected)
    }
}
