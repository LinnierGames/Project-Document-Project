//
//  PhotoCollection.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation
import UIKit

struct PhotoCollection: Codable {
    let title: String
    let zipUrl: URL
    
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
    var contentLocation: String? = nil
    
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
        case contentLocation = "location"
    }
}

extension PhotoCollection: CustomStringConvertible {
    var description: String {
        return "\(title)"
    }
}
