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
     Unzips and then opens the folder the zip contained and extracts the files
     to the destination url
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    public class func unzipFile(_ zipFilePath: URL, destination: URL) throws {
        do {
            /*Unzip into destination url*/
            try Zip.unzipFile(zipFilePath, destination: destination, overwrite: true, password: nil)
            let fileManager = FileManager.default
//            /*Since contents unziped is a */
//            let fileManager = FileManager.default
//            let innerFolderUrl = destination.appendingPathComponent(innerFolderTitle, isDirectory: true)
//            let contents = try fileManager.contentsOfDirectory(at: innerFolderUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
//            /*copy the files*/
//            for file in contents {
//                let fileName = file.lastPathComponent
//                let newDestination = destination.appendingPathComponent(fileName)
//                try fileManager.copyItem(at: file, to: newDestination)
//            }
//
//            /*delete the old files include the inner folder*/
//            try? fileManager.removeItem(at: innerFolderUrl)
// unzip to an images folder
            
            /*clear the ziped file path from the temp folder*/
            try? fileManager.removeItem(at: zipFilePath)
        } catch {
            throw error
        }
    }
}
