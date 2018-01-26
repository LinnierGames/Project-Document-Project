//
//  PhotoCollectionService+Zip.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/18/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation
import Zip

extension Zip {
    
    /**
     Unzip into destination url and clear the downloaded zip from the tmp folder
     - parameter zipFilePath: file to unzip
     - parameter destination: url to unzip the contents to
     - throws: rethrows from Zip.unzipFile(..) and FileManager when deleting the
     zipFilePath
     */
    public class func unzipFile(_ zipFilePath: URL, destination: URL) throws {
        do {
            try Zip.unzipFile(zipFilePath, destination: destination, overwrite: true, password: nil)
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: zipFilePath)
        } catch {
            throw error
        }
    }
}
