//
//  PinMessageCollectionViewCell.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 01/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class PinMessageCollectionViewCell: UICollectionViewCell {
    public static let nib: UINib = UINib
        .init(nibName: "PinMessageCollectionViewCell", bundle: nil)

    // MARK: - Outlets
    @IBOutlet open weak var lableMessage: UILabel!

    // MARK: - Outlets
    open override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
