//
//  SwiftyGiphyAPI.swift
//  SwiftyGiphy
//
//  Created by Brendan Lee on 3/9/17.
//  Copyright © 2017 52inc. All rights reserved.
//

import UIKit

public let kGiphyNetworkingErrorDomain = "kGiphyNetworkingErrorDomain"
typealias GiphyMultipleGIFResponseBlock = (_ error: NSError?, _ response: GiphyResponse?) -> Void
fileprivate typealias GiphyAPIResponseBlock = (_ error: NSError?, _ response: Data?) -> Void
fileprivate let kGiphyUnknownResponseError = NSLocalizedString("The server returned an unknown response.", comment: "Error from server")

public class SwiftyGiphyAPI {
    
    /// Access the Giphy API through the shared singleton.
    public static let shared: SwiftyGiphyAPI = SwiftyGiphyAPI()
    
    /// Before you can use SwiftyGiphy, you need to set your API key.
    public var apiKey = ChatClientConfiguration.shared.giphyApiKey
    public var giphyAPIBase: URL = URL(string: "https://api.giphy.com/v1/gifs/")!
    
    /**
     Send a request
     - parameter request:    The request to send.
     - parameter completion: The completion block to call when done.
     */
    fileprivate func send(request: URLRequest, completion: GiphyAPIResponseBlock?) {
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            let requestURLString = request.url?.absoluteString
            // Check for network error
            guard error == nil else {
                completion?(error as NSError?, nil)
                return
            }
            // Check for valid JSON
            guard let validData = data,
                  let jsonObj = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments),
                  let jsonDict = jsonObj as? [String : AnyObject],
                  let httpResponse = response as? HTTPURLResponse else {
                      if let validData = data,
                         let jsonObj = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments),
                         let jsonArray = jsonObj as? [[String : AnyObject]] {
                          // Ok, it's a root array. It'll bypass some error checking..but it'll be fine.
                          let response: [String : AnyObject] = ["response" : jsonArray as AnyObject]
                          completion?(nil, validData)
                          return
                      }
                      let error = NSError(domain: kGiphyNetworkingErrorDomain, code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey : kGiphyUnknownResponseError])
                      completion?(error, nil)
                      return;
                  }
            // Check the network error code
            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                let error = NSError(domain: kGiphyNetworkingErrorDomain, code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey : kGiphyUnknownResponseError
                ])
                completion?(error, data)
                return;
            }
            // Valid response
            completion?(nil, validData)
        }).resume()
    }
    
    /// Create a basic network error with a given description.
    ///
    /// - parameter description: The description for the error
    ///
    /// - returns: The created error
    fileprivate func networkError(description: String) -> NSError
    {
        return NSError(domain: kGiphyNetworkingErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : description])
    }
    /**
     Create a request.
     
     - parameter relativePath:    The relative path for the request (relative to the Giphy API base)
     - parameter method: The method for the request
     - parameter json:   The object to serialize to JSON (Array or Dictionary)
     
     - returns: The generated request, or nil if a JSON error occurred.
     */
    fileprivate func createRequest(baseURL: URL, relativePath:String, method:String, params: [String : Any]?) -> URLRequest {
        var request = URLRequest(url: URL(string: relativePath, relativeTo: baseURL)!)
        request.httpMethod = method
        if let localparams = params as [String : AnyObject]? {
            if method == "GET" {
                // GET params
                var queryItems = [URLQueryItem]()
                for (key, value) in localparams {
                    let stringValue = (value as? String) ?? String(describing: value)
                    queryItems.append(URLQueryItem(name: key, value: stringValue))
                }
                var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                components.queryItems = queryItems
                request.url = components.url
            } else {
                // JSON params
                let jsonData = try? JSONSerialization.data(withJSONObject: localparams, options: JSONSerialization.WritingOptions())
                request.httpBody = jsonData
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        return request
    }
}

// MARK: - GIF Support
extension SwiftyGiphyAPI {
    
    /// Get the currently trending gifs from Giphy
    ///
    /// - Parameters:
    ///   - limit: The limit of results to fetch
    ///   - rating: The max rating for the gifs
    ///   - offset: The paging offset
    ///   - completion: The completion block to call when done
    func getTrending(
        limit: Int = 25,
        offset: Int? = nil,
        completion: GiphyMultipleGIFResponseBlock?
    ) {
        var params = [String : Any]()
        params["api_key"] = apiKey
        params["limit"] = limit
        params["rating"] = "pg-13"
        if let currentOffset = offset {
            params["offset"] = currentOffset
        }
        let request = createRequest(baseURL: giphyAPIBase, relativePath: "trending", method: "GET", params: params)
        send(request: request) { [unowned self] (error, response) in
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                return
            }
            // We have gifs!
            guard let validResponse = response else {
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            let gifs = try? JSONDecoder().decode(GiphyResponse.self, from: validResponse)
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Get the results for a search from Giphy
    ///
    /// - Parameters:
    ///   - searchTerm: The phrase to use to search Giphy
    ///   - limit: The limit of results to fetch
    ///   - rating: The max rating for the gifs
    ///   - offset: The paging offset
    ///   - completion: The completion block to call when done
    func getSearch(
        searchTerm: String,
        limit: Int = 25,
        offset: Int? = nil,
        completion: GiphyMultipleGIFResponseBlock?
    ) {
        var params = [String : Any]()
        params["api_key"] = apiKey
        params["q"] = searchTerm
        params["limit"] = limit
        params["rating"] = "pg-13"
        if let currentOffset = offset {
            params["offset"] = currentOffset
        }
        let request = createRequest(baseURL: giphyAPIBase, relativePath: "search", method: "GET", params: params)
        send(request: request) { [unowned self] (error, response) in
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                return
            }
            // We have gifs!
            guard let validResponse = response else {
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            let gifs = try? JSONDecoder().decode(GiphyResponse.self, from: validResponse)
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
}
