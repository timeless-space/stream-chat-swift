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
    private var isSearchEnable = false
    private var listenCancellables = Set<AnyCancellable>()
    private var isFetchingApiData = false
    private var cacheMemorySize = 50 * 1000 * 1000
    private var viewModel = GifViewController.ViewModel()

    init(with isSearchEnable: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.isSearchEnable = isSearchEnable
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpObservers()
        setUpGifView()
        setUpProgressView()
        getTrendingGifs(isPaginated: false)
        setUpErrorLabel()
    }

    deinit {
        GPHCache.shared.clear()
    }

    private func setUpObservers() {
        viewModel.$latestTrendingResponse
            .sink { [weak self] result in
            guard let `self` = self else { return }
            if !self.viewModel.isSearchActive {
                DispatchQueue.main.async {
                    self.updateTrendingGifView(latestTrendingResponse: result, scrollToTop: self.viewModel.scrollToTop)
                }
            }
            self.progressView.isHidden = true
            self.errorLabel.isHidden = !(result?.data.isEmpty ?? false)
        }
        .store(in: &listenCancellables)

        viewModel.$latestSearchResponse
            .sink { [weak self] result in
            guard let `self` = self else { return }
            if self.viewModel.isSearchActive {
                self.updateSearchGifView(latestSearchResponse: result, isSearch: self.viewModel.isSearch)
            }
            self.progressView.isHidden = true
            self.errorLabel.isHidden = !(result?.data.isEmpty ?? false)
        }
        .store(in: &listenCancellables)

        viewModel.$apiError
            .sink { [weak self] isApiError in
            guard let `self` = self else { return }
            self.progressView.isHidden = true
            self.errorLabel.isHidden = !(isApiError ?? false)
        }
        .store(in: &listenCancellables)

        viewModel.callSearchApi = { [weak self] in
            guard let `self` = self else { return }
            self.getSearchGifs(isSearch: true)
        }
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
        GPHCache.shared.cache.diskCapacity = cacheMemorySize
        GPHCache.shared.cache.memoryCapacity = cacheMemorySize
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

    override func viewDidDisappear(_ animated: Bool) {
        if isSearchEnable {
            NotificationCenter.default.post(name: .updateTextfield, object: nil, userInfo: nil)
        }
        super.viewDidDisappear(animated)
    }

    private func setUpBackButton() {
        headerStackView.axis = .horizontal
        headerStackView.distribution = .fill
        headerStackView.spacing = 10
        backButton.setImage(UIImage(named: "closeSmall"), for: .normal)
        backButton.addTarget(self, action: #selector(btnBackPressed), for: .touchUpInside)
        backButton.isHidden = !isSearchEnable
        searchView.backgroundColor = Appearance.default.colorPalette.stickerBg
        searchView.placeholder = "Search GIFs"
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
        viewModel.isSearchActive = false
        pagingProgressView.isHidden = viewModel.trendingGifs.count == 0
        bottomView.isHidden = viewModel.trendingGifs.count == 0
        viewModel.scrollToTop = scrollToTop
        viewModel.getTrendingApiCall()
    }

    private func updateTrendingGifView(latestTrendingResponse: GiphyResponse?, scrollToTop: Bool) {
        guard let response = latestTrendingResponse else { return }
        isFetchingApiData = false
        progressView.isHidden = true
        pagingProgressView.isHidden = true
        collectionView?.alpha = 1.0
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
        viewModel.isSearch = isSearch
        viewModel.getSearchApiCall()
    }

    private func updateSearchGifView(latestSearchResponse: GiphyResponse?, isSearch: Bool) {
        guard let response = latestSearchResponse else { return }
        isFetchingApiData = false
        if isSearch {
            viewModel.searchGifs.removeAll()
        }
        pagingProgressView.isHidden = true
        bottomView.isHidden = true
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
    }

    @objc func btnBackPressed(sender: UIButton!) {
        dismiss(animated: true)
    }
}

@available(iOS 13.0, *)
extension GifViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if !isSearchEnable {
            NotificationCenter.default.post(name: .updateTextfield, object: nil, userInfo: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                let gifVc = GifViewController(with: true)
                NotificationCenter.default.post(name: .clearTextField, object: nil, userInfo: nil)
                UIApplication.shared.getTopViewController()?.present(gifVc, animated: true, completion: nil)
            })
        }
        return isSearchEnable
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchingText = searchText
        if searchText.isEmpty {
            viewModel.isSearchActive = false
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
        if (viewModel.isSearchActive ? indexPath.row == viewModel.searchGifs.count - 1 : indexPath.row == viewModel.trendingGifs.count - 1) {
            if viewModel.isSearchActive {
                if viewModel.searchGifs.count < (viewModel.latestSearchResponse?.pagination.totalCount ?? 0) {
                    getSearchGifs(isSearch: false)
                }
            } else {
                if viewModel.trendingGifs.count < (viewModel.latestTrendingResponse?.pagination.totalCount ?? 0) {
                    getTrendingGifs(isPaginated: true)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedGif = viewModel.isSearchActive ? viewModel.searchGifs[indexPath.row] : viewModel.trendingGifs[indexPath.row]
        dismiss(animated: true)
        NotificationCenter.default.post(name: .sendSticker, object: nil, userInfo: ["giphyUrl":  selectedGif.images.fixedWidthDownsampled.url])
    }
}

@available(iOS 13.0, *)
extension GifViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.isSearchActive ? viewModel.searchGifs.count : viewModel.trendingGifs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "cellIdentifier",
            for: indexPath) as? GiphyCollectionCell else { return UICollectionViewCell() }
        guard let indexData = viewModel.isSearchActive ? viewModel.searchGifs[safe: indexPath.row] : viewModel.trendingGifs[safe: indexPath.row] else {
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
