//
//  EmojiMainViewController.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 26/04/22.
//

import UIKit
import GiphyUISDK

class GifViewController: UIViewController {

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
    private var isSearchEnable = false

    init(with isSearchEnable: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.isSearchEnable = isSearchEnable
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getTrendingGifs()
        setUpGifView()
        setUpProgressView()
        view.backgroundColor = Appearance.default.colorPalette.stickerBg
    }

    deinit {
        GPHCache.shared.clear()
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
        GPHCache.shared.cache.diskCapacity = 50 * 1000 * 1000
        GPHCache.shared.cache.memoryCapacity = 50 * 1000 * 1000
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
        let layout = WaterFallLayout()
        layout.delegate = self
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        guard let collectionView = collectionView else {
            return
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
            pagingProgressView.topAnchor.constraint(equalTo: gifView.bottomAnchor)
        ])
    }

    private func setUpBackButton() {
        hStack.axis = .horizontal
        hStack.distribution = .fill
        hStack.spacing = 10
        backButton.setImage(UIImage(named: "closeSmall"), for: .normal)
        backButton.addTarget(self, action: #selector(btnBackPressed), for: .touchUpInside)
        backButton.isHidden = !isSearchEnable
        searchView.backgroundColor = Appearance.default.colorPalette.stickerBg
        searchView.placeholder = "Search Gifs"
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
            self.collectionView?.reloadData()
        })
    }

    @objc func btnBackPressed(sender: UIButton!) {
        dismiss(animated: true, completion: nil)
    }

}

@available(iOS 13.0, *)
extension GifViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if !isSearchEnable {
            let gifVc = GifViewController(with: true)
            UIApplication.shared.keyWindow?.rootViewController?.present(gifVc, animated: true, completion: nil)
        }
        return isSearchEnable
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            isSearchActive = true
            currentSearchText = searchText
            getSearchGifs(isSearch: true)
        } else {
            isSearchActive = false
            getTrendingGifs()
        }
    }
}

extension GifViewController: UICollectionViewDelegate {

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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

extension GifViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearchActive ? searchGifs.count : trendingGifs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdentifier", for: indexPath) as? GiphyCell else { return UICollectionViewCell() }
        cell.configureCell(giphyModel: isSearchActive ? searchGifs[indexPath.row] : trendingGifs[indexPath.row])
        return cell
    }
}

extension GifViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right)) / 2
        return CGSize(width: itemSize, height: itemSize)
    }
}

extension GifViewController: WaterFallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        let item = isSearchActive ? searchGifs[indexPath.row] : trendingGifs[indexPath.row]
        return CGFloat((item.images.fixedWidthDownsampled.height as NSString).floatValue) ?? 0.0
    }
}
