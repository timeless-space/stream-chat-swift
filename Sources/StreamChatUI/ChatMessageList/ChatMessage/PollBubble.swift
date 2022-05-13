//
//  PollBubble.swift
//  StreamChatUI
//
//  Created by Phu Tran on 11/05/2022.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI
import SwiftUI

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
    var channel: ChatChannel?

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
        viewContainer.isHidden = !isSender
        setBubbleConstraints(isSender)
        if #available(iOS 13.0, *) {
            if let pollData = self.getExtraData(key: "pollPreview"),
               let questionRaw = pollData["question"],
               let imageURLStrRaw = pollData["imageURLStr"],
               let optionListRaw = pollData["optionList"],
               let anonymousPollingRaw = pollData["anonymousPolling"],
               let multipleAnswersRaw = pollData["multipleAnswers"],
               let hideTallyUntilVoteRaw = pollData["hideTallyUntilVote"],
               let isSendedRaw = pollData["isSended"] {
                let question = fetchRawData(raw: questionRaw) as? String ?? ""
                let imageURLStr = fetchRawData(raw: imageURLStrRaw) as? String ?? ""
                let optionListStr = fetchRawData(raw: optionListRaw) as? String ?? ""
                let optionList = optionListStr.components(separatedBy: "-")
                let anonymousPolling = (fetchRawData(raw: anonymousPollingRaw) as? String ?? "1") == "1" ? true : false
                let multipleAnswers = (fetchRawData(raw: multipleAnswersRaw) as? String ?? "1") == "1" ? true : false
                let hideTallyUntilVote = (fetchRawData(raw: hideTallyUntilVoteRaw) as? String ?? "1") == "1" ? true : false
                let isSended = (fetchRawData(raw: isSendedRaw) as? String ?? "1") == "1" ? true : false
                subContainer.fit(subview: PollView(
                    question: question,
                    imageURLStr: imageURLStr,
                    optionList: optionList,
                    multipleAnswers: multipleAnswers,
                    hideTallyUntilVote: hideTallyUntilVote,
                    isSended: isSended,
                    onTapSend: {
                        self.onTapSend(
                            question: question,
                            imageURLStr: imageURLStr,
                            optionList: optionList,
                            anonymousPolling: anonymousPolling,
                            multipleAnswers: multipleAnswers,
                            hideTallyUntilVote: hideTallyUntilVote
                        )
                    }, onTapEdit: {
                        self.onTapEdit()
                    }, onTapCancel: {
                        self.onTapCancel()
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
                timestampLabel?.text = "\(isSended ? "" : "Only visible to you ")\(nameAndTimeString ?? "")"
            }
        }
    }

    private func getExtraData(key: String) -> [String: RawJSON]? {
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
        imageURLStr: String,
        optionList: [String],
        anonymousPolling: Bool,
        multipleAnswers: Bool,
        hideTallyUntilVote: Bool
    ) {
        guard let cid = channel?.cid else {
            return
        }
        var userInfo = [String: Any]()
        userInfo["channelId"] = cid
        userInfo["question"] = question
        userInfo["imageUrl"] = imageURLStr
        userInfo["anonymous"] = anonymousPolling
        userInfo["multipleChoices"] = multipleAnswers
        userInfo["hideTally"] = hideTallyUntilVote
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
        userInfo["channelId"] = cid
        userInfo["editData"] = editData
        NotificationCenter.default.post(name: .editPoll, object: nil, userInfo: userInfo)
    }

    private func onTapCancel() {
        contentView.removeFromSuperview()
    }
}

@available(iOS 13.0.0, *)
struct PollView: View {
    // MARK: - Input Paramters
    var question = ""
    var imageURLStr = ""
    var optionList = [""]
    var multipleAnswers = true
    var hideTallyUntilVote = true
    var isSended = false

    // MARK: - Properties
    @State private var selectedOptionIDX = -1

    // MARK: - Callback functions
    var onTapSend: () -> Void
    var onTapEdit: () -> Void
    var onTapCancel: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                if #available(iOS 15.0, *), let imageURL = URL(string: imageURLStr) {
                    Rectangle()
                        .foregroundColor(Color.black) // TODO
                        .frame(width: UIScreen.main.bounds.width * 241 / 375,
                               height: UIScreen.main.bounds.width * 241 / 375)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(question)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white)
                    ForEach(0 ..< optionList.count) { idx in
                        PollSelectLine(item: optionList[idx],
                                       idx: idx,
                                       multipleAnswers: multipleAnswers,
                                       selectedOptionIDX: $selectedOptionIDX)
                    }
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 18)
            }
            .frame(minWidth: UIScreen.main.bounds.width * 241 / 375, alignment: .leading)
            .background(Color.blue)
            .cornerRadius(12)
            .disabled(!isSended)
            if !isSended {
                HStack(spacing: 33) {
                    Spacer(minLength: 0)
                    Button(action: {
                        onTapSend()
                    }) {
                        Text("Send")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.blue)
                    }
                    Button(action: { onTapEdit() }) {
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    Button(action: { onTapCancel() }) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct PollSelectLine: View {
    // MARK: - Input Parameter
    var item = ""
    var idx: Int
    var multipleAnswers = true
    @Binding var selectedOptionIDX: Int

    @State private var isSelect = false

    var body: some View {
        Button(action: {
            if multipleAnswers {
                isSelect.toggle()
            } else {
                selectedOptionIDX = idx
            }
        }) {
            HStack(alignment: .top, spacing: 5) {
                if multipleAnswers {
                    Image(systemName: isSelect ? "circle.fill" : "circle")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(width: 17, height: 17)
                } else {
                    Image(systemName: selectedOptionIDX == idx ? "circle.fill" : "circle")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(width: 17, height: 17)
                }
                Text(item)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 14))
                    .foregroundColor(Color.white)
            }
        }
    }
}
