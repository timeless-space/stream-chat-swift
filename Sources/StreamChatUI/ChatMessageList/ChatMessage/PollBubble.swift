//
//  PollBubble.swift
//  StreamChatUI
//
//  Created by Phu Tran on 11/05/2022.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import SwiftUI
import StreamChat

class PollBubble: UITableViewCell {
    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var timestampLabel: UILabel!
    private var leadingAnchorForSender: NSLayoutConstraint?
    private var leadingAnchorForReceiver: NSLayoutConstraint?
    private var trailingAnchorForSender: NSLayoutConstraint?
    private var trailingAnchorForReceiver: NSLayoutConstraint?
    var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var memberImageURL: [String] = []
    var channel: ChatChannel?
    var pollID = ""

    public lazy var dateFormatter: DateFormatter = .makeDefault()

    var isSender = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }

    private func setLayout() {
        selectionStyle = .none
        backgroundColor = .clear
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.MessageTopPadding)
        ])

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

        leadingAnchorForSender = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: cellWidth)
        trailingAnchorForSender = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8)
        leadingAnchorForReceiver = viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8)
        trailingAnchorForReceiver = viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -cellWidth)
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
//        viewContainer.isHidden = !isSender
        setBubbleConstraints(isSender)
        guard let cid = channel?.cid else {
            return
        }
        if #available(iOS 13.0, *) {
            if let pollData = self.getExtraData(key: "poll"),
               let questionRaw = pollData["question"], let imageUrlRaw = pollData["image_url"],
               let anonymousRaw = pollData["anonymous"], let multipleChoicesRaw = pollData["multiple_choices"],
               let hideTallyRaw = pollData["hide_tally"], let answersRaw = pollData["answers"] {
//               let isSendedRaw = pollData["isSended"] {
                let question = fetchRawData(raw: questionRaw) as? String ?? ""
                let imageUrl = fetchRawData(raw: imageUrlRaw) as? String ?? ""
                let anonymous = fetchRawData(raw: anonymousRaw) as? Bool ?? true
                let multipleChoices = fetchRawData(raw: multipleChoicesRaw) as? Bool ?? true
                let hideTally = fetchRawData(raw: hideTallyRaw) as? Bool ?? true
                let answersArrayJSON = fetchRawData(raw: answersRaw) as? [RawJSON] ?? []
                var answersArrayDict: [[String: RawJSON]] = []
                var answers: [AnswerRes] = []
                answersArrayJSON.forEach { itemRaw in
                    let item = fetchRawData(raw: itemRaw) as? [String: RawJSON] ?? [:]
                    answersArrayDict.append(item)
                }
                answersArrayDict.forEach { item in
                    if let id = item["id"], let content = item["content"], let pollID = item["poll_id"],
                        let votedCount = item["voted_count"], let createdAt = item["created_at"] {
                        var wallets: [AnswerWallet] = []
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
                                        wallets.append(AnswerWallet(
                                            title: fetchRawData(raw: titleRaw) as? String ?? "",
                                            avatar: fetchRawData(raw: avatarRaw) as? String ?? "",
                                            bio: fetchRawData(raw: bioRaw) as? String ?? "",
                                            id: fetchRawData(raw: idRaw) as? String ?? "",
                                            address: fetchRawData(raw: addressRaw) as? String ?? "",
                                            verifies: fetchRawData(raw: verifiedRaw) as? Bool ?? false)
                                        )
                                    }
                                }
                            }
                        }
                        answers.append(AnswerRes(
                            id: fetchRawData(raw: id) as? String ?? "",
                            content: fetchRawData(raw: content) as? String ?? "",
                            pollID: fetchRawData(raw: pollID) as? String ?? "",
                            votedCount: fetchRawData(raw: votedCount) as? Int ?? 0,
                            wallets: wallets,
                            createdAt: fetchRawData(raw: createdAt) as? String ?? ""
                        ))
                    }
                }
                if !answers.isEmpty {
                    pollID = answers[0].pollID
                }

//                let optionListStr = fetchRawData(raw: optionListRaw) as? String ?? ""
//                let optionList = optionListStr.components(separatedBy: "-")
//                let isSended = (fetchRawData(raw: isSendedRaw) as? String ?? "1") == "1" ? true : false
                subContainer.fit(subview: PollView(
                    cid: cid,
                    memberImageURL: memberImageURL,
                    question: question,
                    imageUrl: imageUrl,
                    multipleChoices: true, // multipleChoices,
                    hideTally: hideTally,
                    answers: answers,
//                    isSended: isSended,
                    onTapSend: {
                        self.onTapSend(
                            question: question,
                            imageUrl: "", // imageUrl,
                            optionList: ["abc"], // optionList,
                            anonymousPolling: false, // anonymousPolling,
                            multipleChoices: true, // multipleChoices,
                            hideTally: false // hideTally
                        )
                    },
                    onTapEdit: {
                        self.onTapEdit()
                    },
                    onTapCancel: {
                        self.onTapCancel()
                    },
                    onTapSubmit: { listAnswerID in
                        self.onTapSubmit(listAnswerID)
                    }
                ))
                timestampLabel.textAlignment = isSender ? .right : .left
                var nameAndTimeString: String? = ""
                if let options = layoutOptions {
                    if options.contains(.authorName), let name = content?.author.name {
                        nameAndTimeString?.append("\(name)   ")
                    }
                    if options.contains(.timestamp) , let createdAt = content?.createdAt {
                        nameAndTimeString?.append("\(dateFormatter.string(from: createdAt))")
                    }
                }
                timestampLabel?.text = nameAndTimeString // "\(isSended ? "" : "Only visible to you ")\(nameAndTimeString ?? "")"
            }
        }
    }

    private func getExtraData(key: String) -> [String: RawJSON]? {
        let extra = content?.extraData
        if let extraData = content?.extraData[key] {
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

    private func onTapSend(
        question: String,
        imageUrl: String,
        optionList: [String],
        anonymousPolling: Bool,
        multipleChoices: Bool,
        hideTally: Bool
    ) {
        guard let cid = channel?.cid else {
            return
        }
        var userInfo = [String: Any]()
        userInfo["channelId"] = cid
        userInfo["question"] = question
        userInfo["imageUrl"] = imageUrl
        userInfo["anonymous"] = anonymousPolling
        userInfo["multipleChoices"] = multipleChoices
        userInfo["hideTally"] = hideTally
        userInfo["groupID"] = cid.description
        var answers: [[String: String]] = []
        optionList.forEach { item in
            answers.append(["content": item])
        }
        userInfo["answers"] = answers
        NotificationCenter.default.post(name: .sendPoll, object: nil, userInfo: userInfo)
    }

    private func onTapEdit() {
        guard let cid = channel?.cid else {
            return
        }
        let editData = self.getExtraData(key: "pollPreview")
        var userInfo = [String: Any]()
        userInfo["channelId"] = cid.description
        userInfo["editData"] = editData
        NotificationCenter.default.post(name: .editPoll, object: nil, userInfo: userInfo)
    }

    private func onTapCancel() {
        contentView.removeFromSuperview()
    }

    private func onTapSubmit(_ listAnswerID: [String]) {
        guard let cid = channel?.cid else {
            return
        }
        var userInfo = [String: Any]()
        userInfo["lst_answer_id"] = listAnswerID
        userInfo["poll_id"] = pollID
        userInfo["group_id"] = cid.description
        NotificationCenter.default.post(name: .submitVote, object: nil, userInfo: userInfo)
    }
}

struct AnswerRes {
    var id = ""
    var content = ""
    var pollID = ""
    var votedCount = 0
    var wallets: [AnswerWallet] = []
    var createdAt = ""
}

struct AnswerWallet {
    var title = ""
    var avatar = ""
    var bio = ""
    var id = ""
    var address = ""
    var verifies = false
}

@available(iOS 13.0.0, *)
struct PollView: View {
    // MARK: - Input Paramters
    var cid: ChannelId
    var memberImageURL: [String]
    var question = ""
    var imageUrl = ""
    var multipleChoices = true
    var hideTally = true
    var answers: [AnswerRes] = []
    var isSended = false

    // MARK: - Properties
    @State private var selectedAnswerID = ""
    @State private var selectedMultiAnswerID: [String] = []

    // MARK: - Callback functions
    var onTapSend: () -> Void
    var onTapEdit: () -> Void
    var onTapCancel: () -> Void
    var onTapSubmit: ([String]) -> Void

    // MARK: Computed Variables
    private var votedCount: Int {
        var result = 0
        answers.forEach { item in
            result += item.votedCount
        }
        return result
    }

    private var enableSubmitButton: Bool {
        if multipleChoices {
            return !selectedMultiAnswerID.isEmpty
        } else {
            return !selectedAnswerID.isEmpty
        }
    }

    // MARK: - Body view
    var body: some View {
//        VStack(alignment: .trailing, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                if #available(iOS 15.0, *), let imageURL = URL(string: imageUrl) {
                    Rectangle()
                        .foregroundColor(Color.black) // TODO
                        .frame(width: UIScreen.main.bounds.width * 243 / 375,
                               height: UIScreen.main.bounds.width * 243 / 375)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("YOUR FIRST POLL")
                        .tracking(-0.4)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.bottom, 2.5)
                    Text(question)
                        .tracking(-0.2)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white)
                        .padding(.bottom, 4.5)
                        .padding(.leading, 1)
                    HStack(spacing: 3) {
                        Text("\(votedCount) \(votedCount > 1 ? "Votes" : "Vote")")
                            .tracking(-0.4)
                            .font(.system(size: 10))
                            .foregroundColor(Color.white)
                            .padding(.leading, 1)
//                        ForEach(0 ..< (memberImageURL.count <= 5 ? memberImageURL.count : 5)) { idx in
//                            memberAvatar(memberImageURL[idx])
//                        }
                    }
                    .padding(.bottom, 14.5)
                    VStack(alignment: .leading, spacing: 17) {
                        ForEach(0 ..< answers.count) { idx in
                            PollSelectLine(item: answers[idx],
                                           idx: idx,
                                           multipleChoices: multipleChoices,
                                           selectedAnswerID: $selectedAnswerID,
                                           selectedMultiAnswerID: $selectedMultiAnswerID)
                        }
                    }
                    .padding(.bottom, 17)
                    Button(action: {
                        if multipleChoices {
                            onTapSubmit(selectedMultiAnswerID)
                        } else {
                            onTapSubmit([selectedAnswerID])
                        }
                    }) {
                        RoundedRectangle(cornerRadius: .infinity)
                            .foregroundColor(enableSubmitButton ? Color.white.opacity(0.2) : Color.black.opacity(0.25))
                            .frame(width: UIScreen.main.bounds.width * 184 / 375, height: 29)
                            .overlay(
                                Text("Submit Vote")
                                    .tracking(-0.3)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white.opacity(enableSubmitButton ? 1 : 0.5))
                                    .offset(y: 0.5)
                            )
                            .padding(.horizontal, 16.5)
                            .animation(.easeInOut(duration: 0.2), value: enableSubmitButton)
                    }
                    .padding(.bottom, 4.5)
                }
                .padding(.vertical, 8.5)
                .padding(.horizontal, 12.5)
            }
            .frame(minWidth: UIScreen.main.bounds.width * 243 / 375, alignment: .leading)
            .background(Color.blue)
            .cornerRadius(15)
//            .disabled(!isSended)
//            if !isSended {
//                HStack(spacing: 33) {
//                    Spacer(minLength: 0)
//                    Button(action: {
//                        onTapSend()
//                    }) {
//                        Text("Send")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(Color.blue)
//                    }
//                    Button(action: { onTapEdit() }) {
//                        Text("Edit")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(Color.white.opacity(0.4))
//                    }
//                    Button(action: { onTapCancel() }) {
//                        Text("Cancel")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(Color.white.opacity(0.4))
//                    }
//                }
//            }
//        }
    }

    // MARK: - Subview
    private func memberAvatar(_ avatarURL: String) -> some View {
        ZStack {
            if #available(iOS 15.0, *) {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.black
                }
                .frame(width: 16.5, height: 16.5)
                .cornerRadius(.infinity)
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct PollSelectLine: View {
    // MARK: - Input Parameter
    var item: AnswerRes
    var idx: Int
    var multipleChoices = true
    @Binding var selectedAnswerID: String
    @Binding var selectedMultiAnswerID: [String]

    var body: some View {
        Button(action: {
            if multipleChoices {
                if !selectedMultiAnswerID.contains(item.id) {
                    selectedMultiAnswerID.append(item.id)
                } else {
                    selectedMultiAnswerID.removeAll(where: { $0 == item.id })
                }
            } else {
                if selectedAnswerID != item.id {
                    selectedAnswerID = item.id
                } else {
                    selectedAnswerID.removeAll()
                }
            }
        }) {
            HStack(alignment: .top, spacing: 6) {
                if multipleChoices {
                    Image(systemName: selectedMultiAnswerID.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(width: 15, height: 15)
                } else {
                    Image(systemName: selectedAnswerID == item.id ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(width: 15, height: 15)
                }
                Text(item.content)
                    .tracking(-0.3)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white)
            }
            .padding(.leading, 1)
        }
    }
}
