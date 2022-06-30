//
//  TimestampContainerView.swift
//  StreamChatUI
//
//  Created by Jitendra Sharma on 30/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public class TimestampContainerView: _View {
    // MARK: - Variables
    public private(set) var timestampLabel: UILabel?
    public private(set) var authorNameLabel: UILabel?

    // MARK: - SetUp & Layout
    public override func setUp() {
        super.setUp()
        transform = .mirrorY
    }

    public func createTimestampLabel() {
        timestampLabel = UILabel()
            .withAdjustingFontForContentSizeCategory
            .withBidirectionalLanguagesSupport
            .withoutAutoresizingMaskConstraints

        timestampLabel?.textColor = Appearance.default.colorPalette.subtitleText
        timestampLabel?.font = Appearance.default.fonts.footnote

        layoutTimestampLabel()
    }

    public func createAuthorLabel() {
        authorNameLabel = UILabel()
            .withAdjustingFontForContentSizeCategory
            .withBidirectionalLanguagesSupport
            .withoutAutoresizingMaskConstraints

        authorNameLabel?.textColor = Appearance.default.colorPalette.subtitleText
        authorNameLabel?.font = Appearance.default.fonts.footnote

        layoutAuthorLabel()
    }

    private func layoutAuthorLabel() {
        guard let authorName = authorNameLabel else { return }
        addSubview(authorName)
        NSLayoutConstraint.activate([
            authorName.leadingAnchor.constraint(equalTo: leadingAnchor),
            authorName.topAnchor.constraint(equalTo: topAnchor),
            authorName.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        authorNameLabel?.setContentCompressionResistancePriority(.streamLow, for: .horizontal)
    }

    private func layoutTimestampLabel() {
        guard let timestamp = timestampLabel else { return }
        addSubview(timestamp)
        let timestampLeading = authorNameLabel?.trailingAnchor ?? leadingAnchor
        let space: CGFloat = authorNameLabel == nil ? 0 : 8
        NSLayoutConstraint.activate([
            timestamp.leadingAnchor.constraint(equalTo: timestampLeading, constant: space),
            timestamp.topAnchor.constraint(equalTo: topAnchor),
            timestamp.bottomAnchor.constraint(equalTo: bottomAnchor),
            timestamp.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        timestampLabel?.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
        let authorTrailing = timestampLabel?.leadingAnchor ?? trailingAnchor
        authorNameLabel?.trailingAnchor.constraint(equalTo: authorTrailing)
    }
}
