//
//  URLSession+Extensions.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine

@available(iOS 13.0, *)
extension URLSession.ErasedDataTaskPublisher {
    func unwrapResultJSONFromAPI() -> Self {
        tryMap {
            return $0
        }.eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension URLSession {
    typealias ErasedDataTaskPublisher = AnyPublisher<(data: Data, response: URLResponse), Error>
    func erasedDataTaskPublisher(
        for request: URLRequest
    ) -> ErasedDataTaskPublisher {
        dataTaskPublisher(for: request)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
