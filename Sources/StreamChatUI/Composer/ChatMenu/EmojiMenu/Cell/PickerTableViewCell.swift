//
//  PickerTableViewCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import StreamChat
import Nuke

@available(iOS 13.0, *)
class PickerTableViewCell: UITableViewCell {
    //MARK: Outlets
    @IBOutlet private weak var lblPackName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    @IBOutlet private weak var imgPack: UIImageView!
    @IBOutlet weak var btnDownload: UIButton!

    func configure(with package: PackageList, downloadedPackage: [Int], screenType: Int) {
        lblPackName.text = package.packageName ?? ""
        lblArtistName.text = package.artistName ?? ""
        Nuke.loadImage(with: URL(string: package.packageImg ?? ""), into: imgPack)
        selectionStyle = .none
        btnDownload.isHidden = screenType == EmojiPickerViewController.ScreenType.MySticker.rawValue
        btnDownload.isUserInteractionEnabled = screenType != EmojiPickerViewController.ScreenType.MySticker.rawValue

        if screenType == EmojiPickerViewController.ScreenType.MySticker.rawValue {
            btnDownload.isUserInteractionEnabled = false
            btnDownload.isHidden = true
            self.contentView.alpha = package.isHidden ? 0.5 : 1.0
            self.layoutIfNeeded()
        } else {
            btnDownload.isUserInteractionEnabled = true
            btnDownload.isHidden = false
            self.contentView.alpha = 1.0
        }

        if !downloadedPackage.contains(package.packageID ?? 0) {
            btnDownload.setImage(Appearance.default.images.downloadSticker, for: .normal)
        } else {
            btnDownload.setImage(Appearance.default.images.downloadStickerFill, for: .normal)
        }
    }
}
