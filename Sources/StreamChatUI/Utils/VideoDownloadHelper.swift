//
//  DownloadHelper.swift
//  StreamChatUI
//
//  Created by Mohammed Hanif on 20/06/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class VideoDownloadHelper {

    static let shared = VideoDownloadHelper()

    func getCacheDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    func checkIfFileExists(fileName: String) -> (Bool, String) {
        let cacheUrl = getCacheDirectory()
        if let pathComponent = cacheUrl.appendingPathComponent(fileName) as? URL {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                debugPrint("### Filepath - \(filePath)")
                return (true, filePath)
            } else {
                return (false, filePath)
            }
        } else {
            return (false, "")
        }
    }

    func loadFileAsync(url: URL?, completion: @escaping (String?, Error?) -> Void) {
        guard let url = url else { return }
        let cacheUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let destinationUrl = cacheUrl.appendingPathComponent(url.lastPathComponent)

        if FileManager().fileExists(atPath: destinationUrl.path) {
            debugPrint("### File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        } else {
            debugPrint("### File Download started [\(destinationUrl.path)]")
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request, completionHandler: {
                data, response, error in
                if error == nil {
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode == 200 {
                            if let data = data {
                                if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic) {
                                    debugPrint("### File download complete [\(destinationUrl.path)]")
                                    completion(destinationUrl.path, error)
                                } else {
                                    completion(destinationUrl.path, error)
                                }
                            } else {
                                completion(destinationUrl.path, error)
                            }
                        }
                    }
                } else {
                    completion(destinationUrl.path, error)
                }
            })
            task.resume()
        }
    }
}
