//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct ComponentsKey: EnvironmentKey {
    public static let defaultValue: Components = Components()
}

extension EnvironmentValues {
        
    public var components: Components {
        get {
            self[ComponentsKey.self]
        }
        set {
            self[ComponentsKey.self] = newValue
        }
    }
    
}

public class Components {
    
    public init(messageComponents: MessageComponents = MessageComponents()) {
        self.messageComponents = messageComponents
    }

    public var messageComponents: MessageComponents
        
}
