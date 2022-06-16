//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension Date {
    /// Returns a new random date
    static var unique: Date { Date(timeIntervalSince1970: .random(in: 1_000_000...1_500_000_000)) }

    /// Returns a new random date before the provided date
    static func unique(before date: Date, after: Date = Date.distantPast) -> Date {
        Date(timeIntervalSince1970: .random(in: after.timeIntervalSince1970..<date.timeIntervalSince1970 - 1))
    }

    /// Returns a new random date after the provided date
    static func unique(after date: Date) -> Date {
        Date(timeIntervalSince1970: .random(in: (date.timeIntervalSince1970 + 1)...Date.distantFuture.timeIntervalSince1970))
    }
}
