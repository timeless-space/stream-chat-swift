//
//  EmojiMainViewController.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 26/04/22.
//

import UIKit
import GiphyUISDK

class EmojiMainViewController: UIViewController {

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

    open private(set) lazy var progressView = UIActivityIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var pagingProgressView = UIActivityIndicatorView
        .init()
        .withoutAutoresizingMaskConstraints

    private var trendingGifs:[GiphyModelItem] = []
    private var searchGifs:[GiphyModelItem] = []
    private var latestTrendingResponse: GiphyResponse?
    private var latestSearchResponse: GiphyResponse?
    private var collectionView: UICollectionView?
    private var currentTrendingOffset = 0
    private var currentSearchOffset = 0
    private var apiHandler = SwiftyGiphyAPI.shared
    private var isSearchActive = false
    private var currentSearchText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        getTrendingGifs()
        setUpGifView()
        setUpProgressView()
        view.backgroundColor = Appearance.default.colorPalette.stickerBg
    }

    deinit {
        debugPrint("Deinit called")
    }

    private func setUpGifView() {
        view.insertSubview(gifView, at: 0)
        gifView.backgroundColor = Appearance.default.colorPalette.stickerBg
        gifView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gifView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        gifView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gifView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        gifView.addSubview(hStack)
        setUpBackButton()
        hStack.pin(anchors: [.top, .trailing], to: gifView)
        hStack.leadingAnchor.constraint(equalTo: gifView.leadingAnchor, constant: 15).isActive = true
        setUpWithCollectionView()
        // set to 300 mb
        GPHCache.shared.cache.diskCapacity = 300 * 1000 * 1000
        GPHCache.shared.cache.memoryCapacity = 100 * 1000 * 1000
    }

    private func setUpProgressView() {
        progressView.color = .white
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.startAnimating()
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    /// Setup Collection View in feed view
    func setUpWithCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        guard let collectionView = collectionView else {
            return
        }
        collectionView.autoresizesSubviews = false
        collectionView.register(GiphyCell.self, forCellWithReuseIdentifier: "cellIdentifier")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: gifView.safeLeftAnchor),
            collectionView.rightAnchor.constraint(equalTo: gifView.safeRightAnchor),
            collectionView.topAnchor.constraint(equalTo: searchView.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: gifView.safeBottomAnchor)
        ])
        pagingProgressView.color = .white
        pagingProgressView.translatesAutoresizingMaskIntoConstraints = false
        pagingProgressView.startAnimating()
        pagingProgressView.isHidden = true
        gifView.addSubview(pagingProgressView)
        NSLayoutConstraint.activate([
            pagingProgressView.centerXAnchor.constraint(equalTo: gifView.centerXAnchor),
            pagingProgressView.bottomAnchor.constraint(equalTo: gifView.bottomAnchor)
        ])
    }

    private func setUpBackButton() {
        hStack.axis = .horizontal
        hStack.distribution = .fill
        hStack.spacing = 10
        backButton.setImage(UIImage(named: "closeSmall"), for: .normal)
        backButton.addTarget(self, action: #selector(btnBackPressed), for: .touchUpInside)
        searchView.backgroundColor = Appearance.default.colorPalette.stickerBg
        searchView.backgroundImage = UIImage()
        searchView.delegate = self
        hStack.addArrangedSubview(backButton)
        hStack.addArrangedSubview(searchView)
    }

    private func getTrendingGifs() {
        progressView.isHidden = trendingGifs.count != 0
        apiHandler.getTrending(offset: currentTrendingOffset) { [weak self] error, response in
            guard let `self` = self else { return }
            self.progressView.isHidden = true
            self.trendingGifs.append(contentsOf: response?.data ?? [])
            self.latestTrendingResponse = response
            self.pagingProgressView.isHidden = true
            self.collectionView?.reloadData()
        }
    }

    private func getSearchGifs(isSearch: Bool) {
        apiHandler.getSearch(searchTerm: currentSearchText, offset: currentSearchOffset, completion: { [weak self] error, response in
            guard let `self` = self else { return }
            if isSearch {
                self.searchGifs.removeAll()
                self.searchGifs.append(contentsOf: response?.data ?? [])
            } else {
                self.searchGifs.append(contentsOf: response?.data ?? [])
            }
            self.pagingProgressView.isHidden = true
            self.latestSearchResponse = response
            self.progressView.isHidden = true
            debugPrint("Search Response received")
            self.collectionView?.reloadData()
        })
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
            isSearchActive = true
            debugPrint("Search started")
            currentSearchText = searchText
            getSearchGifs(isSearch: true)
        } else {
            isSearchActive = false
            getTrendingGifs()
        }
    }
}

extension EmojiMainViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == trendingGifs.count - 1 {
            if isSearchActive {
                if searchGifs.count < (latestSearchResponse?.pagination.totalCount ?? 0) {
                    currentSearchOffset = searchGifs.count
                    getSearchGifs(isSearch: false)
                    pagingProgressView.isHidden = false
                }
            } else {
                if trendingGifs.count < (latestTrendingResponse?.pagination.totalCount ?? 0) {
                    currentTrendingOffset = trendingGifs.count
                    getTrendingGifs()
                    pagingProgressView.isHidden = false
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedGif = isSearchActive ? searchGifs[indexPath.row] : trendingGifs[indexPath.row]
        dismiss(animated: true)
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl":  selectedGif.images.downsized.url])
    }

}

extension EmojiMainViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearchActive ? searchGifs.count : trendingGifs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdentifier", for: indexPath) as? GiphyCell else { return UICollectionViewCell() }
        cell.configureFor(giphyModel: isSearchActive ? searchGifs[indexPath.row] : trendingGifs[indexPath.row])
        return cell
    }

//    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        guard let cell = cell as? GiphyCell else {
//            return
//        }
//        cell.
//    }

}

extension EmojiMainViewController: UICollectionViewDelegateFlowLayout {

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: collectionView.frame.size.width / 2, height: 200)
//    }

}
