//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Date {
    /// The code snippet is taken from [stackoverflow](https://stackoverflow.com/a/40654331/3825788)
    func distance(from date: Date, only component: Calendar.Component, calendar: Calendar = .current) -> Int {
        let days1 = calendar.component(component, from: self)
        let days2 = calendar.component(component, from: date)
        return days1 - days2
    }
    
    func hasSame(_ component: Calendar.Component, as date: Date) -> Bool {
        distance(from: date, only: component) == 0
    }
}
