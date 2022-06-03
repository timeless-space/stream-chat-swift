//
//  PinMessageContainerView.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 01/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public class PinMessageContainerView: UIView {

    // MARK: - Variables
    open private(set) lazy var labelTitle: UILabel = {
        return UILabel(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var labelMessage: UILabel = {
        return UILabel(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var unPinCloseButton: UIButton = {
        return UIButton().withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var indicatorView: UIView = {
        return UIView(frame: .zero).withoutAutoresizingMaskConstraints
    }()
    open private(set) lazy var attachmentView: UIView = {
        let view = UIView(frame: .zero).withoutAutoresizingMaskConstraints
        view.backgroundColor = .clear
        return view
    }()
    open private(set) lazy var attachmentViewWidthConstraint: NSLayoutConstraint = {
        return attachmentView.widthAnchor.constraint(equalToConstant: 38)
    }()
    open private(set) lazy var titleLeadingConstraint: NSLayoutConstraint = {
        return labelTitle.leadingAnchor
            .constraint(equalTo: attachmentView.trailingAnchor, constant: 10)
    }()
    private lazy var pinMessages = [ChatMessage]()
    private var currentMessageIndex = 0

    // Callback
    public var callbackMessageDidSelect:((ChatMessage) -> Void)?
    public var callbackCloseButton:((ChatMessage) -> Void)?

    // MARK: - UI
    public func setupUI(pinMessages: [ChatMessage]) {
        self.pinMessages = pinMessages
            .sorted(by: { $0.createdAt > $1.createdAt })
        subviews.forEach { $0.removeFromSuperview() }
        // subview
        addSubview(indicatorView)
        addSubview(attachmentView)
        addSubview(labelTitle)
        addSubview(labelMessage)
        addSubview(unPinCloseButton)
        // layout view
        layoutIndicatorView()
        layoutAttachmentContainerView()
        layoutAttachmentView(isVisible: false)
        layoutTitleLabel()
        layoutMessageLabel()
        layoutCloseButton()
        // setup content
        setupIndicatorView()
        setupMessage()
        setupCloseButton()
        // Gesture Recogniser
        let swipeGestureRecognizerDown = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        let swipeGestureRecognizerUp = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(_:)))
        swipeGestureRecognizerDown.direction = .down
        swipeGestureRecognizerUp.direction = .up
        addGestureRecognizer(swipeGestureRecognizerDown)
        addGestureRecognizer(swipeGestureRecognizerUp)
        let tapGestureRecognizerDown = UITapGestureRecognizer.init(target: self, action: #selector(tapGestureAction(_:)))
        tapGestureRecognizerDown.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizerDown)
        labelTitle.isUserInteractionEnabled = false
        labelMessage.isUserInteractionEnabled = false
        isUserInteractionEnabled = true
    }

    private func layoutIndicatorView() {
        NSLayoutConstraint.activate([
            indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            indicatorView.heightAnchor.constraint(equalToConstant: 38),
            indicatorView.widthAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func layoutAttachmentContainerView() {
        NSLayoutConstraint.activate([
            attachmentView.leadingAnchor.constraint(equalTo: indicatorView.leadingAnchor, constant: 10),
            attachmentView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            attachmentViewWidthConstraint,
            attachmentView.heightAnchor.constraint(equalToConstant: 38),
        ])
    }

    private func layoutAttachmentView(isVisible: Bool) {
        attachmentViewWidthConstraint.constant = isVisible ? 38 : 0
        attachmentViewWidthConstraint.isActive = true
        titleLeadingConstraint.constant = isVisible ? 10 : 5
        titleLeadingConstraint.isActive = true
    }

    private func layoutTitleLabel() {
        NSLayoutConstraint.activate([
            titleLeadingConstraint,
            labelTitle.trailingAnchor.constraint(equalTo: unPinCloseButton
                                                    .leadingAnchor, constant: -20),
            labelTitle.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            labelTitle.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    private func layoutMessageLabel() {
        NSLayoutConstraint.activate([
            labelMessage.leadingAnchor.constraint(equalTo: labelTitle.leadingAnchor),
            labelMessage.trailingAnchor.constraint(equalTo: labelTitle.trailingAnchor),
            labelMessage.topAnchor
                .constraint(equalTo: labelTitle.bottomAnchor, constant: 0),
            labelMessage.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    private func layoutCloseButton() {
        NSLayoutConstraint.activate([
            unPinCloseButton.trailingAnchor
                .constraint(equalTo: trailingAnchor, constant: -20),
            unPinCloseButton.centerYAnchor
                .constraint(equalTo: centerYAnchor, constant: 0),
            unPinCloseButton.widthAnchor.constraint(equalToConstant: 35),
            unPinCloseButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }

    // MARK: - Setup Content
    private func setupIndicatorView() {
        indicatorView.backgroundColor = Appearance.default.colorPalette.themeBlue
    }

    private func setupTitle() {
        let msgNo = currentMessageIndex > 0 ? "#\(currentMessageIndex)" : ""
        labelTitle.text = "Pinned Message \(msgNo)"
        labelTitle.textColor = Appearance.default.colorPalette.themeBlue
        labelTitle.font = UIFont.systemFont(ofSize: 17)
    }

    private func setupCloseButton() {
        unPinCloseButton.setImage(Appearance.default.images.closeBold, for: .normal)
        unPinCloseButton.tintColor = .white
        unPinCloseButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
    }

    private func setupMessage() {
        setupTitle()
        labelMessage.numberOfLines = 1
        guard pinMessages.indices.contains(currentMessageIndex) else {
            return
        }
        labelTitle.alpha = 0.3
        labelMessage.alpha = 0.3
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.labelTitle.alpha = 1.0
            weakSelf.labelMessage.alpha = 1.0
            weakSelf.layoutIfNeeded()
        }
        let message = pinMessages[currentMessageIndex]
        labelMessage.text = message.text
        // attachment
        attachmentView.subviews.forEach { $0.removeFromSuperview() }
        if let attachment = message.imageAttachments.first {
            layoutAttachmentView(isVisible: true)
            addImageAttachment(imageURL: attachment.imageURL)
            labelMessage.text = "Image"
        } else if let attachment = message.videoAttachments.first {
            layoutAttachmentView(isVisible: true)
            addVideoAttachment(videoURL: attachment.videoURL)
            labelMessage.text = "Video"
        } else {
            layoutAttachmentView(isVisible: false)
        }
    }

    private func addImageAttachment(imageURL: URL?) {
        let preview = Components().imageAttachmentComposerPreview.init()
            .withoutAutoresizingMaskConstraints
        preview.content = imageURL
        preview.layer.cornerRadius = 0
        attachmentView.addSubview(preview)
        NSLayoutConstraint.activate([
            preview.leadingAnchor
                .constraint(equalTo: attachmentView.leadingAnchor, constant: 5),
            preview.trailingAnchor
                .constraint(equalTo: attachmentView.trailingAnchor, constant: 0),
            preview.heightAnchor.constraint(equalTo: attachmentView.heightAnchor),
            preview.widthAnchor.constraint(equalTo: attachmentView.widthAnchor),
            preview.topAnchor
                .constraint(equalTo: attachmentView.topAnchor, constant: 0),
            preview.bottomAnchor
                .constraint(equalTo: attachmentView.bottomAnchor, constant: 0),
        ])
    }

    private func addVideoAttachment(videoURL: URL?) {
        let preview = Components().videoAttachmentComposerPreview.init()
            .withoutAutoresizingMaskConstraints
        preview.content = videoURL
        preview.layer.cornerRadius = 0
        attachmentView.addSubview(preview)
        NSLayoutConstraint.activate([
            preview.leadingAnchor
                .constraint(equalTo: attachmentView.leadingAnchor, constant: 0),
            preview.trailingAnchor
                .constraint(equalTo: attachmentView.trailingAnchor, constant: 0),
            preview.heightAnchor.constraint(equalTo: attachmentView.heightAnchor),
            preview.widthAnchor.constraint(equalTo: attachmentView.widthAnchor),
            preview.topAnchor
                .constraint(equalTo: attachmentView.topAnchor, constant: 0),
            preview.bottomAnchor
                .constraint(equalTo: attachmentView.bottomAnchor, constant: 0),
        ])
    }

    // MARK: - Actions
    @objc private func tapGestureAction(_ sender: UITapGestureRecognizer) {
        if currentMessageIndex < pinMessages.count - 1 {
            currentMessageIndex += 1
        } else {
            currentMessageIndex = 0
        }
        setupMessage()
        guard pinMessages.indices.contains(currentMessageIndex) else {
            return
        }
        callbackMessageDidSelect?(pinMessages[currentMessageIndex])
    }

    @objc private func didSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .up:
            if currentMessageIndex < pinMessages.count - 1 {
                currentMessageIndex += 1
            }
        case .down:
            if currentMessageIndex > pinMessages.count - 1 {
                currentMessageIndex -= 1
            }
        default:
            break
        }
        setupMessage()
        callbackMessageDidSelect?(pinMessages[currentMessageIndex])
    }

    @objc private func closeButtonAction() {
        guard pinMessages.indices.contains(currentMessageIndex) else {
            return
        }
        callbackCloseButton?(pinMessages[currentMessageIndex])
    }
}
