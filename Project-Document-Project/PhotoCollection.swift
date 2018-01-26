//
//  PhotoCollection.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation
import UIKit

/**
 Front facing class to give a title and the contentPath of the collection of
 photos
 */
class PhotoCollection: Codable {
    var title: String
    var zipUrl: URL
    
    init(title: String, zipUrl: URL, contentLocation: String? = nil) {
        self.title = title
        self.zipUrl = zipUrl
        self.contentLocation = contentLocation
    }
    
    /** <#Lorem ipsum dolor sit amet.#> */
    var previewImage: UIImage? {
        guard
            let previewUrl = self.contentUrl?.appendingPathComponent("_preview.png", isDirectory: true),
            let imageData = try? Data(contentsOf: previewUrl),
            let image = UIImage(data: imageData)
            else {
                return nil
        }
        
        return image
    }
    
    /** <#Lorem ipsum dolor sit amet.#> */
    fileprivate var contentLocation: String? = nil
    
    /** <#Lorem ipsum dolor sit amet.#> */
    var contentUrl: URL? {
        get {
            return contentLocation?.appendingUserDirectory(isDirectory: true)
        }
        set {
            contentLocation = newValue?.trimUserDirectory
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case title = "collection_name"
        case zipUrl = "zipped_images_url"
    }
}

extension PhotoCollection: CustomStringConvertible {
    var description: String {
        return "\(title)"
    }
}

/**
 Decode and encode a PhotoCollection into UserDefaults
 - warning: only stores title and contentUrl from the collection
 */
struct PhotoCollectionCoding: Codable {
    let title: String
    let zipUrl: URL
    let contentFilePath: String
    
    init?(_ photoCollection: PhotoCollection) {
        self.title = photoCollection.title
        self.zipUrl = photoCollection.zipUrl
        guard let path = photoCollection.contentLocation else {
            return nil
        }
        self.contentFilePath = path
    }
}

extension PhotoCollection {
    convenience init(_ photoCollectionCoding: PhotoCollectionCoding) {
        self.init(title: photoCollectionCoding.title, zipUrl: photoCollectionCoding.zipUrl, contentLocation: photoCollectionCoding.contentFilePath)
    }
}
