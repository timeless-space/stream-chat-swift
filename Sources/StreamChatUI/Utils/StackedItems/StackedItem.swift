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

    public static func staticData() -> [StackedItem] {
        var items = [StackedItem]()
        items.append(.init(id: 0, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/shh.png")!, attachmentType: .image))
        items.append(.init(id: 1, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/celebrate.gif")!, attachmentType: .image))
        items.append(.init(id: 2, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/cheers.gif")!, attachmentType: .image))
        items.append(.init(id: 3, url: URL.init(string: "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/thanks.png")!, attachmentType: .image))
        items.append(.init(id: 4, url: URL.init(string: "https://res.cloudinary.com/timeless/video/upload/v1644831818/app/Wallet/shopping-travel.mp4")!, attachmentType: .video))
        items.append(.init(id: 5, url: URL.init(string: "https://res.cloudinary.com/timeless/video/upload/v1644831819/app/Wallet/wellbeing-calm.mp4")!, attachmentType: .video))
        return items
    }
}
