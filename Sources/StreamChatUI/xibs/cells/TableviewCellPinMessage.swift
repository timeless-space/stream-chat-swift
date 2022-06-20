//
//  TableviewCellPinMessage.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 07/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

open class TableviewCellPinMessage: _TableViewCell {
    static let reuseID = "TableviewCellPinMessage"

    // MARK: - Variables
    private lazy var messageLabel = UILabel()
    private lazy var lastSymbol = UILabel()

    // MARK: - Life cycle
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - UI
    private func setLayout() {
        contentView.transform = .mirrorY
        selectionStyle = .none
        backgroundColor = .clear
        setupMessageLabel()
        layoutMessageLabel()
    }

    private func setupMessageLabel() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 1
        messageLabel.textAlignment = .center
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        contentView.addSubview(messageLabel)

        lastSymbol.translatesAutoresizingMaskIntoConstraints = false
        lastSymbol.numberOfLines = 1
        lastSymbol.textAlignment = .center
        lastSymbol.textColor = .white
        lastSymbol.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        lastSymbol.text = "\""
        contentView.addSubview(lastSymbol)
        lastSymbol.leadingAnchor
            .constraint(equalTo: messageLabel.trailingAnchor).isActive = true
        lastSymbol.centerYAnchor
            .constraint(equalTo: messageLabel.centerYAnchor).isActive = true
    }

    private func layoutMessageLabel() {
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor
                .constraint(equalTo: contentView.centerXAnchor, constant: -5),
            messageLabel.leadingAnchor
                .constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 25),
            messageLabel.trailingAnchor
                .constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -25),
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageLabel.bottomAnchor
                .constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: 0),
        ])
    }

    // MARK: - Configure Data
    public func configureData(message: ChatMessage?, pinAuthor: ChatChannelMember?) {
        messageLabel.text = ""
        lastSymbol.text = ""
        guard let message = message, let pinAuthor = pinAuthor else {
            return
        }
        var authorName = pinAuthor.name ?? ""
        if authorName.lowercased() == pinAuthor.id.lowercased()  {
            let last = pinAuthor.id.suffix(5)
            let first = pinAuthor.id.prefix(7)
            authorName = "\(first)...\(last)"
        }
        let text = getMessageDescription(message: message)
        let description = " pinned \"\(text)"
        var attributes = [NSAttributedString.Key.font :
                            UIFont.boldSystemFont(ofSize: 15)]
        var boldString = NSMutableAttributedString(string: authorName,
                                                   attributes:attributes)
        var attributedString = NSMutableAttributedString()
        attributedString.append(boldString)
        attributedString.append(NSAttributedString(string: description))
        messageLabel.attributedText = attributedString
        lastSymbol.text = text.isBlank ? "" : "\""
    }

    private func getMessageDescription(message: ChatMessage) -> String {
        if let attachment = message.imageAttachments.first {
            return "Image"
        } else if let attachment = message.videoAttachments.first {
            return "Video"
        } else if let attachment = message.fileAttachments.first {
            return "File"
        } else {
            return message.text
        }
    }
}
