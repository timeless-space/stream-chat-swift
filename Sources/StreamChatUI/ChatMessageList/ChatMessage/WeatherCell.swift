//
//  WeatherCell.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 02/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

enum AttachmentActionType: Int {
    case send, edit, cancel
}

class WeatherCell: UITableViewCell {
    // MARK: - Variables
    private var timestampLabel: UILabel = {
        let timestampLabel = UILabel()
            .withoutAutoresizingMaskConstraints
        timestampLabel.textColor = Appearance.default.colorPalette.subtitleText
        timestampLabel.font = Appearance.default.fonts.footnote
        return timestampLabel
    }()
    private var dateFormatter: DateFormatter = .makeDefault()
    private var mainContainer = ContainerStackView(axis: .horizontal)
        .withoutAutoresizingMaskConstraints
    private var subContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    private var authorAvatarView: ChatAvatarView?
    // Constraints
    private var leadingMainContainer: NSLayoutConstraint?
    private var trailingMainContainer: NSLayoutConstraint?
    // Sub container constraints
    private var leadingSubContainer: NSLayoutConstraint?
    private var trailingSubContainer: NSLayoutConstraint?
    private var topSubContainer: NSLayoutConstraint?
    private var bottomSubContainer: NSLayoutConstraint?
    // Avatar
    private var messageAuthorAvatarSize: CGSize { .init(width: 32, height: 32) }
    // Cell width
    private var cellWidth: CGFloat = 200.0
    private var widthConstraintForMainContainer: NSLayoutConstraint?

    private var mainContentView = UIView()
        .withoutAutoresizingMaskConstraints
    private var weatherImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    private var backgroundImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    private var contentDetailsContainer = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    private var subContentView = UIView()
        .withoutAutoresizingMaskConstraints
    private var onlyVisibleToYouContainer = ContainerStackView()
    private var onlyVisibleToYouImageView: UIImageView = {
        let onlyVisibleToYouImageView = UIImageView()
            .withoutAutoresizingMaskConstraints
        onlyVisibleToYouImageView.tintColor = Appearance.default.colorPalette.subtitleText
        onlyVisibleToYouImageView.image = Appearance.default.images.onlyVisibleToCurrentUser
        onlyVisibleToYouImageView.contentMode = .scaleAspectFit
        onlyVisibleToYouImageView.transform = .mirrorY
        return onlyVisibleToYouImageView
    }()
    private var onlyVisibleToYouLabel: UILabel = {
        let onlyVisibleToYouLabel = UILabel()
            .withoutAutoresizingMaskConstraints
        onlyVisibleToYouLabel.textColor = Appearance.default.colorPalette.subtitleText
        onlyVisibleToYouLabel.text = "Only visible to you  "
        onlyVisibleToYouLabel.font = Appearance.default.fonts.footnote
        onlyVisibleToYouLabel.transform = .mirrorY
        return onlyVisibleToYouLabel
    }()
    private var locationNameLabel: UILabel = {
        let locationNameLabel = UILabel()
            .withoutAutoresizingMaskConstraints
        locationNameLabel.textColor = .white
        locationNameLabel.font = Appearance.default.fonts.proSemibold12
        locationNameLabel.transform = .mirrorY
        return locationNameLabel
    }()
    private var temperatueLabel: UILabel = {
       let temperatueLabel = UILabel()
            .withoutAutoresizingMaskConstraints
        temperatueLabel.textColor = .white
        temperatueLabel.font = Appearance.default.fonts.proRegular32
        temperatueLabel.transform = .mirrorY
        return temperatueLabel
    }()
    private var messageLabel: UILabel = {
        var messageLabel = UILabel()
            .withoutAutoresizingMaskConstraints
        messageLabel.textColor = .white
        messageLabel.font = Appearance.default.fonts.proSemibold10
        messageLabel.transform = .mirrorY
        messageLabel.numberOfLines = 2
        return messageLabel
    }()
    private var weatherForOneWalletLabel: UILabel = {
        let weatherForOneWalletLabel = UILabel().withoutAutoresizingMaskConstraints
        weatherForOneWalletLabel.textColor = Appearance.default.colorPalette.statusColorBlue
        weatherForOneWalletLabel.font = Appearance.default.fonts.proRegular8
        weatherForOneWalletLabel.transform = .mirrorY
        weatherForOneWalletLabel.textAlignment = .right
        return weatherForOneWalletLabel
    }()
    private var imageDetailsStackView = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
    private var actionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillProportionally
        return stack
    }()

    private var subStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    // Message details
    var content: ChatMessage?
    var chatChannel: ChatChannel?
    var weatherType: String = ""
    var layoutOptions: ChatMessageLayoutOptions?
    private var isCurrentMessageSend = false
    private var imageLoader = Components.default.imageLoader

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

        // Only visible view
        addOnlyVisibleViewContainer()

        subContentView.backgroundColor = .clear
        subContentView.addSubview(subContainer)
        subContentView.layer.cornerRadius = 18
        mainContentView.layer.cornerRadius = 18

        topSubContainer = subContainer.topAnchor.constraint(equalTo: subContentView.topAnchor, constant: 0)
        bottomSubContainer = subContainer.bottomAnchor.constraint(equalTo: subContentView.bottomAnchor, constant: 0)
        leadingSubContainer = subContainer.leadingAnchor.constraint(equalTo: subContentView.leadingAnchor, constant: 0)
        trailingSubContainer = subContainer.trailingAnchor.constraint(equalTo: subContentView.trailingAnchor, constant: 0)

        NSLayoutConstraint.activate([
            topSubContainer!, bottomSubContainer!, leadingSubContainer!, trailingSubContainer!])

        subStackView.addArrangedSubview(subContentView)
        subStackView.addArrangedSubview(onlyVisibleToYouContainer)
        subStackView.addArrangedSubview(timestampLabel)

        mainContainer.addArrangedSubviews([createAvatarView(), subStackView])
        mainContainer.alignment = .bottom
        contentView.addSubview(mainContainer)

        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
        ])
        widthConstraintForMainContainer?.isActive = true
        mainContentView.widthAnchor.constraint(equalToConstant: cellWidth).isActive = true
        mainContentView.heightAnchor.constraint(equalToConstant: cellWidth).isActive = true
        backgroundImageView.transform = .mirrorY
        weatherImageView.transform = .mirrorY
        mainContentView.addSubview(backgroundImageView)
        mainContentView.addSubview(weatherImageView)
        mainContentView.addSubview(imageDetailsStackView)

        NSLayoutConstraint.activate([
            weatherImageView.bottomAnchor.constraint(equalTo: mainContentView.bottomAnchor, constant: 5),
            weatherImageView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: 5),
            weatherImageView.widthAnchor.constraint(equalToConstant: 135),
            weatherImageView.heightAnchor.constraint(equalToConstant: 135)
        ])

        NSLayoutConstraint.activate([
            backgroundImageView.bottomAnchor.constraint(equalTo: mainContentView.bottomAnchor, constant: 0),
            backgroundImageView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: 0),
            backgroundImageView.topAnchor.constraint(equalTo: mainContentView.topAnchor, constant: 0),
            backgroundImageView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 0),
        ])

        NSLayoutConstraint.activate([
            imageDetailsStackView.topAnchor.constraint(equalTo: mainContentView.topAnchor, constant: 20),
            imageDetailsStackView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 15),
            imageDetailsStackView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -10)
        ])

        // Action buttons
        addImageDetailLabels()
        // Action buttons
        addActionView()
        subContainer.axis = .vertical
        subContainer.distribution = .natural
        subContainer.spacing = .auto
        subContainer.addArrangedSubview(actionsStackView)
        subContainer.addArrangedSubview(weatherForOneWalletLabel)
        subContainer.addArrangedSubview(mainContentView)
        subContainer.transform = .mirrorY

        leadingMainContainer = mainContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8)
        trailingMainContainer = mainContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
    }

    private func addImageDetailLabels() {
        imageDetailsStackView.spacing = 2
        imageDetailsStackView.addArrangedSubviews([messageLabel, temperatueLabel, locationNameLabel])
    }

    private func addActionView() {
        actionsStackView.addArrangedSubview(createActionButton(text: "Send", type: .send))
        actionsStackView.addArrangedSubview(createActionButton(text: "Edit", type: .edit))
        actionsStackView.addArrangedSubview(createActionButton(text: "Cancel", type: .cancel))
    }

    private func addOnlyVisibleViewContainer() {
        onlyVisibleToYouContainer.transform = .mirrorY
        onlyVisibleToYouImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        onlyVisibleToYouContainer.addArrangedSubview(UIView())
        onlyVisibleToYouContainer.addArrangedSubview(onlyVisibleToYouImageView)
        onlyVisibleToYouContainer.addArrangedSubview(onlyVisibleToYouLabel)
    }

    private func setBubbleConstraints(_ isSender: Bool) {
        leadingMainContainer?.isActive = !isSender
        trailingMainContainer?.isActive = isSender
        topSubContainer?.constant = isCurrentMessageSend ? 15 : 0
        leadingSubContainer?.constant = isCurrentMessageSend ? 15 : 0
        trailingSubContainer?.constant = isCurrentMessageSend ? -15 : 0
        bottomSubContainer?.constant = isCurrentMessageSend ? -15 : 0
    }

    private func createActionButton(text: String, type: AttachmentActionType) -> UIButton {
        var button = UIButton()
        button.addTarget(self, action: #selector(onActionItemTapped(sender:)), for: .touchUpInside)
        button.tag = type.rawValue
        button.tintColor = Appearance.default.colorPalette.subtitleText
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(type == .send ?
                             Appearance.default.colorPalette.textColorBlue :
                                UIColor.white.withAlphaComponent(0.4), for: .normal)
        button.setTitle(text, for: .normal)
        button.contentMode = .scaleAspectFit
        button.transform = .mirrorY
        return button
    }

    @objc func onActionItemTapped(sender: UIButton) {
        switch sender.tag {
        case AttachmentActionType.send.rawValue: // Send Action
            callBackSend()
        case AttachmentActionType.edit.rawValue: // Edit Action
            callBackEdit()
        case AttachmentActionType.cancel.rawValue: // Cancel Action
            callBackCancel()
        default:
            break
        }
    }

    private func callBackSend() {
        guard let messageId = content?.id, let cid = chatChannel?.cid else { return }
        let action = AttachmentAction(name: "action",
                                      value: "submit",
                                      style: .primary,
                                      type: .button,
                                      text: "Send")
        ChatClient.shared.messageController(cid: cid, messageId: messageId).dispatchEphemeralMessageAction(action)
    }

    private func callBackEdit() {
        guard let messageId = content?.id else {
            return
        }
        let userInfo = ["messageId": messageId]
        NotificationCenter.default.post(name: .showLocationPicker, object: nil, userInfo: userInfo)
    }

    private func callBackCancel() {
        guard let messageId = content?.id, let cid = chatChannel?.cid else {
            return
        }
        let action = AttachmentAction(name: "action",
                                      value: "cancel",
                                      style: .default,
                                      type: .button,
                                      text: "Cancel")
        ChatClient.shared.messageController(cid: cid, messageId: messageId).dispatchEphemeralMessageAction(action)
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

    func configureCell(isSender: Bool) {

        isCurrentMessageSend = !(content?.localState == .pendingSend || content?.localState == .sending || content?.type == .ephemeral)

        guard let currentLocation = self.content?.extraData.currentLocation,
              let currentTemp = self.content?.extraData.currentWeather,
              let displayMessage = self.content?.extraData.displayMessage,
              let weatherCode = self.content?.extraData.iconCode else {
                  return
              }

        var temp = Measurement(
            value: Double(currentTemp) ?? 0,
            unit: UnitTemperature.kelvin)

        if weatherType == "Fahrenheit" {
            temperatueLabel.text = WeatherHelper.temperatureValueFormatter.string(
                from: temp.converted(to: .fahrenheit)
            )
        } else {
            temperatueLabel.text = WeatherHelper.temperatureValueFormatter.string(
                from: temp.converted(to: .celsius)
            )
        }
        locationNameLabel.text = currentLocation
        messageLabel.text = displayMessage
        weatherForOneWalletLabel.text = "WEATHER FOR 1WALLET"
        let weatherDetail = WeatherHelper.getWeatherDetail(
            condition: weatherCode
        )
        loadImage(url: URL(string: weatherDetail.getImageUrl()), view: weatherImageView ?? .init())
        backgroundImageView.image = weatherDetail.backgroundImage ?? UIImage()
        // Set constraints
        setBubbleConstraints(isSender)
        authorAvatarView?.isHidden = isSender

        if !isCurrentMessageSend {
            subContentView.backgroundColor = .clear
            actionsStackView.isHidden = false
            onlyVisibleToYouContainer.isHidden = false
            weatherForOneWalletLabel.isHidden = true
        } else {
            subContentView.backgroundColor = isSender ? Appearance.default.colorPalette.outgoingMessageColor : Appearance.default.colorPalette.incommingMessageColor
            actionsStackView.isHidden = true
            onlyVisibleToYouContainer.isHidden = true
            weatherForOneWalletLabel.isHidden = false
        }

        if let options = layoutOptions, let memberCount = chatChannel?.memberCount {
            // Hide Avatar view for one-way chat
            if memberCount <= 2 {
                authorAvatarView?.isHidden = true
            } else {
                authorAvatarView?.isHidden = false
                if !options.contains(.authorName) {
                    authorAvatarView?.imageView.image = nil
                } else {
                    loadImage(url: self.content?.author.imageURL, view: authorAvatarView?.imageView ?? .init())
                }
            }
            timestampLabel.isHidden = (!options.contains(.timestamp) || !isCurrentMessageSend)
        }
        if let createdAt = self.content?.createdAt,
           let authorName = self.content?.author.name?.trimStringBy(count: 15),
           let memberCount = chatChannel?.memberCount {
            var authorName = (memberCount <= 2) ? "" : authorName
            // Add extra white space in leading
            if !isSender {
                timestampLabel.text = " " + authorName + "  " + dateFormatter.string(from: createdAt)
                timestampLabel.textAlignment = .left
            } else {
                timestampLabel.text = dateFormatter.string(from: createdAt)
                timestampLabel.textAlignment = .right
            }
        } else {
            timestampLabel.text = nil
        }
    }

    private func loadImage(url: URL?, view: UIImageView) {
        imageLoader.loadImage(
            into: view,
            url: url,
            imageCDN: Components.default.imageCDN,
            placeholder: nil,
            preferredSize: nil
        )
    }

    private func createAvatarView() -> ChatAvatarView {
        if authorAvatarView == nil {
            authorAvatarView = Components.default
                .avatarView
                .init()
                .withoutAutoresizingMaskConstraints
        }
        authorAvatarView?.widthAnchor.pin(equalToConstant: messageAuthorAvatarSize.width).isActive = true
        authorAvatarView?.heightAnchor.pin(equalToConstant: messageAuthorAvatarSize.height).isActive = true
        return authorAvatarView!
    }
}
