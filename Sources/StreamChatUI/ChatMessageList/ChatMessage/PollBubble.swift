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
import Nuke

public class PollBubble: UITableViewCell {
    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var timestampLabel: UILabel!
    private var leadingAnchorForSender: NSLayoutConstraint?
    private var leadingAnchorForReceiver: NSLayoutConstraint?
    private var trailingAnchorForSender: NSLayoutConstraint?
    private var trailingAnchorForReceiver: NSLayoutConstraint?
    var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var channel: ChatChannel?
    var pollID = ""
    let chatClient = ChatClient.shared
    public static var callback: ((String) -> [String: Any]?)?
    public static var clearCache: (() -> Void)?

    public lazy var dateFormatter: DateFormatter = .makeDefault()

    var isSender = false

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
        setBubbleConstraints(isSender)
        guard let cid = channel?.cid else {
            return
        }
        if #available(iOS 13.0, *) {
            var isPreview = false
            if let pollData = self.getExtraData(key: "poll"),
               let questionRaw = pollData["question"], let imageUrlRaw = pollData["image_url"],
               let anonymousRaw = pollData["anonymous"], let multipleChoicesRaw = pollData["multiple_choices"],
               let hideTallyRaw = pollData["hide_tally"], let answersRaw = pollData["answers"] {
                let question = fetchRawData(raw: questionRaw) as? String ?? ""
                let imageUrl = fetchRawData(raw: imageUrlRaw) as? String ?? ""
                let anonymous = fetchRawData(raw: anonymousRaw) as? Bool ?? false
                let multipleChoices = fetchRawData(raw: multipleChoicesRaw) as? Bool ?? false
                let hideTally = fetchRawData(raw: hideTallyRaw) as? Bool ?? false
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
                                            verified: fetchRawData(raw: verifiedRaw) as? Bool ?? false)
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
                    } else if let content = item["content"] {
                        isPreview = self.content?.type == .ephemeral
                        answers.append(AnswerRes(
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
                subContainer.subviews.forEach {
                    $0.removeFromSuperview()
                }
                subContainer.fit(subview: PollView(
                    cid: cid,
                    question: question,
                    imageUrl: imageUrl,
                    multipleChoices: multipleChoices,
                    hideTally: hideTally,
                    answers: answers,
                    pollID: pollID,
                    isSender: isSender,
                    isPreview: isPreview,
                    onTapSend: {
                        guard let messageId = self.content?.id else { return }
                        let action = AttachmentAction(name: "action",
                                                      value: "submit",
                                                      style: .primary,
                                                      type: .button,
                                                      text: "Send")
                        self.chatClient.messageController(cid: cid,
                                                            messageId: messageId)
                            .dispatchEphemeralMessageAction(action)
                    },
                    onTapEdit: { self.onTapEdit() },
                    onTapCancel: { self.onTapCancel() },
                    onTapSubmit: { listAnswerID in self.onTapSubmit(listAnswerID) },
                    onTapViewResult: { answersRes in
                        self.onTapViewResult(
                            question: question,
                            mediaUrl: imageUrl,
                            answerList: answersRes
                        )
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
                timestampLabel?.text = nameAndTimeString
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
//        guard let cid = channel?.cid else {
//            return
//        }
//        var userInfo = [String: Any]()
//        userInfo["channelId"] = cid
//        userInfo["question"] = question
//        userInfo["imageUrl"] = imageUrl
//        userInfo["anonymous"] = anonymousPolling
//        userInfo["multipleChoices"] = multipleChoices
//        userInfo["hideTally"] = hideTally
//        userInfo["groupID"] = cid.description
//        var answers: [[String: String]] = []
//        optionList.forEach { item in
//            answers.append(["content": item])
//        }
//        userInfo["answers"] = answers
//        NotificationCenter.default.post(name: .sendPoll, object: nil, userInfo: userInfo)
    }

    private func onTapEdit() {
        guard let cid = channel?.cid,
        let messageId = content?.id else {
            return
        }
        let editData = self.getExtraData(key: "poll")
        var userInfo = [String: Any]()
        userInfo["channelId"] = cid
        userInfo["editData"] = editData
        userInfo["messageId"] = messageId
        NotificationCenter.default.post(name: .editPoll, object: nil, userInfo: userInfo)

//        guard let messageId = content?.id,
//              let cid = channel?.cid else { return }
//        let action = AttachmentAction(name: "action",
//                                      value: "edit",
//                                      style: .default,
//                                      type: .button,
//                                      text: "Edit")
//        chatClient.messageController(cid: cid,
//                                            messageId: messageId)
//            .dispatchEphemeralMessageAction(action)
    }

    private func onTapCancel() {
        guard let messageId = content?.id,
              let cid = channel?.cid else { return }
        let action = AttachmentAction(name: "action",
                                      value: "cancel",
                                      style: .default,
                                      type: .button,
                                      text: "Cancel")
        chatClient.messageController(cid: cid,
                                            messageId: messageId)
            .dispatchEphemeralMessageAction(action)
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

    private func onTapViewResult(
        question: String,
        mediaUrl: String,
        answerList: [AnswerRes]
    ) {
        var userInfo = [String: Any]()
        userInfo["question"] = question
        userInfo["mediaUrl"] = mediaUrl
        var answers: [[String: Any]] = []
        answerList.forEach { item in
            var answer: [String: Any] = [:]
            answer["id"] = item.id
            answer["content"] = item.content
            answer["pollID"] = item.pollID
            answer["votedCount"] = item.votedCount
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
            answer["createdAt"] = item.createdAt
            answers.append(answer)
        }
        userInfo["answers"] = answers
        NotificationCenter.default.post(name: .viewPollResult, object: nil, userInfo: userInfo)
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
    var verified = false
}

@available(iOS 13.0.0, *)
struct PollView: View {
    // MARK: - Input Paramters
    var cid: ChannelId
    var question = ""
    var imageUrl = ""
    var multipleChoices = false
    var hideTally = false
    @State var answers: [AnswerRes] = []
    var pollID = ""
    var isSender: Bool
    var isPreview = false

    // MARK: - Properties
    @State private var selectedAnswerID = ""
    @State private var selectedMultiAnswerID: [String] = []
    @State private var voted = false
    @State private var loadingSubmit = false
    @State private var isLoaded = false
    @State private var uiImageView = UIImageView()
    @State private var uploadedImage: UIImage?
    @State private var memberVotedURL: [String] = []
    @State private var mediaSize: CGSize?
    @State private var isGifMedia = false
    private let mediaWidth = UIScreen.main.bounds.width * 243 / 375

    // MARK: - Callback functions
    var onTapSend: () -> Void
    var onTapEdit: () -> Void
    var onTapCancel: () -> Void
    var onTapSubmit: ([String]) -> Void
    var onTapViewResult: ([AnswerRes]) -> Void

    // MARK: Computed Variables
    private var votedCount: Int {
        var result = 0
        answers.forEach { item in
            result += item.votedCount
        }
        return result
    }

    private var enableSubmitButton: Bool {
        if voted {
            return true
        } else {
            return multipleChoices ? !selectedMultiAnswerID.isEmpty : !selectedAnswerID.isEmpty
        }
    }

    // MARK: - Body view
    var body: some View {
        if #available(iOS 14.0, *) {
            VStack(alignment: .trailing, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    if !imageUrl.isEmpty {
                        mediaView(imageUrl)
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
                            .padding(.leading, 1)
                            .padding(.bottom, isPreview ? 10.5 : 4.5)
                        if !isPreview {
                            HStack(spacing: 3) {
                                Text("\(votedCount) \(votedCount > 1 ? "Votes" : "Vote")")
                                    .tracking(-0.4)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.white)
                                    .padding(.leading, 1)
                                    .overlay(
                                        ZStack {
                                            if memberVotedURL.count > 0 {
                                                ForEach(0 ..< (memberVotedURL.count <= 5 ? memberVotedURL.count : 5)) { idx in
                                                    ListMemberAvatar(avatarURL: memberVotedURL[0])
                                                        .zIndex(Double(-idx))
                                                        .offset(x: CGFloat(idx * 12 - idx))
                                                }
                                            }
                                        }
                                        .offset(x: 21), alignment: .trailing
                                    )
                            }
                            .padding(.bottom, 14.5)
                        }
                        VStack(alignment: .leading, spacing: 17) {
                            ForEach(0 ..< answers.count) { idx in
                                PollSelectLine(item: answers[idx],
                                               multipleChoices: multipleChoices,
                                               hideTally: hideTally,
                                               isPreview: isPreview,
                                               isSender: isSender,
                                               selectedAnswerID: $selectedAnswerID,
                                               selectedMultiAnswerID: $selectedMultiAnswerID,
                                               voted: $voted,
                                               answers: $answers)
                            }
                        }
                        .padding(.bottom, 17)
                        .disabled(voted || isPreview)
                        if !isPreview {
                            submitResultButton
                        }
                    }
                    .padding(.top, 8.5)
                    .padding(.bottom, isPreview ? 1 : 8.5)
                    .padding(.horizontal, 12.5)
                    .frame(minWidth: mediaWidth, alignment: .leading)
                    .background(isSender ? Color.blue : Color.gray.opacity(0.6))
                    .background(Color.black)
                }
                .cornerRadius(15)
                if isPreview {
                    previewButtons
                }
            }
            .onAppear {
                if let userInfo = PollBubble.callback?(pollID) {
                    loadingSubmit = false
                    isLoaded = true
                    let groupID = userInfo["groupID"] as? String ?? ""
                    let pollID = userInfo["pollID"] as? String ?? ""
                    if groupID == cid.description && pollID == self.pollID {
                        let question = userInfo["question"] as? String ?? ""
                        let imageURL = userInfo["imageURL"] as? String ?? ""
                        let anonymous = userInfo["anonymous"] as? Bool ?? false
                        let multipleChoices = userInfo["multipleChoices"] as? Bool ?? false
                        let hideTally = userInfo["hideTally"] as? Bool ?? false
                        let createdAt = userInfo["createdAt"] as? String ?? ""
                        let creator = userInfo["creator"] as? String ?? ""
                        let groupID = userInfo["groupID"] as? String ?? ""
                        let messageID = userInfo["messageID"] as? String ?? ""
                        let answers = userInfo["answers"] as? [[String: Any]] ?? []
                        let voteFor = userInfo["voteFor"] as? [String] ?? []

                        self.answers.removeAll()
                        answers.forEach { item in
                            var wallets: [AnswerWallet] = []
                            let walletItems = item["wallets"] as? [[String: Any]] ?? []
                            walletItems.forEach { wallet in
                                let title = wallet["title"] as? String ?? ""
                                let avatar = wallet["avatar"] as? String ?? ""
                                let bio = wallet["bio"] as? String ?? ""
                                let id = wallet["id"] as? String ?? ""
                                let address = wallet["address"] as? String ?? ""
                                let verified = wallet["verified"] as? Bool ?? false
                                wallets.append(AnswerWallet(
                                    title: wallet["title"] as? String ?? "",
                                    avatar: wallet["avatar"] as? String ?? "",
                                    bio: wallet["bio"] as? String ?? "",
                                    id: wallet["id"] as? String ?? "",
                                    address: wallet["address"] as? String ?? "",
                                    verified: wallet["verified"] as? Bool ?? false
                                ))
                            }
                            self.answers.append(AnswerRes(
                                id: item["id"] as? String ?? "",
                                content: item["content"] as? String ?? "",
                                pollID: pollID,
                                votedCount: item["votedCount"] as? Int ?? 0,
                                wallets: wallets,
                                createdAt: item["createdAt"] as? String ?? ""
                            ))
                        }
                        voted = userInfo["voted"] as? Bool ?? false
                    }
                } else {
                    var userInfo = [String: Any]()
                    userInfo["group_id"] = cid.description
                    userInfo["poll_id"] = pollID
                    NotificationCenter.default.post(name: .getPollData, object: nil, userInfo: userInfo)
                }
                memberVotedURL.removeAll()
                self.answers.forEach { item in
                    for wallet in item.wallets where !memberVotedURL.contains(wallet.avatar) {
                        memberVotedURL.append(wallet.avatar)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .pollUpdate)) { value in
                withAnimation(.easeInOut(duration: 0.2)) {
                    loadingSubmit = false
                }
                let groupID = value.userInfo?["groupID"] as? String ?? ""
                let pollID = value.userInfo?["pollID"] as? String ?? ""
                if groupID == cid.description && pollID == self.pollID {
                    let question = value.userInfo?["question"] as? String ?? ""
                    let imageURL = value.userInfo?["imageURL"] as? String ?? ""
                    let anonymous = value.userInfo?["anonymous"] as? Bool ?? false
                    let multipleChoices = value.userInfo?["multipleChoices"] as? Bool ?? false
                    let hideTally = value.userInfo?["hideTally"] as? Bool ?? false
                    let createdAt = value.userInfo?["createdAt"] as? String ?? ""
                    let creator = value.userInfo?["creator"] as? String ?? ""
                    let groupID = value.userInfo?["groupID"] as? String ?? ""
                    let messageID = value.userInfo?["messageID"] as? String ?? ""
                    let answers = value.userInfo?["answers"] as? [[String: Any]] ?? []
                    let voteFor = value.userInfo?["voteFor"] as? [String] ?? []

                    self.answers.removeAll()
                    answers.forEach { item in
                        var wallets: [AnswerWallet] = []
                        let walletItems = item["wallets"] as? [[String: Any]] ?? []
                        walletItems.forEach { wallet in
                            let title = wallet["title"] as? String ?? ""
                            let avatar = wallet["avatar"] as? String ?? ""
                            let bio = wallet["bio"] as? String ?? ""
                            let id = wallet["id"] as? String ?? ""
                            let address = wallet["address"] as? String ?? ""
                            let verified = wallet["verified"] as? Bool ?? false
                            wallets.append(AnswerWallet(
                                title: wallet["title"] as? String ?? "",
                                avatar: wallet["avatar"] as? String ?? "",
                                bio: wallet["bio"] as? String ?? "",
                                id: wallet["id"] as? String ?? "",
                                address: wallet["address"] as? String ?? "",
                                verified: wallet["verified"] as? Bool ?? false
                            ))
                        }
                        self.answers.append(AnswerRes(
                            id: item["id"] as? String ?? "",
                            content: item["content"] as? String ?? "",
                            pollID: pollID,
                            votedCount: item["votedCount"] as? Int ?? 0,
                            wallets: wallets,
                            createdAt: item["createdAt"] as? String ?? ""
                        ))
                    }
                    memberVotedURL.removeAll()
                    self.answers.forEach { item in
                        for wallet in item.wallets where !memberVotedURL.contains(wallet.avatar) {
                            memberVotedURL.append(wallet.avatar)
                        }
                    }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        voted = value.userInfo?["voted"] as? Bool ?? false
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Subview
    private func mediaView(_ imageURL: String) -> some View {
        if !isGifMedia, uploadedImage == nil {
            DispatchQueue.main.async {
                let pathExtension = imageURL.components(separatedBy: "?")
                var path = ""
                if pathExtension.count > 0 {
                    path = pathExtension[0]
                }
                let mediaType = path.split(separator: ".").last ?? ""
                if mediaType == "gif" {
                    isGifMedia = true
                } else {
                    Nuke.loadImage(with: imageURL, into: uiImageView) { result in
                        switch result {
                        case .success(let imageResult):
                            uploadedImage = imageResult.image
                        case .failure: break
                        }
                    }
                }
            }
        }
        
        return ZStack {
            if #available(iOS 15.0, *) {
                Rectangle()
                    .foregroundColor(Color.black)
                    .frame(width: mediaWidth, height: mediaWidth)
                ProgressView()
                    .progressViewStyle(.circular)
                    .opacity(!isGifMedia || uploadedImage == nil ? 1 : 0)
                if isGifMedia, let url = URL(string: imageURL) {
                    SwiftyGifView(url: url, frame: mediaWidth)
                        .frame(width: mediaWidth, height: mediaWidth)
                } else if let uiimage = uploadedImage {
                    Image(uiImage: uiimage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: mediaWidth, height: mediaWidth)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: uploadedImage)
    }

    struct SwiftyGifView: UIViewRepresentable {
        var url: URL
        var frame: CGFloat
        var scaleToFit = true

        func makeUIView(context: Context) -> UIView {
            let view = UIView()

            let gifImageView = UIImageView()
            gifImageView.contentMode = .scaleAspectFill
            gifImageView.translatesAutoresizingMaskIntoConstraints = false
            gifImageView.setGifFromURL(url)
            gifImageView.startAnimatingGif()

            view.addSubview(gifImageView)
            NSLayoutConstraint.activate([
                gifImageView.heightAnchor.constraint(equalTo: view.heightAnchor),
                gifImageView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
            return view
        }

        func updateUIView(_ contentView: UIView, context: Context) {
        }
    }

    private var submitResultButton: some View {
        Button(action: {
            if voted {
                onTapViewResult(answers)
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    loadingSubmit = true
                }
                if multipleChoices {
                    onTapSubmit(selectedMultiAnswerID)
                } else {
                    onTapSubmit([selectedAnswerID])
                }
            }
        }) {
            RoundedRectangle(cornerRadius: .infinity)
                .foregroundColor(enableSubmitButton ? Color.white.opacity(0.2) : Color.black.opacity(0.25))
                .frame(width: UIScreen.main.bounds.width * 184 / 375, height: 29)
                .overlay(
                    ZStack {
                        if #available(iOS 14.0, *) {
                            Text("Submit Vote")
                                .tracking(-0.3)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.white.opacity(enableSubmitButton ? 1 : 0.5))
                                .opacity(voted ? 0 : 1)
                                .offset(x: voted ? 50 : 0)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(loadingSubmit ? 0.7 : 0.1)
                                        .opacity(loadingSubmit ? 1 : 0)
                                        .offset(x: 22), alignment: .trailing
                                )
                        } else {
                            EmptyView()
                        }
                        Text("View Results")
                            .tracking(-0.3)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white)
                            .opacity(voted ? 1 : 0)
                            .offset(x: voted ? 0 : -50)
                    }
                        .offset(y: 0.5)
                )
                .padding(.horizontal, 16.5)
                .animation(.easeInOut(duration: 0.2), value: enableSubmitButton)
        }
        .disabled(!enableSubmitButton)
        .padding(.bottom, 4.5)
    }

    private var previewButtons: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button(action: { onTapSend() }) {
                Text("Send")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue)
            }
            .padding(.trailing, 33)
            Button(action: { onTapEdit() }) {
                Text("Edit")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.trailing, 33)
            Button(action: { onTapCancel() }) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
        }
        .padding(.top, 12)
    }

    struct ListMemberAvatar: View {
        var avatarURL = ""
        @State private var avatarUIImageView = UIImageView()
        @State private var avatarUIImage: UIImage?

        var body: some View {
            if avatarUIImage == nil {
                DispatchQueue.main.async {
                    Nuke.loadImage(with: avatarURL, into: avatarUIImageView) { result in
                        switch result {
                        case .success(let imageResult):
                            avatarUIImage = imageResult.image
                        case .failure: break
                        }
                    }
                }
            }
            return ZStack {
                if #available(iOS 15.0, *) {
                    Rectangle()
                        .foregroundColor(Color.clear)
                        .frame(width: 16.5, height: 16.5)
                        .overlay(
                            ZStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.5)
                                    .opacity(avatarUIImage == nil ? 1 : 0)
                                if avatarUIImage != nil {
                                    Image(uiImage: avatarUIImage!)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 16.5, height: 16.5)
                                }
                            }
                        )
                        .cornerRadius(.infinity)
                }
            }
        }
    }
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
    var multipleChoices = true
    var hideTally = false
    var isPreview = false
    var isSender: Bool
    @Binding var selectedAnswerID: String
    @Binding var selectedMultiAnswerID: [String]
    @Binding var voted: Bool
    @Binding var answers: [AnswerRes]

    // MARK: - Properties
    @State private var chartLength: CGFloat = 0 // 118

    // MARK: - Computed Variables
    private var percent: CGFloat {
        var result: CGFloat = 0
        let test = answers
        answers.forEach { item in
            let test = item
            result += CGFloat(item.votedCount)
        }
        let answer = answers.first(where: { $0.id == item.id })
        let vote = CGFloat(answer?.votedCount ?? 0)
        let rate = result == 0 ? 0 : (vote / result)
        return rate * 100
    }

    // MARK: - Body view
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
            if #available(iOS 14.0, *) {
                ZStack {
                    if multipleChoices {
                        HStack(alignment: .top, spacing: !hideTally || voted ? 3.5 : 6) {
                            Image(systemName: isPreview ? "circle" :
                                    (selectedMultiAnswerID.contains(item.id) ?
                                  "checkmark.circle.fill" : "circle"))
                                .resizable()
                                .foregroundColor(Color.white)
                                .frame(width: 15, height: 15)
                                .opacity(voted ? (selectedMultiAnswerID.contains(item.id) ? 1 : 0) : 1)
                            ZStack(alignment: .topLeading) {
                                Text(item.content)
                                    .tracking(-0.3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white)
                                    .opacity(selectedMultiAnswerID.contains(item.id) ? 0 : 1)
                                Text(item.content)
                                    .tracking(-0.3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white)
                                    .opacity(selectedMultiAnswerID.contains(item.id) ? 1 : 0)
                            }
                        }
                        .padding(.leading, !hideTally || voted ? 35 : 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: .infinity)
                                .foregroundColor(selectedMultiAnswerID.contains(item.id) ?
                                                 Color.white.opacity(0.5) : Color.black.opacity(0.4))
                                .frame(width: chartLength == 0 ?
                                       2 : (UIScreen.main.bounds.width * chartLength / 375),
                                       height: 2)
                                .opacity(!hideTally || voted ? 1 : 0)
                                .padding(.leading, 54)
                                .offset(y: 7), alignment: .bottomLeading
                        )
                    } else {
                        HStack(alignment: .top, spacing: !hideTally || voted ? 3.5 : 6) {
                            Image(systemName: isPreview ? "circle" :
                                    (selectedAnswerID == item.id ?
                                  "checkmark.circle.fill" : "circle"))
                                .resizable()
                                .foregroundColor(Color.white)
                                .frame(width: 15, height: 15)
                                .opacity(voted ? (selectedAnswerID == item.id ? 1 : 0) : 1)
                            ZStack(alignment: .topLeading) {
                                Text(item.content)
                                    .tracking(-0.3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white)
                                    .opacity(selectedAnswerID == item.id ? 0 : 1)
                                Text(item.content)
                                    .tracking(-0.3)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white)
                                    .opacity(selectedAnswerID == item.id ? 1 : 0)
                            }
                        }
                        .padding(.leading, !hideTally || voted ? 35 : 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: .infinity)
                                .foregroundColor(selectedAnswerID == item.id ?
                                                 Color.white.opacity(0.5) : Color.black.opacity(0.4))
                                .frame(width: chartLength == 0 ?
                                       2 : (UIScreen.main.bounds.width * chartLength / 375),
                                       height: 2)
                                .opacity(!hideTally || voted ? 1 : 0)
                                .padding(.leading, 54)
                                .offset(y: 7), alignment: .bottomLeading
                        )
                    }
                }
                .overlay(
                    Text("\(String(format: "%.0f", percent))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.white)
                        .opacity(!hideTally || voted ? 1 : 0)
                        .padding(.leading, 1.5), alignment: .topLeading
                )
                .onChange(of: percent) { value in
                    chartLength = 0
//                    withAnimation(.easeInOut(duration: 0.3)) {
                        chartLength = CGFloat(value * 150 / 100)
//                    }
                }
            } else {
                EmptyView()
            }
        }
    }
}
