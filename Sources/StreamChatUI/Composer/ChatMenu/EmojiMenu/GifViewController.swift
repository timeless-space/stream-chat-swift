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

    open private (set) lazy var errorLabel = UILabel
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
    private var listenCancellables = Set<AnyCancellable>()
    private var isFetchingApiData = false
    @Published private var searchingText: String = ""

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
        getTrendingGifs(isPaginated: false)
        setUpDebouncer()
        setUpErrorLabel()
    }

    deinit {
        GPHCache.shared.clear()
    }

    private func setUpGifView() {
        view.insertSubview(gifView, at: 0)
        gifView.backgroundColor = Appearance.default.colorPalette.stickerBg
        NSLayoutConstraint.activate([
            gifView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gifView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gifView.topAnchor.constraint(equalTo: view.topAnchor),
            gifView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        gifView.addSubview(hStack)
        setUpBackButton()
        hStack.pin(anchors: [.top, .trailing], to: gifView)
        hStack.leadingAnchor.constraint(equalTo: gifView.leadingAnchor, constant: 10).isActive = true
        setUpWithCollectionView()
        // set to 50 mb
        GPHCache.shared.cache.diskCapacity = 50 * 1000 * 1000
        GPHCache.shared.cache.memoryCapacity = 50 * 1000 * 1000
    }

    /// Setup Collection View in feed view
    private func setUpWithCollectionView() {
        vStack.axis = .vertical
        pagingProgressView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        // Collection View layout
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        guard let collectionView = collectionView else { return }
        collectionView.autoresizesSubviews = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .black
        if (isSearchEnable) {
            collectionView.keyboardDismissMode = .onDrag
        }
        collectionView.register(GiphyCollectionCell.self, forCellWithReuseIdentifier: "cellIdentifier")
        // Setup our Vertical stack
        setUpVerticalStack(collectionView: collectionView)
    }

    private func setUpVerticalStack(collectionView: UICollectionView) {
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
        bottomView.backgroundColor = .black
        setUpPagingProgressView()
    }

    private func setUpPagingProgressView() {
        pagingProgressView.color = .white
        pagingProgressView.backgroundColor = .black
        pagingProgressView.translatesAutoresizingMaskIntoConstraints = false
        pagingProgressView.startAnimating()
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

    private func setUpErrorLabel() {
        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.topAnchor.constraint(equalTo: searchView.bottomAnchor, constant: 20),
            errorLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
        errorLabel.text = "Sorry we couldn't find any gifs. Please try again later."
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.textColor = .white
        errorLabel.isHidden = true
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

    private func getTrendingGifs(isPaginated: Bool = false, scrollToTop: Bool = false) {
        progressView.isHidden = trendingGifs.count != 0
        collectionView?.alpha = isPaginated ? 1.0 : 0.0
        isFetchingApiData = true
        errorLabel.isHidden = true
        isSearchActive = false
        pagingProgressView.isHidden = trendingGifs.count == 0
        bottomView.isHidden = trendingGifs.count == 0
        apiHandler.getTrending(offset: currentTrendingOffset) { [weak self] error, response in
            guard let `self` = self else { return }
            self.errorLabel.isHidden = !(response?.data.isEmpty ?? false)
            self.progressView.isHidden = true
            if error == nil && !self.isSearchActive {
                self.updateTrendingGifView(latestTrendingResponse: response, scrollToTop: scrollToTop)
            }
        }
    }

    private func updateTrendingGifView(latestTrendingResponse: GiphyResponse?, scrollToTop: Bool) {
        guard let response = latestTrendingResponse else { return }
        isFetchingApiData = false
        progressView.isHidden = true
        pagingProgressView.isHidden = true
        collectionView?.alpha = 1.0
        self.latestTrendingResponse = response
        bottomView.isHidden = true
        if trendingGifs.isEmpty {
            trendingGifs.append(contentsOf: response.data ?? [])
            collectionView?.reloadData()
        } else {
            collectionView?.performBatchUpdates({
                let updateIndex = response.data.enumerated().compactMap { IndexPath(row: $0.offset + trendingGifs.count, section: 0)} ?? []
                let indexPath = IndexPath(row: response.data.count ?? 0 , section: 0)
                trendingGifs.append(contentsOf: response.data ?? [])
                collectionView?.insertItems(at: updateIndex)
            }, completion: nil)
        }
        searchGifs.removeAll()
        currentSearchOffset = 0
        if scrollToTop && trendingGifs.count > 0 {
            collectionView?.setContentOffset(.zero, animated: false)
        }
    }

    private func getSearchGifs(isSearch: Bool) {
        collectionView?.alpha = isSearch ? 0.0 : 1.0
        progressView.isHidden = !isSearch
        errorLabel.isHidden = true
        isFetchingApiData = true
        pagingProgressView.isHidden = isSearch
        bottomView.isHidden = isSearch
        apiHandler.getSearch(searchTerm: currentSearchText, offset: currentSearchOffset, completion: { [weak self] error, response in
            guard let `self` = self else { return }
            self.errorLabel.isHidden = !(response?.data.isEmpty ?? false)
            self.progressView.isHidden = true
            if error == nil && self.isSearchActive {
                self.updateSearchGifView(latestSearchResponse: response, isSearch: isSearch)
            }
        })
    }

    private func updateSearchGifView(latestSearchResponse: GiphyResponse?, isSearch: Bool) {
        guard let response = latestSearchResponse else { return }
        isFetchingApiData = false
        if isSearch {
            searchGifs.removeAll()
        }
        pagingProgressView.isHidden = true
        bottomView.isHidden = true
        self.latestSearchResponse = response
        progressView.isHidden = true
        collectionView?.alpha = 1.0
        if searchGifs.isEmpty {
            searchGifs.append(contentsOf: response.data ?? [])
            collectionView?.setContentOffset(.zero, animated: false)
            collectionView?.reloadData()
        } else {
            collectionView?.performBatchUpdates({
                let updateIndex = response.data.enumerated().compactMap { IndexPath(row: $0.offset + self.searchGifs.count, section: 0)} ?? []
                let indexPath = IndexPath(row: response.data.count ?? 0 , section: 0)
                searchGifs.append(contentsOf: response.data ?? [])
                collectionView?.insertItems(at: updateIndex)
            }, completion: nil)
        }
        trendingGifs.removeAll()
        currentTrendingOffset = 0
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
        searchingText = searchText
        if searchText.isEmpty {
            isSearchActive = false
            getTrendingGifs(isPaginated: false, scrollToTop: true)
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
}

@available(iOS 13.0, *)
extension GifViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearchActive ? searchGifs.count : trendingGifs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdentifier", for: indexPath) as? GiphyCollectionCell else { return UICollectionViewCell() }
        guard let indexData = isSearchActive ? searchGifs[safe: indexPath.row] : trendingGifs[safe: indexPath.row] else {
            return cell
        }
        cell.configureCell(giphyModel: indexData)
        return cell
    }
}

@available(iOS 13.0, *)
extension GifViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 2, height: 125)
    }
}
