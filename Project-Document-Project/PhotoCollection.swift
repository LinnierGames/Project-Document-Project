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
class PhotoCollection: NSObject, Decodable {
    
    /** Title of the photo collection */
    var title: String
    
    /** URL location of the zip stored on the cloud */
    var zipUrl: URL?
    
    /**
     Stored contentLocation as a trimmed string, thus only containg
     the path from the app sandbox to the destination
     */
    fileprivate var contentLocation: String? = nil
    
    init(title: String, zipUrl: URL? = nil, contentLocation: String? = nil) {
        self.title = title
        self.zipUrl = zipUrl
        self.contentLocation = contentLocation
    }
    
    /** Read the preview image from the contentUrl, if it exists */
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
    
    /** Unzipped location of the images including the preview image */
    var contentUrl: URL? {
        get {
            return contentLocation?.appendingUserDirectory(isDirectory: true)
        }
        set {
            contentLocation = newValue?.trimUserDirectory
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case title = "collection_name"
        case zipUrl = "zipped_images_url"
    }
    
    override var description: String {
        return "\(title)"
    }
}

/**
 Decode and encode a PhotoCollection into UserDefaults
 - warning: only stores title and contentUrl from the collection
 */
struct PhotoCollectionCoding: Codable {
    let title: String
    let contentFilePath: String
    
    /**
     Map a PhotoCollection to a PhotoCollectionCoding
     - warning: is failable since photoCollection.contentLocation can be nil
     */
    init?(_ photoCollection: PhotoCollection) {
        self.title = photoCollection.title
        guard let path = photoCollection.contentLocation else {
            return nil
        }
        self.contentFilePath = path
    }
}

extension PhotoCollection {
    /**
     Convenience initializer to map PhotoCollectiongCoding back to
     - warning: only title and contentLocation are stored in a
     PhotoCollectionCoding. All others, such as zipUrl, will be nil
     */
    convenience init(_ photoCollectionCoding: PhotoCollectionCoding) {
        self.init(title: photoCollectionCoding.title, contentLocation: photoCollectionCoding.contentFilePath)
    }
}
