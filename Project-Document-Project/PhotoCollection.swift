//
//  PhotoCollection.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation
struct PhotoCollection: Encodable {
    let title: String
    let zipUrl: URL
    var contentUrl: URL?
    
    enum CodingKeys: String, CodingKey {
        case title = "collection_name"
        case zipUrl = "zipped_images_url"
    }
}

extension PhotoCollection: CustomStringConvertible {
    var description: String {
        return "\(title), zip \(zipUrl.relativeString), \(contentUrl?.relativeString ?? "not found")"
    }
}
