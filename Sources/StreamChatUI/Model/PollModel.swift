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
    public var imageURLStr: String?
    public var optionList: [String] = [""]
    public var anonymousPolling = true
    public var multipleAnswers = true
    public var hideTallyUntilVote = true
    public var isSended = false

    public init() {}

    public func toDictionary() -> [String: RawJSON] {
        var dictOut = [String: RawJSON]()
        dictOut["question"] = .string(question ?? "")
        dictOut["imageURLStr"] = .string(imageURLStr ?? "")
        dictOut["optionList"] = .string(optionList.joined(separator: "-"))
        dictOut["anonymousPolling"] = .string(anonymousPolling ? "1" : "0")
        dictOut["multipleAnswers"] = .string(multipleAnswers ? "1" : "0")
        dictOut["hideTallyUntilVote"] = .string(hideTallyUntilVote ? "1" : "0")
        dictOut["isSended"] = .string(isSended ? "1" : "0")

        return dictOut
    }
}
