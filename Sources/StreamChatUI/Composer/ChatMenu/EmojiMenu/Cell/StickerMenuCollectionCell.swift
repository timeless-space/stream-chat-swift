//
//  StickerMenuCollectionCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 01/04/22.
//

import Foundation
import StreamChat

class StickerMenuCollectionCell: UICollectionViewCell {

    //MARK: Outlets
    @IBOutlet private weak var imgMenu: UIImageView!
    @IBOutlet private weak var bgView: UIView!

    private var imageLoader = Components.default.imageLoader

    func configureMenu(menu: StickerMenu, selectedId: Int) {
        if menu.menuId == -1 {
            imgMenu.image = (selectedId == -1 ? Appearance.default.images.clock : Appearance.default.images.clock?.noir)
        } else if menu.menuId == -2 {
            imgMenu.image = (selectedId == -2 ? Appearance.default.images.gif : Appearance.default.images.gif.noir)
        } else {
            guard let imgUrl = URL(string: menu.image ?? "") else {
                imgMenu.image = nil
                return
            }
            imageLoader.loadImage(
                using: .init(url: imgUrl),
                cachingKey: menu.image) { result in
                    switch result {
                    case .success(let imageResult):
                        self.imgMenu.image = (menu.menuId == selectedId) ? imageResult : imageResult.noir
                    case .failure:
                        self.imgMenu.image = nil
                    }
                }
        }
        imgMenu.tintColor = .init(rgb: 0x343434)
        imgMenu.contentMode = .scaleAspectFill
        imgMenu.alpha = (menu.menuId == selectedId) ? 1 : 1
        bgView.backgroundColor = (menu.menuId == selectedId) ? .init(rgb: 0x0E0E0E) : .clear
        bgView.cornerRadius = bgView.bounds.width / 2
        imgMenu.cornerRadius = imgMenu.bounds.width / 2
    }
}
