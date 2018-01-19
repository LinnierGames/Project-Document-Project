//
//  PhotoCollectionService.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation
import Zip

struct PhotoCollectionService {
    
    init() {
        Zip.addCustomFileExtension("tmp")
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: ~/../app-sandbox/Libray/Cache/<name>/
     */
    func filePathFor(photoCollection name: String) -> URL {
        let fileManager = FileManager.default
        let documentsFilePath = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let photoCollectionFilePath = documentsFilePath.appendingPathComponent("Caches", isDirectory: true)/*.appendingPathComponent(name, isDirectory: true) removes adding an extra folder*/
        
        return photoCollectionFilePath
    }
    
    func downloadZip(for url: URL, complition: @escaping (_ downloadLocation: URL?, Error?) -> ()) {
        let request = URLRequest(url: url)
        let session = URLSession.shared
        session.downloadTask(with: request) { (downloadDestination, response, error) in
            guard
                error == nil,
                let filePath = downloadDestination
                else {
                return complition(downloadDestination, error)
            }
            complition(filePath, nil)
        }.resume()
    }
    
    let baseUrl = URL(string: "https://s3-us-west-2.amazonaws.com/mob3/image_collection.json")!
    
    func fetchPhotoCollections(complition: @escaping ([PhotoCollection]) -> Void) {
        let request = URLRequest(url: baseUrl)
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                return complition([])
            }
        
            guard
                let result = data,
                let jsonCollections = try? JSONSerialization.jsonObject(with: result, options: .allowFragments) as! [[String: Any]]
                else {
                    return complition([])
            }
            
            var collections: [PhotoCollection] = []
            
            var dispatchGroup = DispatchGroup()
            
            for jsonCollection in jsonCollections {
                guard
                    let zipUrl = URL(string: jsonCollection["zipped_images_url"] as! String),
                    var collectionTitle = jsonCollection["collection_name"] as! String?
                    else {
                    return //skip jsonCollection
                }
                dispatchGroup.enter()
                self.downloadZip(for: zipUrl, complition: { (downloadUrl, error) in
                    defer { dispatchGroup.leave() }
                    guard
                        error == nil,
                        let filePath = downloadUrl
                        else {
                            return //skip jsonCollection
                    }
                    collectionTitle = collectionTitle.lowercased()
                    let cacheFilePath = self.filePathFor(photoCollection: collectionTitle)
                    do {
                        try Zip.unzipFile(filePath, destination: cacheFilePath, innerFolderTitle: collectionTitle)
                        
                        /*Locate the _preview image*/
                        let unzippedFolderTitle = zipUrl.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "+", with: " ")
                        let collectionCacheFilePath = cacheFilePath.appendingPathComponent(unzippedFolderTitle, isDirectory: true)
                        let previewUrl = collectionCacheFilePath.appendingPathComponent("_preview.png")
                        let imageData = try Data(contentsOf: previewUrl)
                        let image = UIImage(data: imageData)
                        
                        let photoCollection = PhotoCollection(title: collectionTitle, zipUrl: zipUrl, previewImage: image, contentUrl: collectionCacheFilePath)
                        
                        collections.append(photoCollection)
                    } catch {
                        //TODO: if Zip.unzip fails do i have to clear the
                        //folder?
                        print("ERROR: \(error.localizedDescription)")
                        print(zipUrl.deletingPathExtension().lastPathComponent)
                        
                        return //skip jsonCollection
                    }
                })
            }
            dispatchGroup.notify(queue: .main, execute: {
                complition(collections)
            })
        }.resume()
    }
}
