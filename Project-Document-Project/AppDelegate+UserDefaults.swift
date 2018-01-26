//
//  AppDelegate+UserDefaults.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/19/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    /**
     Store and read the collection of PhotoCollection
     - warning: [PhotoCollection] is mapped to [PhotoCollectionCoding]
     */
    var cacheDownloadedImages: [PhotoCollection]? {
        get {
            if let collectionData = self.object(forKey: "collectionCache") as! Data? {
                guard let photoCollectionCodings = try? JSONDecoder().decode([PhotoCollectionCoding].self, from: collectionData) else {
                    return nil
                }
                
                return photoCollectionCodings.map { PhotoCollection.init($0) }
            } else {
                return nil
            }
        }
        set {
            if let collectionCodings = newValue?.map({ PhotoCollectionCoding.init($0) }) {
                let collectionData = try? JSONEncoder().encode(collectionCodings)
                self.set(collectionData, forKey: "collectionCache")
            }
        }
    }
}
