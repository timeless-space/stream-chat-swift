//
//  PickerTableViewCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import StreamChat
import Nuke
import Lottie

class PickerTableViewCell: UITableViewCell {
    //MARK: Outlets
    @IBOutlet private weak var lblPackName: UILabel!
    @IBOutlet private weak var lblArtistName: UILabel!
    @IBOutlet private weak var imgPack: UIImageView!
    @IBOutlet private weak var btnDownload: UIButton!
    private var animationView: AnimationView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
         setUp()
    }

    func setUp() {
        animationView = .init(url: URL(string: "https://res.cloudinary.com/timeless/raw/upload/app/Wallet/Stickers/Shark/shark-animated-at-tgsticker-sticker-0.json")!, closure: { error in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.animationView.play()
            }
        })
        animationView.frame = self.contentView.bounds
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        self.contentView.addSubview(animationView!)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        animationView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        animationView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        animationView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        animationView.play()
    }

    func configure(with package: PackageList, downloadedPackage: [Int]) {
        lblPackName.text = package.packageName ?? ""
        lblArtistName.text = package.artistName ?? ""
        Nuke.loadImage(with: URL(string: package.packageImg ?? ""), into: imgPack)
        selectionStyle = .none
        if !downloadedPackage.contains(package.packageID ?? 0) {
            btnDownload.setImage(Appearance.default.images.downloadSticker, for: .normal)
        } else {
            btnDownload.setImage(Appearance.default.images.downloadStickerFill, for: .normal)
        }
    }
}
