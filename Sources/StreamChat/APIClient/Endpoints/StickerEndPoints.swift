//
//  StickerEndPoints.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/03/22.
//

import Foundation
import Combine

@available(iOS 13.0, *)
extension StickerApi {
    public static func analytics(userId: String) -> AnyPublisher<EmptyResponse, Error> {
        var request = (URLRequest(url: base.appendingPathComponent("analytics/send/790/")))
        let params = ["userId": "123"] as Dictionary<String, String>
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func mySticker() -> AnyPublisher<ResponseBody<MyStickerBody>, Error> {
        var request = (URLRequest(url: base.appendingPathComponent("mysticker/\(StickerApi.userId)")))
        request.httpMethod = "GET"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func stickerInfo(id: String) -> AnyPublisher<ResponseBody<PackageInfoBody>, Error> {
        let url = base.absoluteString + "package/\(id)?" + "userId=\(userId)"
        // TODO: Refactor code, remove force cast
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "GET"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func buildQueryString(fromDictionary parameters: [String:String]) -> String {
        var urlVars:[String] = []
        for (k, value) in parameters {
            let value = value as NSString
            if let encodedValue = value.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
                urlVars.append(k + "=" + encodedValue)
            }
        }
        return urlVars.isEmpty ? "" : "?" + urlVars.joined(separator: "&")
    }
}
