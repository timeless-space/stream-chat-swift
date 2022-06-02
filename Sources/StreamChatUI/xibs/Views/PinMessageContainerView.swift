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
    private lazy var pinMessages = [ChatMessage]()
    private var currentMessageIndex = 0

    // Callback
    public var callbackMessageDidSelect:((ChatMessage) -> Void)?
    public var callbackCloseButton:((ChatMessage) -> Void)?

    // MARK: - UI
    public func setupUI(pinMessages: [ChatMessage]) {
        self.pinMessages = pinMessages
        subviews.forEach { $0.removeFromSuperview() }
        // subview
        addSubview(indicatorView)
        addSubview(labelTitle)
        addSubview(labelMessage)
        addSubview(unPinCloseButton)
        // layout view
        layoutIndicatorView()
        layoutTitleLabel()
        layoutMessageLabel()
        layoutCloseButton()
        // setup content
        setupIndicatorView()
        setupTitle()
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

    private func layoutTitleLabel() {
        NSLayoutConstraint.activate([
            labelTitle.leadingAnchor
                .constraint(equalTo: indicatorView.trailingAnchor, constant: 10),
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
        labelTitle.text = "Pinned Message"
        labelTitle.textColor = Appearance.default.colorPalette.themeBlue
        labelTitle.font = UIFont.systemFont(ofSize: 17)
    }

    private func setupCloseButton() {
        unPinCloseButton.setImage(Appearance.default.images.closeBold, for: .normal)
        unPinCloseButton.tintColor = .white
        unPinCloseButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
    }

    private func setupMessage() {
        labelMessage.numberOfLines = 1
        guard pinMessages.indices.contains(currentMessageIndex) else {
            return
        }
        labelTitle.alpha = 0.3
        labelMessage.alpha = 0.3
        layoutIfNeeded()
        UIView.animate(withDuration: 0.2) {
            self.labelTitle.alpha = 1.0
            self.labelMessage.alpha = 1.0
        }
        let message = pinMessages[currentMessageIndex]
        labelMessage.text = message.text
        callbackMessageDidSelect?(message)
    }

    // MARK: - Actions
    @objc private func tapGestureAction(_ sender: UITapGestureRecognizer) {
        if currentMessageIndex < pinMessages.count - 1 {
            currentMessageIndex += 1
        } else {
            currentMessageIndex = 0
        }
        setupMessage()
    }

    @objc private func didSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .up:
            if currentMessageIndex < pinMessages.count - 1 {
                currentMessageIndex += 1
                setupMessage()
            }
        case .down:
            if currentMessageIndex > pinMessages.count - 1 {
                currentMessageIndex -= 1
                setupMessage()
            }
        default:
            break
        }
    }

    @objc private func closeButtonAction() {
        guard pinMessages.indices.contains(currentMessageIndex) else {
            return
        }
        callbackCloseButton?(pinMessages[currentMessageIndex])
    }
}
