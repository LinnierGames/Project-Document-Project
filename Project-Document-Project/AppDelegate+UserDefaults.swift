//
//  AppDelegate+UserDefaults.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/19/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation

extension UserDefaults {
    var userHasDownloadedImages: Bool {
        get {
            return self.bool(forKey: "hasCollectedImagesFromServer")
        }
        set {
            self.set(newValue, forKey: "hasCollectedImagesFromServer")
        }
    }
}
