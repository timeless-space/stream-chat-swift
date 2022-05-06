//
//  EmojiMainViewController.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 26/04/22.
//

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

    open private(set) lazy var headerStackView = UIStackView
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

    open private (set) lazy var contentStackView = UIStackView
        .init()
        .withoutAutoresizingMaskConstraints

    open private (set) lazy var bottomView = UIView
        .init()
        .withoutAutoresizingMaskConstraints

    open private (set) lazy var errorLabel = UILabel
        .init()
        .withoutAutoresizingMaskConstraints

    private var collectionView: UICollectionView?
    private var currentTrendingOffset = 0
    private var currentSearchOffset = 0
    private var isSearchActive = false
    private var currentSearchText = ""
    private var isSearchEnable = false
    private var listenCancellables = Set<AnyCancellable>()
    private var isFetchingApiData = false
    @Published private var searchingText: String = ""

    var viewModel: GifViewModel!

    init(with isSearchEnable: Bool, viewModel: GifViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.isSearchEnable = isSearchEnable
        self.viewModel = viewModel
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
        gifView.addSubview(headerStackView)
        setUpBackButton()
        headerStackView.pin(anchors: [.top, .trailing], to: gifView)
        headerStackView.leadingAnchor.constraint(equalTo: gifView.leadingAnchor, constant: 10).isActive = true
        setUpWithCollectionView()
        // set to 50 mb
        GPHCache.shared.cache.diskCapacity = 50 * 1000 * 1000
        GPHCache.shared.cache.memoryCapacity = 50 * 1000 * 1000
    }

    /// Setup Collection View in feed view
    private func setUpWithCollectionView() {
        contentStackView.axis = .vertical
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
        contentStackView.addArrangedSubview(collectionView)
        contentStackView.addArrangedSubview(pagingProgressView)
        contentStackView.addArrangedSubview(bottomView)
        // Add subview
        view.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.leftAnchor.constraint(equalTo: gifView.safeLeftAnchor),
            contentStackView.rightAnchor.constraint(equalTo: gifView.safeRightAnchor),
            contentStackView.topAnchor.constraint(equalTo: searchView.bottomAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: gifView.bottomAnchor)
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
        headerStackView.axis = .horizontal
        headerStackView.distribution = .fill
        headerStackView.spacing = 10
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
        headerStackView.addArrangedSubview(backButton)
        headerStackView.addArrangedSubview(searchView)
    }

    private func getTrendingGifs(isPaginated: Bool = false, scrollToTop: Bool = false) {
        progressView.isHidden = viewModel.trendingGifs.count != 0
        collectionView?.alpha = isPaginated ? 1.0 : 0.0
        isFetchingApiData = true
        errorLabel.isHidden = true
        isSearchActive = false
        pagingProgressView.isHidden = viewModel.trendingGifs.count == 0
        bottomView.isHidden = viewModel.trendingGifs.count == 0
        viewModel.getTrendingApiCalls(currentTrendingOffset: currentTrendingOffset) { [weak self] isSuccess, response in
            guard let `self` = self else { return }
            if (isSuccess) {
                if !self.isSearchActive {
                    self.updateTrendingGifView(latestTrendingResponse: response, scrollToTop: scrollToTop)
                }
                self.progressView.isHidden = true
                self.errorLabel.isHidden = !(self.viewModel.latestSearchResponse?.data.isEmpty ?? false)
            } else {
                self.errorLabel.isHidden = false
                self.progressView.isHidden = true
            }
        }
    }

    private func updateTrendingGifView(latestTrendingResponse: GiphyResponse?, scrollToTop: Bool) {
        guard let response = latestTrendingResponse else { return }
        isFetchingApiData = false
        progressView.isHidden = true
        pagingProgressView.isHidden = true
        collectionView?.alpha = 1.0
        viewModel.latestTrendingResponse = response
        bottomView.isHidden = true
        if viewModel.trendingGifs.isEmpty {
            viewModel.trendingGifs.append(contentsOf: response.data ?? [])
            collectionView?.reloadData()
        } else {
            collectionView?.performBatchUpdates({
                let updateIndex = response.data.enumerated().compactMap { IndexPath(row: $0.offset + viewModel.trendingGifs.count, section: 0)} ?? []
                let indexPath = IndexPath(row: response.data.count ?? 0 , section: 0)
                viewModel.trendingGifs.append(contentsOf: response.data ?? [])
                collectionView?.insertItems(at: updateIndex)
            }, completion: nil)
        }
        viewModel.searchGifs.removeAll()
        currentSearchOffset = 0
        if scrollToTop && viewModel.trendingGifs.count > 0 {
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

        viewModel.getSearchApiCalls(currentSearchText: currentSearchText, currentSearchOffset: currentSearchOffset) { [weak self] isSuccess, response in
            guard let `self` = self else { return }
            if isSuccess {
                if self.isSearchActive {
                    self.updateSearchGifView(latestSearchResponse: response, isSearch: isSearch)
                }
                self.progressView.isHidden = true
                self.errorLabel.isHidden = !(self.viewModel.latestSearchResponse?.data.isEmpty ?? false)
            } else {
                self.errorLabel.isHidden = false
                self.progressView.isHidden = true
            }
        }
    }

    private func updateSearchGifView(latestSearchResponse: GiphyResponse?, isSearch: Bool) {
        guard let response = latestSearchResponse else { return }
        isFetchingApiData = false
        if isSearch {
            viewModel.searchGifs.removeAll()
        }
        pagingProgressView.isHidden = true
        bottomView.isHidden = true
        viewModel.latestSearchResponse = response
        progressView.isHidden = true
        collectionView?.alpha = 1.0
        if viewModel.searchGifs.isEmpty {
            viewModel.searchGifs.append(contentsOf: response.data ?? [])
            collectionView?.setContentOffset(.zero, animated: false)
            collectionView?.reloadData()
        } else {
            collectionView?.performBatchUpdates({
                let updateIndex = response.data.enumerated().compactMap { IndexPath(row: $0.offset + viewModel.searchGifs.count, section: 0)} ?? []
                let indexPath = IndexPath(row: response.data.count ?? 0 , section: 0)
                viewModel.searchGifs.append(contentsOf: response.data ?? [])
                collectionView?.insertItems(at: updateIndex)
            }, completion: nil)
        }
        viewModel.trendingGifs.removeAll()
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
            let gifVc = GifViewController(with: true, viewModel: GifViewModel())
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
        if (isSearchActive ? indexPath.row == viewModel.searchGifs.count - 1 : indexPath.row == viewModel.trendingGifs.count - 1) {
            if isSearchActive {
                if viewModel.searchGifs.count < (viewModel.latestSearchResponse?.pagination.totalCount ?? 0) {
                    currentSearchOffset = viewModel.searchGifs.count
                    getSearchGifs(isSearch: false)
                }
            } else {
                if viewModel.trendingGifs.count < (viewModel.latestTrendingResponse?.pagination.totalCount ?? 0) {
                    currentTrendingOffset = viewModel.trendingGifs.count
                    getTrendingGifs(isPaginated: true)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedGif = isSearchActive ? viewModel.searchGifs[indexPath.row] : viewModel.trendingGifs[indexPath.row]
        dismiss(animated: true)
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl":  selectedGif.images.fixedWidthDownsampled.url])
    }
}

@available(iOS 13.0, *)
extension GifViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearchActive ? viewModel.searchGifs.count : viewModel.trendingGifs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdentifier", for: indexPath) as? GiphyCollectionCell else { return UICollectionViewCell() }
        guard let indexData = isSearchActive ? viewModel.searchGifs[safe: indexPath.row] : viewModel.trendingGifs[safe: indexPath.row] else {
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
