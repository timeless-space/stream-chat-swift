//
//  ChannelListDateFormatter.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 22/03/22.
//

import Foundation

open class ChannelListDateFormatter {
    enum dateFormatType: String {
        case shortWeekDateFormat = "EE"
        case dayMonthDateFormatter = "MM/dd"
        case longDateFormatter = "MM/DD/YY"
    }
    private var dateFormatter = DateFormatter()
    
    func formatDate(with type: dateFormatType, date: Date) -> String {
        dateFormatter.dateFormat  = type.rawValue
        return format(date)
    }

    public init() {}

    private func format(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
