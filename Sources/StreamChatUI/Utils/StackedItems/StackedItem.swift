//
//  StackedItem.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 02/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

public class StackedItem: Equatable {
    public enum AttachmentType {
        case video
        case image
    }
    public static func == (lhs: StackedItem, rhs: StackedItem) -> Bool {
        return lhs.id == rhs.id
    }
    public var id: Int
    public var url: URL
    public var attachmentId: String?
    public var attachmentType: AttachmentType?

    public init(id: Int, url: URL, attachmentType: AttachmentType, attachmentId: String? = nil) {
        self.id = id
        self.attachmentType = attachmentType
        self.url = url
        self.attachmentId = attachmentId
    }
}
