//
//  Dictionary+Extensions.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

extension Dictionary {
    func data() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}
