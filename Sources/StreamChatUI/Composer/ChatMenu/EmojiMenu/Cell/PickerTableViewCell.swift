//
//  PickerTableViewCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import StreamChat

protocol DownloadStickerDelegate: class {
    func onClickOfDownload(indexPath: IndexPath)
}

@available(iOS 13.0, *)
class PickerTableViewCell: UITableViewCell {

    //MARK: Outlets
    @IBOutlet private weak var lblPackName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    @IBOutlet private weak var imgPack: UIImageView!
    @IBOutlet private weak var btnDownload: UIButton!
    weak var delegate: DownloadStickerDelegate?
    var indexPath: IndexPath = IndexPath(row: 0, section: 0)
    let imageLoader = Components.default.imageLoader

    func configure(with package: PackageList, downloadedPackage: [Int], screenType: Int, indexPath: IndexPath) {
        self.indexPath = indexPath
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
        btnDownload.isEnabled = screenType != EmojiPickerViewController.ScreenType.MySticker.rawValue
        btnDownload.addTarget(self, action: #selector(btnDownloadAction), for: .touchUpInside)
        if screenType == EmojiPickerViewController.ScreenType.MySticker.rawValue {
            btnDownload.isHidden = true
            contentView.alpha = package.isHidden ? 0.5 : 1.0
        } else {
            btnDownload.isHidden = false
            contentView.alpha = 1.0
        }
        btnDownload.isEnabled = package.isDownload != "Y"
        btnDownload.setImage(
            package.isDownload != "Y" ?
            Appearance.default.images.downloadSticker :
            Appearance.default.images.downloadStickerFill,
            for: .normal)
    }

    @objc private func btnDownloadAction() {
        btnDownload.isEnabled = false
        delegate?.onClickOfDownload(indexPath: indexPath)
    }
}
