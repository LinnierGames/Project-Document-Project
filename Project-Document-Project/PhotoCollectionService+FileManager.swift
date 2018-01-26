//
//  PhotoCollection+FileManager.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/25/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation

extension FileManager {
    /**
     Returns the url of the cached images folder in the Library folder of the
     sandbox.
     
     - parameter appendingDirectory: appends a string directory to the end of
     this path
     
     - returns: ~/../app-sandbox/Libray/Caches/<name>/
     */
    func imagesCacheFolder(appendingDirectory: String? = nil) -> URL {
        let documentsFilePath = self.urls(for: .libraryDirectory, in: .userDomainMask).first!
        var photoCollectionFilePath = documentsFilePath.appendingPathComponent("Caches", isDirectory: true).appendingPathComponent("Images", isDirectory: true)
        if let appendedPath = appendingDirectory {
            photoCollectionFilePath.appendPathComponent(appendedPath, isDirectory: true)
        }
        
        return photoCollectionFilePath
    }
}
