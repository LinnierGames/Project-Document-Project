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
            /*Unzip into destination url and clear the downloaded zip from the tmp folder*/
            try Zip.unzipFile(zipFilePath, destination: destination, overwrite: true, password: nil)
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: zipFilePath)
        } catch {
            throw error
        }
    }
}
