//
//  UITableviewCell+Extensions.swift
//  StreamChatUI
//
//  Created by Jitendra Sharma on 01/04/22.
//

import Foundation

public extension UITableViewCell {
    static var identifier: String { return String(describing: self) }
    static let nib = UINib.init(nibName: identifier, bundle: nil)
}
