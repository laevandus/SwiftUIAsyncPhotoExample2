//
//  AsyncPhotoCache.swift
//  SwiftUIAsyncPhotoExample2
//
//  Created by Toomas Vahter on 09.12.2023.
//

import Foundation
import SwiftUI

/// An interface for caching images by identifier and size.
protocol AsyncPhotoCaching {
    
    /// Store the specified image by size and identifier.
    /// - Parameters:
    ///   - image: The image to be cached.
    ///   - id: The unique identifier of the image.
    func store(_ image: UIImage, forID id: any Hashable)
    
    
    /// Returns the image associated with a given id and size.
    /// - Parameters:
    ///   - id: The unique identifier of the image.
    ///   - size: The size of the image stored in the cache.
    /// - Returns: The image associated with id and size, or nil if no image is associated with id and size.
    func image(for id: any Hashable, size: CGSize) -> UIImage?
    
    
    /// Returns the caching key by combining a given image id and a size.
    /// - Parameters:
    ///   - id: The unique identifier of the image.
    ///   - size: The size of the image stored in the cache.
    /// - Returns: The caching key by combining a given id and size.
    func cacheKey(for id: any Hashable, size: CGSize) -> String
}

extension AsyncPhotoCaching {
    func cacheKey(for id: any Hashable, size: CGSize) -> String {
        "\(id.hashValue):w\(Int(size.width))h\(Int(size.height))"
    }
}

struct AsyncPhotoCache: AsyncPhotoCaching {
    private var storage: NSCache<NSString, UIImage>
    static let shared = AsyncPhotoCache(countLimit: 10)
    
    init(countLimit: Int) {
        self.storage = NSCache()
        self.storage.countLimit = countLimit
    }
    
    func store(_ image: UIImage, forID id: any Hashable) {
        let key = cacheKey(for: id, size: image.size)
        storage.setObject(image, forKey: key as NSString)
    }
    
    func image(for id: any Hashable, size: CGSize) -> UIImage? {
        let key = cacheKey(for: id, size: size)
        return storage.object(forKey: key as NSString)
    }
}
