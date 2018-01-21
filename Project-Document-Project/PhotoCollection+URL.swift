//
//  PhotoCollection+URL.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/20/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation
extension URL {
    
    /** <#Lorem ipsum dolor sit amet.#> */
    var trimUserDirectory: String {
        let fMgr = FileManager.default
        let appSandboxTitle = fMgr.urls(for: .documentDirectory, in: .userDomainMask).first!.deletingLastPathComponent().lastPathComponent
        var urlToTrim = self
        var path = ""
        while appSandboxTitle != urlToTrim.lastPathComponent && urlToTrim.lastPathComponent != "" {
            path = "/\(urlToTrim.lastPathComponent)" + path
            urlToTrim = urlToTrim.deletingLastPathComponent()
        }
        let newPath = path[path.index(path.startIndex, offsetBy: 1)...]
        path = String(newPath)
        
        return path
    }
}

extension String {
    
    /** <#Lorem ipsum dolor sit amet.#> */
    func appendingUserDirectory(isDirectory: Bool) -> URL {
        let fMgr = FileManager.default
        
        return fMgr.urls(for: .documentDirectory, in: .userDomainMask).first!.deletingLastPathComponent().appendingPathComponent(self, isDirectory: isDirectory)
    }
}
