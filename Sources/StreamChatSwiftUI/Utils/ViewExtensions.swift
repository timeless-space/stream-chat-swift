//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension View {
    /// Returns the bottom safe area of the device.
    public var bottomSafeArea: CGFloat {
        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        return bottomPadding
    }
}
