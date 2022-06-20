//
//  ChatUserListDateFormatter.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 22/03/22.
//

import Foundation

// Date Formatter for chat user list
open class ChatUserListDateFormatter: MessageDateSeparatorFormatter {
    
    public var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    public init() {}

    open func format(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
