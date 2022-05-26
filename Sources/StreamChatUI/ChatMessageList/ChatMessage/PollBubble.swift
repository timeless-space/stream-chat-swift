//
//  PollBubble.swift
//  StreamChatUI
//
//  Created by Phu Tran on 11/05/2022.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public class PollBubble: UITableViewCell {
    // MARK: - Input Properties
    var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var channel: ChatChannel?

    // MARK: - Properties
    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var timestampLabel: UILabel!
    private var leadingAnchorForSender: NSLayoutConstraint?
    private var leadingAnchorForReceiver: NSLayoutConstraint?
    private var trailingAnchorForSender: NSLayoutConstraint?
    private var trailingAnchorForReceiver: NSLayoutConstraint?
    private var pollID = ""
    private let chatClient = ChatClient.shared
    private lazy var dateFormatter: DateFormatter = .makeDefault()

    // MARK: - Computed Variables
    private var cellWidth: CGFloat {
        UIScreen.main.bounds.width * 0.3
    }

    // MARK: - Callback Functions
    public static var callback: ((String) -> [String: Any]?)?
    public static var clearCache: (() -> Void)?
    public static var getWalletImageURL: ((String) -> String)?

    // MARK: - Methods
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview == nil {
            PollBubble.clearCache?()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setLayout() {
        selectionStyle = .none
        backgroundColor = .clear

        // MARK: - Set viewContainer
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.MessageTopPadding)
        ])

        // MARK: - Set subContainer
        subContainer = UIView()
        subContainer.translatesAutoresizingMaskIntoConstraints = false
        subContainer.backgroundColor = .clear
        subContainer.clipsToBounds = true
        viewContainer.addSubview(subContainer)
        subContainer.transform = .mirrorY
        NSLayoutConstraint.activate([
            subContainer.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor, constant: 0),
            subContainer.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            subContainer.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
        ])

        // MARK: - Set timestampLabel
        timestampLabel = createTimestampLabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(timestampLabel)
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
            timestampLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
        timestampLabel.transform = .mirrorY

        // MARK: - Set Anchor
        leadingAnchorForSender = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor,
                                                                        constant: cellWidth)
        trailingAnchorForSender = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor,
                                                                          constant: -8)
        leadingAnchorForReceiver = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor,
                                                                          constant: 8)
        trailingAnchorForReceiver = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor,
                                                                            constant: -cellWidth)
    }

    private func setBubbleConstraints(_ isSender: Bool) {
        leadingAnchorForSender?.isActive = isSender
        leadingAnchorForSender?.constant = cellWidth
        trailingAnchorForSender?.isActive = isSender
        trailingAnchorForSender?.constant = -8
        leadingAnchorForReceiver?.isActive = !isSender
        leadingAnchorForReceiver?.constant = 8
        trailingAnchorForReceiver?.isActive = !isSender
        trailingAnchorForReceiver?.constant = -cellWidth
    }

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            timestampLabel.textAlignment = .left
            timestampLabel!.textColor = Appearance.default.colorPalette.subtitleText
            timestampLabel!.font = Appearance.default.fonts.footnote
        }
        return timestampLabel!
    }

    func configData(isSender: Bool) {
        setBubbleConstraints(isSender)
        guard let cid = channel?.cid else {
            return
        }
        if #available(iOS 15.0, *) {
            var isPreview = false
            if let pollData = self.getExtraData(key: "poll"),
               let questionRaw = pollData["question"],
               let imageUrlRaw = pollData["image_url"],
               let multipleChoicesRaw = pollData["multiple_choices"],
               let hideTallyRaw = pollData["hide_tally"],
               let answersRaw = pollData["answers"] {
                let question = fetchRawData(raw: questionRaw) as? String ?? ""
                let imageUrl = fetchRawData(raw: imageUrlRaw) as? String ?? ""
                let answersArrayJSON = fetchRawData(raw: answersRaw) as? [RawJSON] ?? []
                var answersArrayDict: [[String: RawJSON]] = []
                var answers: [PollBubbleView.AnswerRes] = []
                answersArrayJSON.forEach { itemRaw in
                    let item = fetchRawData(raw: itemRaw) as? [String: RawJSON] ?? [:]
                    answersArrayDict.append(item)
                }
                answersArrayDict.forEach { item in
                    if let id = item["id"],
                       let content = item["content"],
                       let pollID = item["poll_id"],
                       let votedCount = item["voted_count"],
                       let createdAt = item["created_at"] {
                        var wallets: [PollBubbleView.AnswerWallet] = []
                        if let walletsRaw = item["wallets"] {
                            let walletsArrayJSON = fetchRawData(raw: walletsRaw) as? [RawJSON] ?? []
                            if !walletsArrayJSON.isEmpty {
                                var walletsArrayDict: [[String: RawJSON]] = []
                                walletsArrayJSON.forEach { itemRaw in
                                    let item = fetchRawData(raw: itemRaw) as? [String: RawJSON] ?? [:]
                                    walletsArrayDict.append(item)
                                }
                                walletsArrayDict.forEach { item in
                                    if let titleRaw = item["title"], let avatarRaw = item["avatar"],
                                       let bioRaw = item["bio"], let idRaw = item["id"],
                                       let addressRaw = item["address"], let verifiedRaw = item["verified"] {
                                        wallets.append(PollBubbleView.AnswerWallet(
                                            title: fetchRawData(raw: titleRaw) as? String ?? "",
                                            avatar: fetchRawData(raw: avatarRaw) as? String ?? "",
                                            bio: fetchRawData(raw: bioRaw) as? String ?? "",
                                            id: fetchRawData(raw: idRaw) as? String ?? "",
                                            address: fetchRawData(raw: addressRaw) as? String ?? "",
                                            verified: fetchRawData(raw: verifiedRaw) as? Bool ?? false)
                                        )
                                    }
                                }
                            }
                        }
                        answers.append(PollBubbleView.AnswerRes(
                            id: fetchRawData(raw: id) as? String ?? "",
                            content: fetchRawData(raw: content) as? String ?? "",
                            pollID: fetchRawData(raw: pollID) as? String ?? "",
                            votedCount: fetchRawData(raw: votedCount) as? Int ?? 0,
                            wallets: wallets,
                            createdAt: fetchRawData(raw: createdAt) as? String ?? ""
                        ))
                    } else if let content = item["content"] {
                        isPreview = self.content?.type == .ephemeral
                        answers.append(PollBubbleView.AnswerRes(
                            id: "",
                            content: fetchRawData(raw: content) as? String ?? "",
                            pollID: "",
                            votedCount: 0,
                            wallets: [],
                            createdAt: ""
                        ))
                    }
                }
                if !answers.isEmpty {
                    pollID = answers[0].pollID
                }
                var pollVotedCount: Double = 0
                if let pollVotedCountRaw = pollData["poll_voted_count"] {
                    pollVotedCount = fetchRawData(raw: pollVotedCountRaw) as? Double ?? 0
                }
                var orderedWallets: [PollBubbleView.OrderedWallet] = []
                var orderedArrayJSON: [RawJSON] = []
                if let orderedWalletRaw = pollData["ordered_wallets"] {
                    let orderedWalletArrayJSON = fetchRawData(raw: orderedWalletRaw) as? [RawJSON] ?? []
                    var orderedWalletArrayDict: [[String: RawJSON]] = []
                    orderedWalletArrayJSON.forEach { itemRaw in
                        let item = fetchRawData(raw: itemRaw) as? [String: RawJSON] ?? [:]
                        orderedWalletArrayDict.append(item)
                    }
                    orderedWalletArrayDict.forEach { item in
                        if let walletAddress = item["wallet_address"], let createdAt = item["created_at"] {
                            orderedWallets.append(PollBubbleView.OrderedWallet(
                                walletAddress: fetchRawData(raw: walletAddress) as? String ?? "",
                                createdAt: fetchRawData(raw: createdAt) as? String ?? ""
                            ))
                        }
                    }
                }
                let controller = chatClient.currentUserController()
                var showYourFirstPoll = false
                if !isPreview, isSender {
                    if let firstPollMessageIDRaw = controller.currentUser?.extraData["firstPollMessageID"] {
                        if let messageId = self.content?.id {
                            let firstPollMessageID = fetchRawData(raw: firstPollMessageIDRaw) as? String ?? ""
                            showYourFirstPoll = firstPollMessageID == messageId
                        }
                    } else {
                        showYourFirstPoll = true
                    }
                }
                subContainer.subviews.forEach { $0.removeFromSuperview() }
                subContainer.fit(subview: PollBubbleView(
                    cid: cid,
                    question: question,
                    imageUrl: imageUrl,
                    multipleChoices: fetchRawData(raw: multipleChoicesRaw) as? Bool ?? false,
                    hideTally: fetchRawData(raw: hideTallyRaw) as? Bool ?? false,
                    answers: answers,
                    pollVotedCount: pollVotedCount,
                    orderedWallets: orderedWallets,
                    pollID: pollID,
                    isSender: isSender,
                    isPreview: isPreview,
                    showYourFirstPoll: showYourFirstPoll,
                    callBackSend: { self.callBackSend(cid: cid) },
                    callBackEdit: { self.callBackEdit() },
                    callBackCancel: { self.callBackCancel() },
                    callBackSubmit: { listAnswerID in self.callBackSubmit(listAnswerID) },
                    callBackViewResults: { answersRes, pollVotedCountRes in
                        self.onTapViewResult(
                            question: question,
                            mediaUrl: imageUrl,
                            answerList: answersRes,
                            pollVotedCount: pollVotedCountRes
                        )
                    }
                ))
                timestampLabel.textAlignment = isSender ? .right : .left
                var nameAndTimeString = ""
                if let options = layoutOptions {
                    if options.contains(.authorName), let name = content?.author.name {
                        nameAndTimeString.append("\(name)   ")
                    }
                    if let createdAt = content?.createdAt {
                        if options.contains(.timestamp) {
                            if isSender && isPreview {
                                nameAndTimeString.append("  Only visible to you \(dateFormatter.string(from: createdAt))")
                            } else {
                                nameAndTimeString.append("\(dateFormatter.string(from: createdAt))")
                            }
                        } else if options.contains(.onlyVisibleForYouIndicator), isSender && isPreview {
                            nameAndTimeString.append("  Only visible to you \(dateFormatter.string(from: createdAt))")
                        }
                    }
                }
                timestampLabel?.text = nameAndTimeString
                if nameAndTimeString.contains("Only visible to you") {
                    timestampLabel?.addImage(systemName: "eye.fill")
                }
            }
        }
    }

    private func getExtraData(key: String) -> [String: RawJSON]? {
        let extra = content?.extraData
        if let extraData = content?.extraData[key] {
            switch extraData {
            case .dictionary(let dictionary): return dictionary
            default: return nil
            }
        } else {
            return nil
        }
    }

    private func callBackSend(cid: ChannelId) {
        guard let messageId = content?.id else { return }
        let action = AttachmentAction(name: "action",
                                      value: "submit",
                                      style: .primary,
                                      type: .button,
                                      text: "Send")
        chatClient.messageController(cid: cid, messageId: messageId)
            .dispatchEphemeralMessageAction(action, completion: { error in
                if error == nil {
                    var userInfo = [String: Any]()
                    userInfo["firstPollMessageID"] = messageId
                    NotificationCenter.default.post(name: .pollSended, object: nil, userInfo: userInfo)
                }
            })
    }

    private func callBackEdit() {
        guard let cid = channel?.cid, let messageId = content?.id else {
            return
        }
        let editData = self.getExtraData(key: "poll")
        var userInfo = [String: Any]()
        userInfo["channelId"] = cid
        userInfo["editData"] = editData
        userInfo["message_id"] = messageId
        NotificationCenter.default.post(name: .editPoll, object: nil, userInfo: userInfo)
    }

    private func callBackCancel() {
        guard let messageId = content?.id, let cid = channel?.cid else {
            return
        }
        let action = AttachmentAction(name: "action",
                                      value: "cancel",
                                      style: .default,
                                      type: .button,
                                      text: "Cancel")
        chatClient.messageController(cid: cid, messageId: messageId).dispatchEphemeralMessageAction(action)
    }

    private func callBackSubmit(_ listAnswerID: [String]) {
        guard let cid = channel?.cid else {
            return
        }
        var userInfo = [String: Any]()
        userInfo["lst_answer_id"] = listAnswerID
        userInfo["poll_id"] = pollID
        userInfo["group_id"] = cid.description
        NotificationCenter.default.post(name: .submitVote, object: nil, userInfo: userInfo)
    }

    @available(iOS 15.0, *)
    private func onTapViewResult(
        question: String,
        mediaUrl: String,
        answerList: [PollBubbleView.AnswerRes],
        pollVotedCount: Double
    ) {
        var userInfo = [String: Any]()
        userInfo["question"] = question
        userInfo["mediaUrl"] = mediaUrl
        var answers: [[String: Any]] = []
        answerList.forEach { item in
            var answer: [String: Any] = [:]
            answer["id"] = item.id
            answer["content"] = item.content
            answer["poll_id"] = item.pollID
            answer["voted_count"] = item.votedCount
            var wallets: [[String: Any]] = []
            item.wallets.forEach { itemWallet in
                var wallet: [String: Any] = [:]
                wallet["title"] = itemWallet.title
                wallet["avatar"] = itemWallet.avatar
                wallet["bio"] = itemWallet.bio
                wallet["id"] = itemWallet.id
                wallet["address"] = itemWallet.address
                wallet["verified"] = itemWallet.verified
                wallets.append(wallet)
            }
            answer["wallets"] = wallets
            answer["created_at"] = item.createdAt
            answers.append(answer)
        }
        userInfo["answers"] = answers
        userInfo["poll_voted_count"] = pollVotedCount
        NotificationCenter.default.post(name: .viewPollResult, object: nil, userInfo: userInfo)
    }
}
