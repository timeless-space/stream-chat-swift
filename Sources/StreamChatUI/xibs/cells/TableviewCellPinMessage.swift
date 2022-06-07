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
    // MARK: - Variables
    static let reuseID = "TableviewCellPinMessage"
    private var contentWidth: CGFloat {
        return UIScreen.main.bounds.width - 100
    }
    public var message: ChatMessage? {
        didSet {
            configureData()
        }
    }
    private var messageLabel: UILabel!
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
        messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messageLabel)
        messageLabel.numberOfLines = 1
        messageLabel.textAlignment = .center
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        layoutMessageLabel()
    }

    private func layoutMessageLabel() {
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor
                .constraint(equalTo: contentView.centerXAnchor),
            messageLabel.centerYAnchor
                .constraint(equalTo: contentView.centerYAnchor),
            messageLabel.widthAnchor.constraint(equalToConstant: contentWidth)
        ])
    }

    // MARK: - Configure Data
    private func configureData() {
        messageLabel.text = ""
        guard let message = message else {
            return
        }
        let authorName = message.author.name ?? ""
        let description = " pinned \"\(message.text)\""
        var attributes = [NSAttributedString.Key.font :
                            UIFont.boldSystemFont(ofSize: 15)]
        var boldString = NSMutableAttributedString(string: authorName,
                                                   attributes:attributes)
        var attributedString = NSMutableAttributedString()
        attributedString.append(boldString)
        attributedString.append(NSAttributedString(string: description))
        messageLabel.attributedText = attributedString
    }
}
