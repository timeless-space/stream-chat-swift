// The MIT License (MIT)
//
// Copyright (c) 2015-2021 Alexander Grebenyuk (github.com/kean).

import Foundation

#if !os(macOS)
import UIKit.UIImage
#else
import AppKit.NSImage
#endif

// MARK: - ImageResponse

/// An image response that contains a fetched image and some metadata.
struct ImageResponse {
    /// An image container with an image and associated metadata.
    let container: ImageContainer

    #if os(macOS)
    /// A convenience computed property that returns an image from the container.
    var image: NSImage { container.image }
    #else
    /// A convenience computed property that returns an image from the container.
    var image: UIImage { container.image }
    #endif

    /// A response. `nil` unless the resource was fetched from the network or an
    /// HTTP cache.
    let urlResponse: URLResponse?

    /// Contains a cache type in case the image was returned from one of the
    /// pipeline caches (not including any of the HTTP caches if enabled).
    let cacheType: CacheType?

    /// Initializes the response with the given image.
    init(container: ImageContainer, urlResponse: URLResponse? = nil, cacheType: CacheType? = nil) {
        self.container = container
        self.urlResponse = urlResponse
        self.cacheType = cacheType
    }

    func map(_ transformation: (ImageContainer) -> ImageContainer?) -> ImageResponse? {
        return autoreleasepool {
            guard let output = transformation(container) else {
                return nil
            }
            return ImageResponse(container: output, urlResponse: urlResponse, cacheType: cacheType)
        }
    }

    /// A cache type.
    enum CacheType {
        /// Memory cache (see `ImageCaching`)
        case memory
        /// Disk cache (see `DataCaching`)
        case disk
    }
}

// MARK: - ImageContainer

/// An image container with an image and associated metadata.
struct ImageContainer {
    #if os(macOS)
    /// A fetched image.
    var image: NSImage
    #else
    /// A fetched image.
    var image: UIImage
    #endif

    /// An image type.
    var type: ImageType?

    /// Returns `true` if the image in the container is a preview of the image.
    var isPreview: Bool

    /// Contains the original image `data`, but only if the decoder decides to
    /// attach it to the image.
    ///
    /// The default decoder (`ImageDecoders.Default`) attaches data to GIFs to
    /// allow to display them using a rendering engine of your choice.
    ///
    /// - note: The `data`, along with the image container itself gets stored
    /// in the memory cache.
    var data: Data?

    /// An metadata provided by the user.
    var userInfo: [UserInfoKey: Any]

    /// Initializes the container with the given image.
    init(image: PlatformImage, type: ImageType? = nil, isPreview: Bool = false, data: Data? = nil, userInfo: [UserInfoKey: Any] = [:]) {
        self.image = image
        self.type = type
        self.isPreview = isPreview
        self.data = data
        self.userInfo = userInfo
    }

    /// Modifies the wrapped image and keeps all of the rest of the metadata.
    func map(_ closure: (PlatformImage) -> PlatformImage?) -> ImageContainer? {
        guard let image = closure(self.image) else {
            return nil
        }
        return ImageContainer(image: image, type: type, isPreview: isPreview, data: data, userInfo: userInfo)
    }

    /// A key use in `userInfo`.
    struct UserInfoKey: Hashable, ExpressibleByStringLiteral {
        let rawValue: String

        init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        init(stringLiteral value: String) {
            self.rawValue = value
        }

        /// A user info key to get the scan number (Int).
        static let scanNumberKey: UserInfoKey = "github.com/kean/nuke/scan-number"
    }
}
