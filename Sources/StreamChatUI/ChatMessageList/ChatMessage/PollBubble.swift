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
               let anonymousRaw = pollData["anonymous"],
               let multipleChoicesRaw = pollData["multiple_choices"],
               let hideTallyRaw = pollData["hide_tally"],
               let answersRaw = pollData["answers"] {
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
                    if let id = item["id"],
                       let content = item["content"],
                       let pollID = item["poll_id"],
                       let votedCount = item["voted_count"],
                       let createdAt = item["created_at"] {
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
                var pollVotedCount: Double = 0
                if let pollVotedCountRaw = pollData["poll_voted_count"] {
                    pollVotedCount = fetchRawData(raw: pollVotedCountRaw) as? Double ?? 0
                }

                var orderedWallets: [OrderedWallet] = []
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
                            orderedWallets.append(OrderedWallet(
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
                    pollVotedCount: pollVotedCount,
                    orderedWallets: orderedWallets,
                    pollID: pollID,
                    isSender: isSender,
                    isPreview: isPreview,
                    showYourFirstPoll: showYourFirstPoll,
                    callBackSend: {
                        guard let messageId = self.content?.id else { return }
                        let action = AttachmentAction(name: "action",
                                                      value: "submit",
                                                      style: .primary,
                                                      type: .button,
                                                      text: "Send")
                        self.chatClient.messageController(cid: cid,
                                                            messageId: messageId)
                            .dispatchEphemeralMessageAction(action, completion: { error in
                                if error == nil {
                                    var userInfo = [String: Any]()
                                    userInfo["firstPollMessageID"] = messageId
                                    NotificationCenter.default.post(name: .pollSended, object: nil, userInfo: userInfo)
                                }
                            })
                    },
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
            case .dictionary(let dictionary):
                return dictionary
            default:
                return nil
            }
        } else {
            return nil
        }
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
        chatClient.messageController(cid: cid, messageId: messageId)
            .dispatchEphemeralMessageAction(action)
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

    private func onTapViewResult(
        question: String,
        mediaUrl: String,
        answerList: [AnswerRes],
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

extension UILabel {
    func addImage(systemName: String, afterLabel: Bool = false) {
        let attachment = NSTextAttachment()
        if #available(iOS 15.0, *) {
            attachment.image = UIImage(systemName: systemName)
            attachment.image = attachment.image?.withTintColor(Appearance.default.colorPalette.subtitleText)
            attachment.bounds = CGRect(x: 0, y: 0, width: 15.5, height: 10)
        }
        let attachmentString = NSAttributedString(attachment: attachment)
        if afterLabel {
            let strLabelText = NSMutableAttributedString(string: self.text!)
            strLabelText.append(attachmentString)
            self.attributedText = strLabelText
        } else {
            let strLabelText = NSAttributedString(string: self.text!)
            let mutableAttachmentString = NSMutableAttributedString(attributedString: attachmentString)
            mutableAttachmentString.append(strLabelText)
            self.attributedText = mutableAttachmentString
        }
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

struct OrderedWallet {
    var walletAddress = ""
    var createdAt = ""
}

@available(iOS 15.0, *)
struct PollView {
    // MARK: - Input Paramters
    var cid: ChannelId
    var question = ""
    var imageUrl = ""
    var multipleChoices = false
    var hideTally = false
    @State var answers: [AnswerRes] = []
    @State var pollVotedCount: Double = 0
    @State var orderedWallets: [OrderedWallet] = []
    var pollID = ""
    var isSender: Bool
    var isPreview = false
    var showYourFirstPoll = false

    // MARK: - Properties
    @State private var selectedAnswersID: [String] = []
    @State private var voted = false
    @State private var loadingSubmit = false
    @State private var isLoaded = false
    @State private var uiImageView = UIImageView()
    @State private var uploadedImage: UIImage?
    @State private var memberVotedURL: [String] = []
    @State private var mediaSize: CGSize?
    @State private var isGifMedia = false
    @State private var listVotedAnswer: [String] = []
    private let mediaWidth = UIScreen.main.bounds.width * 243 / 375

    // MARK: - Callback Functions
    var callBackSend: () -> Void
    var callBackEdit: () -> Void
    var callBackCancel: () -> Void
    var callBackSubmit: ([String]) -> Void
    var callBackViewResults: ([AnswerRes], Double) -> Void

    // MARK: Computed Variables
    private var enableSubmitButton: Bool {
        return voted ? true : !selectedAnswersID.isEmpty
    }
}

// MARK: - Body view
@available(iOS 15.0, *)
extension PollView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if !imageUrl.isEmpty {
                    mediaView(imageUrl)
                }
                contentView
            }
            .cornerRadius(15)
            if isPreview {
                previewButtons
            }
        }
        .onAppear { onAppearHandler() }
        .onReceive(NotificationCenter.default.publisher(for: .pollUpdate)) { notification in
            onReceiveUpdatedPoll(notification)
        }
    }
}

// MARK: - Subview
@available(iOS 15.0, *)
extension PollView {
    private func mediaView(_ imageURL: String) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.black)
                .frame(width: mediaWidth, height: mediaWidth)
            ProgressView()
                .progressViewStyle(.circular)
                .opacity(!isGifMedia || uploadedImage == nil ? 1 : 0)
            if isLoaded {
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
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showYourFirstPoll {
                Text("YOUR FIRST POLL")
                    .tracking(-0.4)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.8))
                    .padding(.bottom, 2.5)
            }
            Text(question)
                .tracking(-0.2)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 1)
                .padding(.bottom, isPreview ? 10.5 : 4.5)
            if !isPreview {
                HStack(spacing: 3) {
                    Text("\(Int(pollVotedCount)) \(pollVotedCount > 1 ? "Votes" : "Vote")")
                        .tracking(-0.4)
                        .font(.system(size: 10))
                        .foregroundColor(Color.white)
                        .padding(.leading, 1)
                        .overlay(
                            ZStack {
                                if memberVotedURL.count > 0 {
                                    ForEach(0 ..< (memberVotedURL.count <= 5 ? memberVotedURL.count : 5)) { idx in
                                        ListMemberAvatar(avatarURL: memberVotedURL[idx])
                                            .zIndex(Double(-idx))
                                            .offset(x: CGFloat(idx * 12 - idx))
                                    }
                                }
                            }
                                .offset(x: 21)
                                .id("\(memberVotedURL.count)"), alignment: .trailing
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
                                   listVotedAnswer: listVotedAnswer,
                                   selectedAnswersID: $selectedAnswersID,
                                   voted: $voted,
                                   answers: $answers,
                                   pollVotedCount: $pollVotedCount)
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

        func updateUIView(_ contentView: UIView, context: Context) { }
    }

    private var submitResultButton: some View {
        Button(action: {
            if voted {
                onTapViewResults()
            } else {
                onTapSubmit()
            }
        }) {
            RoundedRectangle(cornerRadius: .infinity)
                .foregroundColor(enableSubmitButton ? Color.white.opacity(0.2) : Color.black.opacity(0.25))
                .frame(width: UIScreen.main.bounds.width * 184 / 375, height: 29)
                .overlay(
                    ZStack {
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
        .id("\(answers)")
    }

    private var previewButtons: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            Button(action: { callBackSend() }) {
                Text("Send")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.blue)
            }
            .padding(.trailing, 33)
            Button(action: { callBackEdit() }) {
                Text("Edit")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            .padding(.trailing, 33)
            Button(action: { callBackCancel() }) {
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
            return Rectangle()
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

    private func memberAvatar(_ avatarURL: String) -> some View {
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

// MARK: - Methods
@available(iOS 15.0, *)
extension PollView {
    private func onAppearHandler() {
        if !imageUrl.isEmpty, !isGifMedia, uploadedImage == nil {
            let pathExtension = imageUrl.components(separatedBy: "?")
            let path = pathExtension.count > 0 ? pathExtension[0] : ""
            let mediaType = path.split(separator: ".").last ?? ""
            if mediaType == "gif" {
                isGifMedia = true
            } else {
                Nuke.loadImage(with: imageUrl, into: uiImageView) { result in
                    switch result {
                    case .success(let imageViewResult):
                        uploadedImage = imageViewResult.image
                    case .failure: break
                    }
                }
            }
        }
        if let userInfo = PollBubble.callback?(pollID) {
            setDataFromUserInfo(userInfo)
        } else {
            var userInfo = [String: Any]()
            userInfo["group_id"] = cid.description
            userInfo["poll_id"] = pollID
            NotificationCenter.default.post(name: .getPollData, object: nil, userInfo: userInfo)
        }
    }

    private func onReceiveUpdatedPoll(_ notification: NotificationCenter.Publisher.Output) {
        if let userInfo = notification.userInfo {
            setDataFromUserInfo(userInfo, updatedPoll: true)
        }
    }

    private func setDataFromUserInfo(_ userInfo: [AnyHashable: Any], updatedPoll: Bool = false) {
        withAnimation(.easeInOut(duration: updatedPoll ? 0.2 : 0)) {
            loadingSubmit = false
        }
        if cid.description == (userInfo["group_id"] as? String ?? ""),
            pollID == (userInfo["poll_id"] as? String ?? "") {
            let question = userInfo["question"] as? String ?? ""
            let imageURL = userInfo["image_url"] as? String ?? ""
            let anonymous = userInfo["anonymous"] as? Bool ?? false
            let multipleChoices = userInfo["multiple_choices"] as? Bool ?? false
            let hideTally = userInfo["hide_tally"] as? Bool ?? false
            let createdAt = userInfo["created_at"] as? String ?? ""
            let expiredAt = userInfo["expired_at"] as? String ?? ""
            let messageID = userInfo["message_id"] as? String ?? ""
            let creator = userInfo["creator"] as? String ?? ""
            let answers = userInfo["answers"] as? [[String: Any]] ?? []
            withAnimation(.easeInOut(duration: updatedPoll ? 0.2 : 0)) {
                voted = userInfo["voted"] as? Bool ?? false
            }
            listVotedAnswer = userInfo["vote_for"] as? [String] ?? []
            pollVotedCount = userInfo["poll_voted_count"] as? Double ?? 0
            let orderedWallets = userInfo["ordered_wallets"] as? [[String: Any]] ?? []
            self.answers.removeAll()
            answers.forEach { answer in
                var wallets: [AnswerWallet] = []
                let walletItems = answer["wallets"] as? [[String: Any]] ?? []
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
                    id: answer["id"] as? String ?? "",
                    content: answer["content"] as? String ?? "",
                    pollID: pollID,
                    votedCount: answer["voted_count"] as? Int ?? 0,
                    wallets: wallets,
                    createdAt: answer["created_at"] as? String ?? ""
                ))
            }
            self.orderedWallets.removeAll()
            orderedWallets.forEach { orderedWallet in
                self.orderedWallets.append(OrderedWallet(
                    walletAddress: orderedWallet["wallet_address"] as? String ?? "",
                    createdAt: orderedWallet["created_at"] as? String ?? ""
                ))
            }
            memberVotedURL.removeAll()
            self.orderedWallets.forEach { orderedWallet in
                if let walletImageURL = PollBubble.getWalletImageURL?(orderedWallet.walletAddress) {
                    memberVotedURL.append(walletImageURL)
                }
            }
            isLoaded = true
        }
    }

    private func onTapSubmit() {
        withAnimation(.easeInOut(duration: 0.2)) {
            loadingSubmit = true
        }
        callBackSubmit(selectedAnswersID)
    }

    private func onTapViewResults() {
        callBackViewResults(answers, pollVotedCount)
    }
}

@available(iOS 15.0, *)
struct PollSelectLine: View {
    // MARK: - Input Parameter
    var item: AnswerRes
    var multipleChoices = true
    var hideTally = false
    var isPreview = false
    var isSender: Bool
    var listVotedAnswer: [String]
    @Binding var selectedAnswersID: [String]
    @Binding var voted: Bool
    @Binding var answers: [AnswerRes]
    @Binding var pollVotedCount: Double

    // MARK: - Properties
    @State private var chartLength: CGFloat = 0

    // MARK: - Computed Variables
    private var percent: CGFloat {
        pollVotedCount <= 0 ? 0 : (CGFloat(item.votedCount) / CGFloat(pollVotedCount) * 100)
    }

    private var checkMarkIcon: String {
        if !isPreview && (listVotedAnswer.contains(item.id) || selectedAnswersID.contains(item.id)) {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }

    private var hideCheckMark: Bool {
        voted && !selectedAnswersID.contains(item.id) && !listVotedAnswer.contains(item.id)
    }

    private var showPercent: Bool {
        !isPreview && (!hideTally || voted)
    }

    private var didSelected: Bool {
        listVotedAnswer.contains(item.id) || selectedAnswersID.contains(item.id)
    }

    // MARK: - Body view
    var body: some View {
        Button(action: {
            if selectedAnswersID.contains(item.id) {
                if multipleChoices {
                    selectedAnswersID.removeAll(where: { $0 == item.id })
                } else {
                    selectedAnswersID.removeAll()
                }
            } else {
                if !multipleChoices {
                    selectedAnswersID.removeAll()
                }
                selectedAnswersID.append(item.id)
            }
        }) {
            HStack(alignment: .top, spacing: !hideTally || voted ? 3.5 : 6) {
                Image(systemName: checkMarkIcon)
                    .resizable()
                    .foregroundColor(Color.white)
                    .frame(width: 15, height: 15)
                    .opacity(hideCheckMark ? 0 : 1)
                ZStack(alignment: .topLeading) {
                    Text(item.content)
                        .tracking(-0.3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white)
                        .opacity(didSelected ? 0 : 1)
                    Text(item.content)
                        .tracking(-0.3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.white)
                        .opacity(didSelected ? 1 : 0)
                }
            }
            .padding(.trailing, 34)
            .offset(x: showPercent ? 35 : 1)
            .overlay(
                RoundedRectangle(cornerRadius: .infinity)
                    .foregroundColor(didSelected ? Color.white.opacity(0.5) : Color.black.opacity(0.4))
                    .frame(width: chartLength == 0 ?
                           2 : (UIScreen.main.bounds.width * chartLength / 375),
                           height: 2)
                    .opacity(showPercent ? 1 : 0)
                    .padding(.leading, 54)
                    .offset(y: 7), alignment: .bottomLeading
            )
            .overlay(
                Text("\(String(format: "%.0f", percent))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.white)
                    .opacity(showPercent ? 1 : 0)
                    .padding(.leading, 1.5), alignment: .topLeading
            )
            .onChange(of: percent) { value in
                // chartLength = 0
                // withAnimation(.easeInOut(duration: !voted ? 0.3 : 0)) {
                chartLength = CGFloat(value * 150 / 100)
                // }
            }
        }
    }
}
