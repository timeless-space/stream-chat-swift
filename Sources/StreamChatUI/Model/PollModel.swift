//
//  PollModel.swift
//  Timeless-wallet
//
//  Created by Phu Tran on 11/05/2022.
//

import Foundation
import StreamChat

public struct PollModel {
    // MARK: - Variables
    public var question: String?
    public var imageURL: String?
    public var anonymous = false
    public var multipleChoices = false
    public var hideTally = false
    public var groupID: String?
    public var answers: [String] = [""]

    public init() {}

    public func toDictionary() -> [String: RawJSON] {
        var dictOut = [String: RawJSON]()
        dictOut["question"] = .string(question ?? "")
        dictOut["image_url"] = .string(imageURL ?? "")
        dictOut["anonymous"] = .bool(anonymous)
        dictOut["multiple_choices"] = .bool(multipleChoices)
        dictOut["hide_tally"] = .bool(hideTally)
        dictOut["group_id"] = .string(groupID ?? "")

        var answersRaw: [RawJSON] = []
        answersRaw = answers.map({
            var answer: [String: RawJSON] = [:]
            answer["content"] = .string($0 ?? "")
            return .dictionary(answer)
        })
        dictOut["answers"] = .array(answersRaw)

        return dictOut
    }
}
