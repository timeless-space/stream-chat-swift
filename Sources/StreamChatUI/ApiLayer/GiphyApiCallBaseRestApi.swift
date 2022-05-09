//
//  GiphyApiCalls.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 06/05/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

@available(iOS 13.0, *)
class BaseRestAPI<T: EndPointType>: NSObject {
    
    typealias RequestModifier = ((URLRequest) -> URLRequest)
    var urlSession: URLSession { URLSession.shared }

    func call(type: T, params: [String: Any]?, requestModifier: @escaping RequestModifier = { $0 }) -> URLSession.ErasedDataTaskPublisher {
        var request = URLRequest(url: type.url)
        request.httpMethod = type.httpMethod.rawValue
        request.httpBody = params?.data()
        request.allHTTPHeaderFields = type.headers
        return createPublisher(for: request, type: type, requestModifier: requestModifier)
    }

    func createPublisher(
        for request: URLRequest,
        type: T,
        requestModifier:@escaping RequestModifier) -> URLSession.ErasedDataTaskPublisher {
            return Just(request)
                .setFailureType(to: Error.self)
                .flatMap { [self] in
                    urlSession.erasedDataTaskPublisher(for: requestModifier($0))
                }
                .eraseToAnyPublisher()
        }
}
