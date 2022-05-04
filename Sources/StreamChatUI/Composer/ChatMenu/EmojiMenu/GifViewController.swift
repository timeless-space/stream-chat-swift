//
//  EmojiMainViewController.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 26/04/22.
//

import UIKit
import GiphyUISDK
import Combine

@available(iOS 13.0, *)
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

    open private (set) lazy var vStack = UIStackView
        .init()
        .withoutAutoresizingMaskConstraints

    open private (set) lazy var bottomView = UIView
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
    @Published var searchingText: String = ""
    private var listenCancellables = Set<AnyCancellable>()
    private var isFetchingApiData = false

    init(with isSearchEnable: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.isSearchEnable = isSearchEnable
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGifView()
        setUpProgressView()
        getTrendingGifs()
        setUpDebouncer()
    }

    deinit {
        GPHCache.shared.clear()
    }

    private func setUpDebouncer() {
        $searchingText
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .subscribe(on: RunLoop.main)
            .sink { [weak self] result in
                guard let `self` = self else { return }
                if result == "" {
                    return
                }
                self.isSearchActive = true
                self.currentSearchText = result
                self.getSearchGifs(isSearch: true)
            }
            .store(in: &listenCancellables)
    }

    private func setUpGifView() {
        view.backgroundColor = Appearance.default.colorPalette.emojiBg
        view.insertSubview(gifView, at: 0)
        gifView.backgroundColor = Appearance.default.colorPalette.stickerBg
        gifView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        gifView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        gifView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        gifView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        gifView.addSubview(hStack)
        setUpBackButton()
        hStack.pin(anchors: [.top, .trailing], to: gifView)
        hStack.leadingAnchor.constraint(equalTo: gifView.leadingAnchor, constant: 10).isActive = true
        setUpWithCollectionView()
        // set to 50 mb
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
        vStack.axis = .vertical
        pagingProgressView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        // Collection View layout
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
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
        // Setup our Vertical stack
        vStack.addArrangedSubview(collectionView)
        vStack.addArrangedSubview(pagingProgressView)
        vStack.addArrangedSubview(bottomView)
        // Add subview
        view.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.leftAnchor.constraint(equalTo: gifView.safeLeftAnchor),
            vStack.rightAnchor.constraint(equalTo: gifView.safeRightAnchor),
            vStack.topAnchor.constraint(equalTo: searchView.bottomAnchor),
            vStack.bottomAnchor.constraint(equalTo: gifView.bottomAnchor)
        ])
        pagingProgressView.color = .white
        pagingProgressView.translatesAutoresizingMaskIntoConstraints = false
        pagingProgressView.startAnimating()
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
        if (isSearchEnable) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let `self` = self else { return }
                self.searchView.becomeFirstResponder()
            }
        }
        hStack.addArrangedSubview(backButton)
        hStack.addArrangedSubview(searchView)
    }

    private func getTrendingGifs(isPaginated: Bool = false) {
        progressView.isHidden = trendingGifs.count != 0
        isFetchingApiData = true
        pagingProgressView.isHidden = trendingGifs.count == 0
        bottomView.isHidden = trendingGifs.count == 0
        apiHandler.getTrending(offset: currentTrendingOffset) { [weak self] error, response in
            guard let `self` = self else { return }
            self.isFetchingApiData = false
            self.progressView.isHidden = true
            self.pagingProgressView.isHidden = true
            self.bottomView.isHidden = true
            self.searchGifs.removeAll()
            self.currentSearchOffset = 0
            self.trendingGifs.append(contentsOf: response?.data ?? [])
            self.latestTrendingResponse = response
            self.collectionView?.reloadData()
        }
    }

    private func getSearchGifs(isSearch: Bool) {
        collectionView?.alpha = isSearch ? 0.0 : 1.0
        progressView.isHidden = !isSearch
        isFetchingApiData = true
        pagingProgressView.isHidden = isSearch
        bottomView.isHidden = isSearch
        apiHandler.getSearch(searchTerm: currentSearchText, offset: currentSearchOffset, completion: { [weak self] error, response in
            guard let `self` = self else { return }
            self.isFetchingApiData = false
            if isSearch {
                self.searchGifs.removeAll()
                self.searchGifs.append(contentsOf: response?.data ?? [])
            } else {
                self.searchGifs.append(contentsOf: response?.data ?? [])
            }
            self.pagingProgressView.isHidden = true
            self.bottomView.isHidden = true
            self.latestSearchResponse = response
            self.progressView.isHidden = true
            self.trendingGifs.removeAll()
            self.currentTrendingOffset = 0
            self.collectionView?.alpha = 1.0
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
            searchingText = searchText
        } else {
            isSearchActive = false
            getTrendingGifs()
        }
    }
}

@available(iOS 13.0, *)
extension GifViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if isFetchingApiData {
            return
        }
        if (isSearchActive ? indexPath.row == searchGifs.count - 1 : indexPath.row == trendingGifs.count - 1) {
            if isSearchActive {
                if searchGifs.count < (latestSearchResponse?.pagination.totalCount ?? 0) {
                    currentSearchOffset = searchGifs.count
                    getSearchGifs(isSearch: false)
                }
            } else {
                if trendingGifs.count < (latestTrendingResponse?.pagination.totalCount ?? 0) {
                    currentTrendingOffset = trendingGifs.count
                    getTrendingGifs(isPaginated: true)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedGif = isSearchActive ? searchGifs[indexPath.row] : trendingGifs[indexPath.row]
        dismiss(animated: true)
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl":  selectedGif.images.fixedWidthDownsampled.url])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let currentCell = cell as? GiphyCell else { return }
        currentCell.clearData()
    }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
extension GifViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 2, height: 125)
    }
}
