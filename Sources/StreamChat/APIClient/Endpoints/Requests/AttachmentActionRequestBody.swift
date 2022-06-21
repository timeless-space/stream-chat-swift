//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `message/{id}/action` endpoint
struct AttachmentActionRequestBody: Encodable {
    private enum CodingKeys: String, CodingKey {
        case channelId = "id"
        case channelType = "type"
        case messageId = "message_id"
        case data = "form_data"
    }

    let cid: ChannelId
    let messageId: MessageId
    let action: AttachmentAction
    let poll: [String: RawJSON]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(cid.id, forKey: .channelId)
        try container.encode(cid.type, forKey: .channelType)
        try container.encode(messageId, forKey: .messageId)
        let encoder = JSONEncoder()
        var string = ""
        if let jsonData = try? encoder.encode(poll) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                string = jsonString
            }
        }

        try container.encode([action.name: action.value, "poll": string], forKey: .data)
    }
}
