//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

public class StreamColors {
    
    public var appBackground: Color
    
    public init(appBackground: Color = Color.white) {
        self.appBackground = appBackground
    }
    
    public static let defaultColors = StreamColors()
    
}
