//
//  PickerTableViewCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import StreamChat

class PickerTableViewCell: UITableViewCell {
    //MARK: Outlets
    @IBOutlet private weak var lblPackName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    @IBOutlet private weak var imgPack: UIImageView!
    @IBOutlet private weak var btnDownload: UIButton!

    let imageLoader = Components.default.imageLoader

    func configure(with package: PackageList, downloadedPackage: [Int]) {
        lblPackName.text = package.packageName ?? ""
        lblArtistName.text = package.artistName ?? ""
        //Nuke.loadImage(with: URL(string: package.packageImg ?? ""), into: imgPack)
        guard let imgUrl = URL(string: package.packageImg ?? "") else {
            imgPack.image = nil
            return
        }
        imageLoader.loadImage(
            using: .init(url: imgUrl),
            cachingKey: package.packageImg) { result in
                switch result {
                case .success(let imageResult):
                    self.imgPack.image = imageResult
                case .failure:
                    self.imgPack.image = nil
                }
            }
        selectionStyle = .none
        if !downloadedPackage.contains(package.packageID ?? 0) {
            btnDownload.setImage(Appearance.default.images.downloadSticker, for: .normal)
        } else {
            btnDownload.setImage(Appearance.default.images.downloadStickerFill, for: .normal)
        }
    }
}
