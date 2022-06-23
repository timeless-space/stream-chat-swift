//
//  CustomMediaModal.swift
//  StreamChatUI
//
//  Created by Jitendra Sharma on 23/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public class CustomMediaModel {

    public let image: UIImage
    public var url: URL?
    public let type: AttachmentType

    public init(image: UIImage, url: URL?, type: AttachmentType) {
        self.image = image
        self.url = url
        self.type = type
        if type == .image {
            self.url = try? image.temporaryLocalFileUrl()
        }
    }
}
