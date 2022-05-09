//
//  RequestGetSearch.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

class GetGifRequestModel {

    var apiKey: String?
    var searchText: String?
    var limit: Int?
    var rating: String?
    var offset: Int?

    init(
        apiKey: String = ChatClientConfiguration.shared.giphyApiKey,
        searchText: String? = nil,
        limit: Int = 25,
        rating: String = "pg-13",
        offset: Int?
    ) {
        self.apiKey = apiKey
        self.searchText = searchText
        self.limit = limit
        self.rating = rating
        self.offset = offset
    }

    func trendingQueryItems() -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        queryItems.append(URLQueryItem(name: "limit", value: limit?.string ?? ""))
        queryItems.append(URLQueryItem(name: "rating", value: rating))
        queryItems.append(URLQueryItem(name: "offset", value: offset?.string ?? ""))
        return queryItems
    }

    func searchQueryItems() -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        queryItems.append(URLQueryItem(name: "q", value: searchText))
        queryItems.append(URLQueryItem(name: "limit", value: limit?.string ?? ""))
        queryItems.append(URLQueryItem(name: "rating", value: rating))
        queryItems.append(URLQueryItem(name: "offset", value: offset?.string ?? ""))
        return queryItems
    }
}
