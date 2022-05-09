//
//  SwiftyGiphyAPI.swift
//  SwiftyGiphy
//
//  Created by Brendan Lee on 3/9/17.
//  Copyright © 2017 52inc. All rights reserved.
//

import UIKit
import Combine

@available(iOS 13.0, *)
class SwiftyGiphyApiCallClient: BaseRestAPI<SwiftyGiphyApiCallClient.RequestType>, GiphyApiServiceProtocol {

    static let shared: SwiftyGiphyApiCallClient = SwiftyGiphyApiCallClient()

    func getSearch(req: GetGifRequestModel) -> AnyPublisher<Result<GiphyResponse, Error>, Never> {
        return call(type: .getSearch(queryItems: req.searchQueryItems()), params: nil)
            .unwrapResultJSONFromAPI()
            .map { $0.data }
            .decodeFromJson(GiphyResponse.self)
            .receive(on: DispatchQueue.main)
            .map({ giphyResponse in
                return .success(giphyResponse)
            })
            .catch({ error in
                Just(.failure(error as! Error))
            })
                    .eraseToAnyPublisher()
    }

    func getTrending(req: GetGifRequestModel) -> AnyPublisher<Result<GiphyResponse, Error>, Never> {
        return call(type: .getTrending(queryItems: req.trendingQueryItems()), params: nil)
            .unwrapResultJSONFromAPI()
            .map { $0.data }
            .decodeFromJson(GiphyResponse.self)
            .receive(on: DispatchQueue.main)
            .map({ giphyResponse in
                return .success(giphyResponse)
            })
            .catch({ error in
                return Just(.failure(error as! Error))
            })
                    .eraseToAnyPublisher()
    }
}

class NetworkHelper {

    static var httpDefaultHeader: [String: String] {
        return ["Accept": "application/json",
                "Content-Type": "application/json"]
    }
}

@available(iOS 13.0, *)
extension SwiftyGiphyApiCallClient {
    enum RequestType: EndPointType {
        case getTrending(queryItems: [URLQueryItem])
        case getSearch(queryItems: [URLQueryItem])

        // MARK: Vars & Lets
        var baseURL: String {
            return "https://api.giphy.com/"
        }

        var queryItems: [URLQueryItem] {
            switch self {
            case .getSearch(let queryItems), .getTrending(let queryItems):
                return queryItems
            default:
                return []
            }
        }

        var version: String {
            return "v1/"
        }

        var path: String {
            switch self {
            case .getTrending:
                return "gifs/trending"
            case .getSearch:
                return "gifs/search"
            }
        }

        var httpMethod: HTTPMethod {
            switch self {
            case .getTrending, .getSearch:
                return .get
            default:
                return .post
            }
        }

        var headers: [String: String] {
            return NetworkHelper.httpDefaultHeader
        }
    }
}
