//
//  GiphyApiServiceProtocol.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine

@available(iOS 13.0, *)
protocol GiphyApiServiceProtocol {
    func getSearch(req: GetGifRequestModel) -> AnyPublisher<Result<GiphyResponse, Error>, Never>
    func getTrending(req: GetGifRequestModel) -> AnyPublisher<Result<GiphyResponse, Error>, Never>
}
