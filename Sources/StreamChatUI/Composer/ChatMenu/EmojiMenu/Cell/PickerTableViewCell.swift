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
            contentView.alpha = package.isHidden ? 0.5 : 1.0
            layoutIfNeeded()
        } else {
            btnDownload.isUserInteractionEnabled = true
            btnDownload.isHidden = false
            contentView.alpha = 1.0
        }
        btnDownload.setImage(
            package.isDownload != "Y" ?
            Appearance.default.images.downloadSticker :
            Appearance.default.images.downloadStickerFill,
            for: .normal)
    }
}
