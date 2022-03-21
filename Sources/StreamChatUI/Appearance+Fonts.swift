//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UIFont
import CoreGraphics

public extension Appearance {
    enum fontFamilyName {
        case SFProTextRegular
        case SFProTextSemiBold
        case SFCompactTextRegular
        case SFProDisplayRegular
        case SFProDisplayBold
        var getFamilyName: String {
            switch self {
            case .SFProTextRegular: return "SFProText-Regular"
            case .SFProTextSemiBold: return "SFProText-Semibold"
            case .SFCompactTextRegular: return "SFCompactText-Regular"
            case .SFProDisplayRegular: return "SFProDisplay-Regular"
            case .SFProDisplayBold: return "SFProDisplay-Bold"
            }
        }
    }
    struct Fonts {
        public var caption1 = UIFont.preferredFont(forTextStyle: .caption1)
        public var footnoteBold = UIFont.preferredFont(forTextStyle: .footnote).bold
        public var footnote = UIFont.preferredFont(forTextStyle: .footnote)
        public var subheadline = UIFont.preferredFont(forTextStyle: .subheadline)
        public var subheadlineBold = UIFont.preferredFont(forTextStyle: .subheadline).bold
        public var body = UIFont.preferredFont(forTextStyle: .body)
        public var bodyBold = UIFont.preferredFont(forTextStyle: .body).bold
        public var bodyItalic = UIFont.preferredFont(forTextStyle: .body).italic
        public var headline = UIFont.preferredFont(forTextStyle: .headline)
        public var headlineBold = UIFont.preferredFont(forTextStyle: .headline).bold
        public var title = UIFont.preferredFont(forTextStyle: .title1)
        public var emoji = UIFont.systemFont(ofSize: 50)
        public lazy var groupUserName: UIFont = {
            return getFont(fontFamily: .SFProTextRegular, size: 17)
        }()
        public lazy var chatMessage: UIFont = {
            return getFont(fontFamily: .SFProTextRegular, size: 17)
        }()
        public lazy var chatMessageTime: UIFont = {
            return getFont(fontFamily: .SFProTextRegular, size: 13)
        }()
        // Font with custom size
        public func getFont(fontFamily: fontFamilyName, size: CGFloat) -> UIFont {
            return UIFont.init(name: fontFamily.getFamilyName, size: size) ?? UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        }
    }
}
