//
//  NoContactsAvailableCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 09/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class NoContactsAvailableCell: UITableViewCell {
    // MARK: - Variables
    static let reuseID = "NoContactsAvailableCell"
    // MARK: - Life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
}
