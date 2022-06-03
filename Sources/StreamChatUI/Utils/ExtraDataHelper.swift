//
//  ExtraDataHelper.swift
//  StreamChat
//
//  Created by Ajay Ghodadra on 04/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension Dictionary where Key == String, Value == RawJSON {
    func getExtraData(key: String) -> [String: RawJSON]? {
        if let extraData = self[key] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getExtraDataArray(key: String) -> [RawJSON]? {
        if let extraData = self[key] {
            switch extraData {
            case .array(let array):
                return array
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}

// MARK: - DAO
public extension Dictionary where Key == String, Value == RawJSON {
    var minimumContribution: String? {
        if let minimumContribution = self["minimumContribution"] {
            return fetchRawData(raw: minimumContribution) as? String
        } else {
            return nil
        }
    }

    var charityThumb: String? {
        if let charityThumb = self["charityThumb"] {
            return fetchRawData(raw: charityThumb) as? String
        } else {
            return nil
        }
    }

    var safeAddress: String? {
        if let charityThumb = self["safeAddress"] {
            return fetchRawData(raw: charityThumb) as? String
        } else {
            return nil
        }
    }

    var daoName: String? {
        if let daoName = self["daoName"] {
            return fetchRawData(raw: daoName) as? String
        } else {
            return nil
        }
    }

    var masterWalletAddress: String? {
        if let masterWalletAddress = self["masterWalletAddress"] {
            return fetchRawData(raw: masterWalletAddress) as? String
        } else {
            return nil
        }
    }

    var daoExpireDate: String? {
        if let daoExpireDate = self["daoExpireDate"] {
            return fetchRawData(raw: daoExpireDate) as? String
        } else {
            return nil
        }
    }

    var daoJoinLink: String? {
        if let daoJoinLink = self["daoJoinLink"] {
            return fetchRawData(raw: daoJoinLink) as? String
        } else {
            return nil
        }
    }

    var daoDescription: String? {
        if let daoDescription = self["daoDescription"] {
            return fetchRawData(raw: daoDescription) as? String
        } else {
            return nil
        }
    }

    var daoGroupCreator: String? {
        if let daoGroupCreator = self["groupCreator"] {
            return fetchRawData(raw: daoGroupCreator) as? String
        } else {
            return nil
        }
    }

    var signers: [String] {
        if let arrSigners = self["signers"] {
            let rawJson = fetchRawData(raw: arrSigners) as? [RawJSON] ?? [RawJSON]()
            return rawJson.map({ fetchRawData(raw: $0) as? String ?? ""})
        } else {
            return []
        }
    }
}

// MARK: - Admin Message
public extension Dictionary where Key == String, Value == RawJSON {
    var adminMessage: String? {
        guard let adminMessage = getExtraData(key: "adminMessage") else {
            return nil
        }
        if let strMessage = adminMessage["adminMessage"] {
            return fetchRawData(raw: strMessage) as? String
        } else {
            return nil
        }
    }
    var adminMessageMembers: [String: RawJSON]? {
        guard let adminMessage = getExtraData(key: "adminMessage") else {
            return nil
        }
        if let userIDs = adminMessage["members"] {
            return fetchRawData(raw: userIDs) as? [String: RawJSON]
        } else {
            return nil
        }
    }
    var adminMessageType: AdminMessageType {
        if let messageType = self["messageType"] {
            let rawValue = fetchRawData(raw: messageType) as? String ?? ""
            return AdminMessageType(rawValue: rawValue) ?? .none
        } else {
            return .none
        }
    }

    var daoAdmins: [[String: Any]] {
        var arrOut: [[String: Any]] = []
        if let admin = self["adminMessage"] {
            let rawJson = fetchRawData(raw: admin) as? [String: RawJSON] ?? [String: RawJSON]()
            if rawJson.keys.contains("adminMessage") {
                let arrAdmins = fetchRawData(raw: rawJson["adminMessage"]!) as? [RawJSON] ?? [RawJSON]()
                for admin in arrAdmins {
                    let dictAdmin = fetchRawData(raw: admin) as? [String: RawJSON] ?? [String: RawJSON]()
                    print(dictAdmin)
                    var dictOut: [String: Any] = [:]
                    if dictAdmin.keys.contains("signerName") {
                        dictOut["signerName"] = fetchRawData(raw: dictAdmin["signerName"]!) as? String ?? ""
                    }
                    if dictAdmin.keys.contains("signerUserId") {
                        dictOut["signerUserId"] = fetchRawData(raw: dictAdmin["signerUserId"]!) as? String ?? ""
                    }
                    arrOut.append(dictOut)
                }
                return arrOut
            } else {
                return arrOut
            }
            return arrOut
        } else {
            return arrOut
        }
    }
}

// MARK: - Normal Channel

public extension Dictionary where Key == String, Value == RawJSON {
    var channelDescription: String? {
        if let channelDescription = self[kExtraDataChannelDescription] {
            return fetchRawData(raw: channelDescription) as? String
        } else {
            return nil
        }
    }
    
    var isTreasureGroup: Bool {
        if let isTreasureGroup = self["isTreasureGroup"] {
            return fetchRawData(raw: isTreasureGroup) as? Bool ?? false
        } else {
            return false
        }
    }

    var joinLink: String? {
        if let joinLink = self["joinLink"] {
            return fetchRawData(raw: joinLink) as? String
        } else {
            return nil
        }
    }
}

// MARK: - RedPacketAmountBubble txId
public extension Dictionary where Key == String, Value == RawJSON {
    var txId: String? {
        if let txId = self["txId"] {
            return fetchRawData(raw: txId) as? String
        } else {
            return nil
        }
    }
}

// MARK: - RedPacket other amount bubble
public extension Dictionary where Key == String, Value == RawJSON {
    private var redPacketOtherAmountExtraData: [String: RawJSON] {
        if let extraData = self["RedPacketOtherAmountReceived"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return [:]
            }
        } else {
            return [:]
        }
    }

    var otherAmountUserId: String? {
        if let userId = redPacketOtherAmountExtraData["userId"] {
            return fetchRawData(raw: userId) as? String
        } else {
            return nil
        }
    }

    var otherReceivedAmount: String? {
        if let amount = redPacketOtherAmountExtraData["receivedAmount"] {
            let dblAmount = fetchRawData(raw: amount) as? Double ?? 0
            return "\(dblAmount)"
        } else {
            return nil
        }
    }

    var otherAmuntReceivedUserName: String? {
        if let userName = redPacketOtherAmountExtraData["userName"] {
            return fetchRawData(raw: userName) as? String
        } else {
            return nil
        }
    }

    var otherAmountReceivedCongratesKey: String? {
        if let congrates = redPacketOtherAmountExtraData["congratsKey"] {
            return fetchRawData(raw: congrates) as? String
        } else {
            return nil
        }
    }

    var otherAmountTxId: String? {
        if let txId = redPacketOtherAmountExtraData["txId"] {
            return fetchRawData(raw: txId) as? String
        } else {
            return nil
        }
    }
}

// MARK: - RedPacket Top Amount cell
public extension Dictionary where Key == String, Value == RawJSON {
    private var redPacketTopAmountExtraData: [String: RawJSON] {
        if let extraData = self["RedPacketTopAmountReceived"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return [:]
            }
        } else {
            return [:]
        }
    }

    var topReceivedAmount: String? {
        if let amount = redPacketTopAmountExtraData["receivedAmount"] {
            let dblAmount = fetchRawData(raw: amount) as? Double ?? 0
            return "\(dblAmount)"
        } else {
            return nil
        }
    }

    var highestAmountUserName: String? {
        if let userName = redPacketTopAmountExtraData["highestAmountUserName"] {
            return fetchRawData(raw: userName) as? String
        } else {
            return nil
        }
    }

    var highestAmountUserId: String? {
        if let userId = redPacketTopAmountExtraData["highestAmountUserId"] {
            return fetchRawData(raw: userId) as? String
        } else {
            return nil
        }
    }
}

// MARK: - Send ONE cell
public extension Dictionary where Key == String, Value == RawJSON {
    private var sendOneExtraData: [String: RawJSON] {
        if let extraData = self["oneWalletTx"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return [:]
            }
        } else {
            return [:]
        }
    }

    var sentOneTxId: String? {
        if let txId = sendOneExtraData["txId"] {
            return fetchRawData(raw: txId) as? String
        } else {
            return nil
        }
    }

    var sentOneRecipientName: String? {
        if let recipientName = sendOneExtraData["recipientName"] {
            return fetchRawData(raw: recipientName) as? String
        } else {
            return nil
        }
    }

    var sentOneTransferAmount: String? {
        if let transferAmount = sendOneExtraData["transferAmount"] {
            let dblAmount = fetchRawData(raw: transferAmount) as? Double ?? 0
            return "\(dblAmount)"
        } else {
            return nil
        }
    }

    var sentOnePaymentTheme: String? {
        if let paymentTheme = sendOneExtraData["paymentTheme"] {
            return fetchRawData(raw: paymentTheme) as? String
        } else {
            return nil
        }
    }
}

// MARK: - TedPacket Expired cell
public extension Dictionary where Key == String, Value == RawJSON {
    private var redPacketExpiredExtraData: [String: RawJSON] {
        if let extraData = self["RedPacketExpired"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return [:]
            }
        } else {
            return [:]
        }
    }

    var redPacketExpiredHighestAmountUserName: String? {
        if let userName = redPacketExpiredExtraData["highestAmountUserName"] {
            return fetchRawData(raw: userName) as? String
        } else {
            return nil
        }
    }
}

// MARK: - Wallet request pay bubble
public extension Dictionary where Key == String, Value == RawJSON {
    var recipientName: String? {
        if let recipientName = self["recipientName"] {
            return fetchRawData(raw: recipientName) as? String
        } else {
            return nil
        }
    }

    var requestedThemeUrl: String? {
        if let paymentTheme = self["paymentTheme"] {
            return fetchRawData(raw: paymentTheme) as? String
        } else {
            return nil
        }
    }

    var recipientUserId: String? {
        if let recipientUserId = self["recipientUserId"] {
            return fetchRawData(raw: recipientUserId) as? String
        } else {
            return nil
        }
    }
}

// MARK: - Announcement
public extension Dictionary where Key == String, Value == RawJSON {
    var tag: [String]? {
        guard let tags = getExtraDataArray(key: "tags") else {
            return nil
        }
        return tags.map { fetchRawData(raw: $0) as? String ?? "" }
    }
    
    var cta: String? {
        if let ctaStr = self["cta"] {
            return fetchRawData(raw: ctaStr) as? String
        } else {
            return nil
        }
    }

    var ctaData: String? {
        if let ctaDataStr = self["cta_data"] {
            return fetchRawData(raw: ctaDataStr) as? String
        } else {
            return nil
        }
    }

    var requestedIsPaid: Bool {
        if let isPaid = self["isPaid"] {
            return fetchRawData(raw: isPaid) as? Bool ?? true
        } else {
            return true
        }
    }

    var requestedImageUrl: String? {
        if let recipientImageUrl = self["recipientImageUrl"] {
            return fetchRawData(raw: recipientImageUrl) as? String
        } else {
            return nil
        }
    }

    var requestedAmount: String? {
        if let transferAmount = self["transferAmount"] {
            return fetchRawData(raw: transferAmount) as? String
        } else {
            return nil
        }
    }
}

// MARK: - RedPacket PickUp Bubble
public extension Dictionary where Key == String, Value == RawJSON {
    private var redPacketExtraData: [String: RawJSON] {
        if let extraData = self["redPacketPickup"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return [:]
            }
        } else {
            return [:]
        }
    }

    var redPacketTitle: String? {
        if let title = redPacketExtraData["title"] {
            return fetchRawData(raw: title) as? String
        } else {
            return nil
        }
    }

    var redPacketMyName: String? {
        if let myName = redPacketExtraData["myName"] {
            return fetchRawData(raw: myName) as? String
        } else {
            return nil
        }
    }

    var redPacketMyWalletAddress: String? {
        if let myWalletAddress = redPacketExtraData["myWalletAddress"] {
            return fetchRawData(raw: myWalletAddress) as? String
        } else {
            return nil
        }
    }

    var redPacketMyImageUrl: String? {
        if let myImageUrl = redPacketExtraData["myImageUrl"] {
            return fetchRawData(raw: myImageUrl) as? String
        } else {
            return nil
        }
    }

    var redPacketChannelUsers: String? {
        if let channelUsers = redPacketExtraData["channelUsers"] {
            return fetchRawData(raw: channelUsers) as? String
        } else {
            return nil
        }
    }

    var redPacketAmount: String? {
        if let amount = redPacketExtraData["amount"] {
            return fetchRawData(raw: amount) as? String
        } else {
            return nil
        }
    }

    var redPacketChannelId: String? {
        if let channelId = redPacketExtraData["channelId"] {
            return fetchRawData(raw: channelId) as? String
        } else {
            return nil
        }
    }

    var redPacketParticipantsCount: String? {
        if let participantsCount = redPacketExtraData["participantsCount"] {
            return fetchRawData(raw: participantsCount) as? String
        } else {
            return nil
        }
    }

    var redPacketMinOne: String? {
        if let minOne = redPacketExtraData["minOne"] {
            return fetchRawData(raw: minOne) as? String
        } else {
            return nil
        }
    }

    var redPacketMaxOne: String? {
        if let maxOne = redPacketExtraData["maxOne"] {
            return fetchRawData(raw: maxOne) as? String
        } else {
            return nil
        }
    }

    var redPacketEndTime: String? {
        if let endTime = redPacketExtraData["endTime"] {
            return fetchRawData(raw: endTime) as? String
        } else {
            return nil
        }
    }

    var redPacketID: String? {
        if let packetId = redPacketExtraData["packetId"] {
            return fetchRawData(raw: packetId) as? String
        } else {
            return nil
        }
    }

    var redPacketAddress: String? {
        if let packetAddress = redPacketExtraData["packetAddress"] {
            return fetchRawData(raw: packetAddress) as? String
        } else {
            return nil
        }
    }
}

// MARK: Sticker
public extension Dictionary where Key == String, Value == RawJSON {
    var stickerUrl: String? {
        if let stickerUrl = self["stickerUrl"] {
            return fetchRawData(raw: stickerUrl) as? String
        } else {
            return nil
        }
    }

    var giphyUrl: String? {
        if let stickerUrl = self["giphyUrl"] {
            return fetchRawData(raw: stickerUrl) as? String
        } else {
            return nil
        }
    }
}

// MARK: - User detail
public extension Dictionary where Key == String, Value == RawJSON {
    var email: String? {
        if let email = self["email"] {
            return fetchRawData(raw: email) as? String
        } else {
            return nil
        }
    }

    var bio: String? {
        if let bio = self["bio"] {
            return fetchRawData(raw: bio) as? String
        } else {
            return nil
        }
    }

    var birthday: String? {
        if let birthday = self["birthday"] {
            return fetchRawData(raw: birthday) as? String
        } else {
            return nil
        }
    }

    var instagramId: String? {
        if let instagramId = self["instagramId"] {
            return fetchRawData(raw: instagramId) as? String
        } else {
            return nil
        }
    }

    var tiktokId: String? {
        if let tiktokId = self["tiktokId"] {
            return fetchRawData(raw: tiktokId) as? String
        } else {
            return nil
        }
    }

    var twitterId: String? {
        if let twitterId = self["twitterId"] {
            return fetchRawData(raw: twitterId) as? String
        } else {
            return nil
        }
    }

    var phoneNumber: String? {
        if let phoneNumber = self["phoneNumber"] {
            return fetchRawData(raw: phoneNumber) as? String
        } else {
            return nil
        }
    }

    var coverImage: String? {
        if let coverImage = self["coverImage"] {
            return fetchRawData(raw: coverImage) as? String
        } else {
            return nil
        }
    }
}

// MARK: - Gift PickUp Bubble
public extension Dictionary where Key == String, Value == RawJSON {
    private var giftExtraData: [String: RawJSON] {
        if let extraData = self["gift"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return [:]
            }
        } else {
            return [:]
        }
    }

    var giftTitle: String? {
        if let title = giftExtraData["title"] {
            return fetchRawData(raw: title) as? String
        } else {
            return nil
        }
    }

    var giftMyName: String? {
        if let myName = giftExtraData["myName"] {
            return fetchRawData(raw: myName) as? String
        } else {
            return nil
        }
    }

    var giftMyWalletAddress: String? {
        if let myWalletAddress = giftExtraData["myWalletAddress"] {
            return fetchRawData(raw: myWalletAddress) as? String
        } else {
            return nil
        }
    }

    var giftChannelUsers: String? {
        if let channelUsers = giftExtraData["channelUsers"] {
            return fetchRawData(raw: channelUsers) as? String
        } else {
            return nil
        }
    }

    var giftAmount: String? {
        if let amount = giftExtraData["total_amount"] {
            return fetchRawData(raw: amount) as? String
        } else {
            return nil
        }
    }

    var giftChannelId: String? {
        if let channelId = giftExtraData["channelId"] {
            return fetchRawData(raw: channelId) as? String
        } else {
            return nil
        }
    }

    var giftEndTime: String? {
        if let endTime = giftExtraData["endTime"] {
            return fetchRawData(raw: endTime) as? String
        } else {
            return nil
        }
    }

    var giftID: String? {
        if let packetId = giftExtraData["id"] {
            return fetchRawData(raw: packetId) as? String
        } else {
            return nil
        }
    }

    var giftAddress: String? {
        if let packetAddress = giftExtraData["packetAddress"] {
            return fetchRawData(raw: packetAddress) as? String
        } else {
            return nil
        }
    }

    var flair: String? {
        if let flair = giftExtraData["flair"] {
            return fetchRawData(raw: flair) as? String
        } else {
            return nil
        }
    }

    var tokenAddress: String? {
        if let symbol = giftExtraData["token_address"] {
            return fetchRawData(raw: symbol) as? String
        } else {
            return nil
        }
    }

    var claimedAt: String? {
        if let claimedAt = self["claimed_at"] {
            return fetchRawData(raw: claimedAt) as? String
        } else {
            return nil
        }
    }
}

public func fetchRawData(raw: RawJSON) -> Any? {
    switch raw {
    case .number(let double):
        return double
    case .string(let string):
        return string
    case .bool(let bool):
        return bool
    case .dictionary(let dictionary):
        return dictionary
    case .array(let array):
        return array
    case .nil:
        return nil
    @unknown default:
        return nil
    }
}
