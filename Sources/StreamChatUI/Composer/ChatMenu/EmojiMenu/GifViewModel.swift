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
class GifViewModel: NSObject {

    private var apiHandler = SwiftyGiphyApiCallCombine.shared
    var trendingGifs:[GiphyModelItem] = []
    var searchGifs:[GiphyModelItem] = []
    var latestTrendingResponse: GiphyResponse?
    var latestSearchResponse: GiphyResponse?
    var currentNetworkCalls = Set<AnyCancellable>()

    func getTrendingApiCalls(currentTrendingOffset: Int, completion: @escaping GiphyApiResponseCompletion) {
        apiHandler.getTrending(req: RequestGetSearch(offset: currentTrendingOffset)).sink(receiveValue: { result in
            switch result {
            case .success(let giphyResponse):
                completion(true, giphyResponse)
            case .failure:
                completion(false, nil)
            default: break
            }
        }).store(in: &currentNetworkCalls)
    }

    func getSearchApiCalls(currentSearchText: String, currentSearchOffset: Int, completion: @escaping GiphyApiResponseCompletion) {
        apiHandler.getSearch(req: RequestGetSearch(searchText: currentSearchText, offset: currentSearchOffset)).sink(receiveValue: { result in
            switch result {
            case .success(let giphyResponse):
                completion(true, giphyResponse)
            case .failure:
                completion(false, nil)
            default: break
            }
        })
            .store(in: &currentNetworkCalls)
    }
}
