//
//  ChatInviteInfo.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 22/04/22.
//

import Foundation

// MARK: - ChatInviteInfo
public struct ChatInviteInfo: Codable {
    public let channel: Channel
    public let members: [Member]
    public let isMember: Bool

    enum CodingKeys: String, CodingKey {
        case channel, members
        case isMember = "is_member"
    }
}

// MARK: - Channel
public struct Channel: Codable {
    public let cid, name: String?
    public let channelDescription: String?
}

// MARK: - Member
public struct Member: Codable {
    public let userID: String?
    public let user: User?
    public let createdAt, updatedAt: String?
    public let banned, shadowBanned: Bool?
    public let role, channelRole: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case banned
        case shadowBanned = "shadow_banned"
        case role
        case channelRole = "channel_role"
    }
}

// MARK: - User
public struct User: Codable {
    public let banned, online: Bool?
    public let userID, id, role, createdAt: String?
    public let image: String?
    public let walletAddress, updatedAt, lastActive, name: String?

    enum CodingKeys: String, CodingKey {
        case banned, online
        case userID = "userId"
        case id, role
        case createdAt = "created_at"
        case image, walletAddress
        case updatedAt = "updated_at"
        case lastActive = "last_active"
        case name
    }
}

public struct CreatePrivateGroup: Codable {
    public let cid: String?
    public let password: String?
}
