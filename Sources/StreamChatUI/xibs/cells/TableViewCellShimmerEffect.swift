//
//  TableViewCellShimmerEffect.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 15/04/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import SkeletonView

class TableViewCellShimmerEffect: UITableViewCell {
    public static let nib: UINib = UINib.init(nibName: identifier, bundle: nil)

    // MARK: - Outlets
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lableTilte: UILabel!
    @IBOutlet weak var lableSubTilte: UILabel!

    // MARK: - view life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
        imgView.layer.cornerRadius = imgView.bounds.height / 2
        imgView.isSkeletonable = true
        lableTilte.isSkeletonable = true
        lableSubTilte.isSkeletonable = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    //MARK: - Shimmer
    public func showShimmer() {
        imgView.image = UIImage()
        imgView.backgroundColor = .clear
        imgView.showAnimatedGradientSkeleton()
        lableTilte.showAnimatedGradientSkeleton()
        lableSubTilte.showAnimatedGradientSkeleton()
    }

    public func hideShimmer() {
        imgView.hideSkeleton()
        lableTilte.hideSkeleton()
        lableSubTilte.hideSkeleton()
    }
}
