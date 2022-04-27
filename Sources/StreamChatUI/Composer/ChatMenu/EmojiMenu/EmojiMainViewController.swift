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

    private var gifs:[GiphyModelItem] = []

    private var collectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: CGRect(x: 5, y: 0, width: 400, height: 40), collectionViewLayout: layout)
        getTrendingGifs()
//         setupGifLayout()
        setUpWithCollectionView()
        view.backgroundColor = Appearance.default.colorPalette.stickerBg
    }

    /// Setup Collection View in feed view
    func setUpWithCollectionView() {
        view.insertSubview(gifView, at: 0)
        gifView.backgroundColor = Appearance.default.colorPalette.stickerBg
        gifView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gifView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        gifView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gifView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        gifView.addSubview(hStack)
        hStack.pin(anchors: [.top, .trailing], to: gifView)
        hStack.leadingAnchor.constraint(equalTo: gifView.leadingAnchor, constant: 15).isActive = true
        setUpBackButton()
        guard let collectionView = collectionView else {
            return
        }

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GiphyCell.self, forCellWithReuseIdentifier: "cellIdentifier")
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: gifView.safeLeftAnchor),
            collectionView.rightAnchor.constraint(equalTo: gifView.safeRightAnchor),
            collectionView.topAnchor.constraint(equalTo: searchView.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: gifView.safeBottomAnchor)
        ])
    }

    private func getTrendingGifs() {
        // AppConstant.giphyAPIKey
        var apiHandler = SwiftyGiphyAPI.shared
//        apiHandler.apiKey = AppConstant.giphyAPIKey
        apiHandler.getTrending { error, response in
            print(response)
        }
    }

    private func setupGifLayout() {
        view.insertSubview(gifView, at: 0)
        gifView.backgroundColor = Appearance.default.colorPalette.stickerBg
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
        giphy.theme = CustomTheme()
        giphy.update()
    }

    private func setUpBackButton() {
        hStack.axis = .horizontal
        hStack.distribution = .fill
        hStack.spacing = 10
        backButton.setImage(UIImage(named: "closeSmall"), for: .normal)
        backButton.addTarget(self, action: #selector(btnBackPressed), for: .touchUpInside)
        searchView.backgroundColor = Appearance.default.colorPalette.stickerBg
        searchView.backgroundImage = UIImage()
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
        dismiss(animated: true)
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl": media.url(rendition: .downsized, fileType: .gif)])
    }

    func didSelectMoreByYou(query: String) { }

    func didScroll(offset: CGFloat) {
        view.endEditing(true)
    }
}

@available(iOS 13.0, *)
extension EmojiMainViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            debugPrint("Search started")
            giphy.content = GPHContent.search(withQuery: searchBar.text ?? "", mediaType: .gif, language: .english)
            giphy.update()
        } else {
            giphy.content = GPHContent.trending(mediaType: .gif)
            giphy.update()
        }
    }
}

extension EmojiMainViewController: UICollectionViewDelegate {

}

extension EmojiMainViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdentifier", for: indexPath) as? GiphyCell else { return UICollectionViewCell() }
        cell.configureCell(giphyModel: gifs[indexPath.row])
        return cell
    }

}

extension EmojiMainViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 2, height: 100)
    }

}

public class CustomTheme: GPHTheme {
    public override init() {
        super.init()
        self.type = .light
    }

    public override var backgroundColorForLoadingCells: UIColor {
        return Appearance.default.colorPalette.stickerBg
    }
}
