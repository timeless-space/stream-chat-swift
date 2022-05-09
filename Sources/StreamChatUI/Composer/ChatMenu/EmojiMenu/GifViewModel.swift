//
//  GifViewModel.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import Combine

typealias GiphyApiResponseCompletion = (_ isSuccess: Bool, _ response: GiphyResponse?) -> Void

@available(iOS 13.0, *)
class GifViewModel: ObservableObject {

    private var apiHandler = SwiftyGiphyApiCallClient.shared
    var trendingGifs: [GiphyModelItem] = []
    var searchGifs: [GiphyModelItem] = []
    var isSearch = false
    var scrollToTop = false
    var isSearchActive = false
    private var currentSearchText = ""
    @Published var latestTrendingResponse: GiphyResponse?
    @Published var latestSearchResponse: GiphyResponse?
    @Published var apiError: Bool?
    @Published var searchingText: String = ""
    var currentNetworkCalls = Set<AnyCancellable>()
    var callSearchApi: (() -> Void)?

    init() {
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
                self.callSearchApi?()
            }
            .store(in: &currentNetworkCalls)
    }

    func getTrendingApiCall() {
        apiHandler.getTrending(req: GetGifRequestModel(offset: trendingGifs.count)).sink(receiveValue: { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let giphyResponse):
                self.latestTrendingResponse = giphyResponse
            case .failure:
                self.apiError = true
            default: break
            }
        }).store(in: &currentNetworkCalls)
    }

    func getSearchApiCall() {
        apiHandler.getSearch(req: GetGifRequestModel(searchText: currentSearchText, offset: searchGifs.count)).sink(receiveValue: { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let giphyResponse):
                self.latestSearchResponse = giphyResponse
            case .failure:
                self.apiError = true
            default: break
            }
        })
            .store(in: &currentNetworkCalls)
    }
}
