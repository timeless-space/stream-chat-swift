//
//  EmojiMainViewController.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 26/04/22.
//

import UIKit
import GiphyUISDK

class EmojiMainViewController: UIViewController {

    open private(set) lazy var giphy = GiphyGridController
        .init()

    open private(set) lazy var searchView = UISearchBar
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var backButton = UIButton
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var hStack = UIStackView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var gifView = UIView
        .init()
        .withoutAutoresizingMaskConstraints

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGifLayout()
        view.backgroundColor = .black
    }

    private func setupGifLayout() {
        view.insertSubview(gifView, at: 0)
        gifView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gifView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        gifView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gifView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        giphy.clipsPreviewRenditionType = .preview
        addChild(giphy)
        gifView.addSubview(giphy.view)
        searchView.placeholder = "Search Gif"
        gifView.addSubview(hStack)
        hStack.pin(anchors: [.top, .trailing], to: gifView)
        hStack.leadingAnchor.constraint(equalTo: gifView.leadingAnchor, constant: 15).isActive = true
        setUpBackButton()
        searchView.searchBarStyle = .prominent
        searchView.delegate = self
        giphy.view.translatesAutoresizingMaskIntoConstraints = false
        giphy.view.leftAnchor.constraint(equalTo: gifView.safeLeftAnchor).isActive = true
        giphy.view.rightAnchor.constraint(equalTo: gifView.safeRightAnchor).isActive = true
        giphy.view.topAnchor.constraint(equalTo: searchView.bottomAnchor).isActive = true
        giphy.view.bottomAnchor.constraint(equalTo: gifView.safeBottomAnchor).isActive = true
        giphy.didMove(toParent: self)
        let trendingGIFs = GPHContent.trending(mediaType: .gif)
        giphy.content = trendingGIFs
        giphy.delegate = self
        giphy.update()
    }

    private func setUpBackButton() {
        hStack.axis = .horizontal
        hStack.distribution = .fill
        hStack.spacing = 10
        backButton.setImage(UIImage(named: "closeSmall"), for: .normal)
        backButton.addTarget(self, action: #selector(btnBackPressed), for: .touchUpInside)
        hStack.addArrangedSubview(backButton)
        hStack.addArrangedSubview(searchView)
    }

    @objc func btnBackPressed(sender: UIButton!) {
        dismiss(animated: true, completion: nil)
    }

}

@available(iOS 13.0, *)
extension EmojiMainViewController: GPHGridDelegate {
    func contentDidUpdate(resultCount: Int, error: Error?) { }

    func didSelectMedia(media: GPHMedia, cell: UICollectionViewCell) {
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl": media.url(rendition: .downsized, fileType: .gif)])
    }

    func didSelectMoreByYou(query: String) { }

    func didScroll(offset: CGFloat) { }
}

@available(iOS 13.0, *)
extension EmojiMainViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
}

@available(iOS 13.0, *)
extension EmojiMainViewController: GiphyDelegate {
    func didDismiss(controller: GiphyViewController?) { }

    func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
        giphyViewController.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl": media.url(rendition: .downsized, fileType: .gif)])
    }
}
