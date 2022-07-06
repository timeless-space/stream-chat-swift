//
//  MusicBubble.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/07/22.
//

import StreamChat

protocol MusicCellTapEvent: AnyObject {
    func onTapOfMusicCell(messageContent: ChatMessage)
}

public class MusicBubble: UITableViewCell {
    // MARK: - Input Properties
    var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var channel: ChatChannel?

    // MARK: - Properties
    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var timestampLabel: UILabel!
    private let chatClient = ChatClient.shared
    private lazy var dateFormatter: DateFormatter = .makeDefault()
    weak var delegate: MusicCellTapEvent?
    var tapGesture: UITapGestureRecognizer?

    // MARK: - Computed Variables
    private var cellWidth: CGFloat {
        UIScreen.main.bounds.width * 0.3
    }

    // MARK: - Methods
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
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
        viewContainer.backgroundColor = Appearance.default.colorPalette.background6
        viewContainer.clipsToBounds = true
        viewContainer.cornerRadius = 10

        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(onTapOfMusicCell))
        tapGesture?.numberOfTapsRequired = 1
        if let tapGesture = tapGesture {
            viewContainer.addGestureRecognizer(tapGesture)
        }

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
        NSLayoutConstraint.activate([
            subContainer.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
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

        // MARK: - Set Anchor
        viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor,
                                               constant: 8).isActive = true
        viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor,
                                                                            constant: -cellWidth).isActive = true
    }

    @objc private func onTapOfMusicCell() {
        if let content = content {
            delegate?.onTapOfMusicCell(messageContent: content)
        }
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

        subContainer.subviews.forEach { $0.removeFromSuperview() }
        subContainer.fit(subview: MusicBubbleView())
        let controller = chatClient.currentUserController()

        timestampLabel.textAlignment = isSender ? .right : .left
        var nameAndTimeString = ""
        if let options = layoutOptions {
            if options.contains(.authorName), let name = content?.author.name {
                nameAndTimeString.append("\(name)   ")
            }
            if let createdAt = content?.createdAt {
                if options.contains(.timestamp) {
                    nameAndTimeString.append("\(dateFormatter.string(from: createdAt))")
                }
            }
        }
        timestampLabel?.text = nameAndTimeString
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
}
