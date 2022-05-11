//
//  PollBubble.swift
//  StreamChatUI
//
//  Created by Phu Tran on 11/05/2022.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
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
    var client: ChatClient?
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
        if #available(iOS 13.0, *) {
            subContainer.fit(subview: PollView())
        }

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

@available(iOS 13.0.0, *)
struct PollView: View {
    @State private var isSend = false
    @State private var isCancel = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("This jacket for park city during our free weekend in August?")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white)
                ForEach(0 ..< 3) { _ in
                    PollSelectLine()
                }
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 18)
            .background(Color.blue)
            .cornerRadius(12)
            HStack(spacing: 33) {
                Spacer(minLength: 0)
                Button(action: { isSend = true }) {
                    Text("Send")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.blue)
                }
                Button(action: {

                }) {
                    Text("Edit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                Button(action: { isCancel = false }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.4))
                }
            }
        }
    }
}

@available(iOS 13.0.0, *)
struct PollSelectLine: View {
    @State private var isSelect = false

    var body: some View {
        Button(action: { isSelect.toggle() }) {
            HStack(spacing: 5) {
                Image(systemName: isSelect ? "circle.fill" : "circle")
                    .resizable()
                    .foregroundColor(Color.white)
                    .frame(width: 17, height: 17)
                Text("Test")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white)
            }
        }
    }
}
