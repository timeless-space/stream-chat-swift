//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct NoContentView: View {
    
    public var body: some View {
        VStack {
            Spacer()
            Text("There are no new messages.")
                .padding()
            Spacer()
        }
    }
    
}
