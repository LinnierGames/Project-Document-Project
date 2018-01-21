//
//  AppDelegate+UserDefaults.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/19/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    /** <#Lorem ipsum dolor sit amet.#> */
    var cacheDownloadedImages: [PhotoCollection]? {
        get {
            if let collectionData = self.object(forKey: "collectionCache") as! Data? {
                return try? JSONDecoder().decode([PhotoCollection].self, from: collectionData)
            } else {
                return nil
            }
        }
        set {
            let collectionData = try? JSONEncoder().encode(newValue)
            self.set(collectionData, forKey: "collectionCache")
        }
    }
}
