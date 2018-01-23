//
//  PhotoCollectionService.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import Foundation
import Zip

typealias ProgressCallback = (Float) -> Void

class PhotoCollectionService: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    lazy var session: URLSession = {
        return URLSession(
            configuration: URLSessionConfiguration.default,
            delegate: self,
            delegateQueue: nil
        )
    }()
    var progressCallback: ProgressCallback?
    var progressData: Data?
    var estimatedTotal: Int = 0
    
    override init() {
        super.init()
        
        Zip.addCustomFileExtension("tmp")
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: ~/../app-sandbox/Libray/Cache/<name>/
     */
    private func filePathFor(photoCollection name: String?) -> URL {
        let fileManager = FileManager.default
        let documentsFilePath = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
        var photoCollectionFilePath = documentsFilePath.appendingPathComponent("Caches", isDirectory: true).appendingPathComponent("Images", isDirectory: true)
        if let appendedPath = name {
            photoCollectionFilePath.appendPathComponent(appendedPath, isDirectory: true)
        }
        
        return photoCollectionFilePath
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    private func downloadZip(for url: URL, complition: @escaping (_ downloadLocation: URL?, Error?) -> ()) {
        let request = URLRequest(url: url)

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
    
    enum PhotoResult {
        case done([PhotoCollection])
        case downloading(Double)
        case unzipping(Double)
        case error(PhotoServiceError)
    }
    
    enum PhotoServiceError: Error {
        case couldNotParseJSON
        case badRequest
    }
    
    /** <#Lorem ipsum dolor sit amet.#> */
    let baseUrl = URL(string: "https://s3-us-west-2.amazonaws.com/mob3/image_collection.json")!
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     */
    func getPhotoCollections(complition: @escaping (PhotoResult) -> ()) {
        if let collection = UserDefaults.standard.cacheDownloadedImages {
            complition(PhotoResult.done(collection))
        } else {
            fetchPhotoCollections(complition: complition)
        }
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     */
    private func fetchPhotoCollections(complition: @escaping (PhotoResult) -> Void) {
        let request = URLRequest(url: baseUrl)
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                return complition(.error(.badRequest))
            }
            
            guard
                let result = data,
                let jsonCollections = try? JSONSerialization.jsonObject(with: result, options: .allowFragments) as! [[String: Any]]
                else {
                    return complition(.error(.couldNotParseJSON))
            }
            var collections: [PhotoCollection] = []
            var dispatchGroup = DispatchGroup()
            
            for jsonCollection in jsonCollections {
                guard
                    let zipDownloadUrl = URL(string: jsonCollection["zipped_images_url"] as! String),
                    var collectionTitle = jsonCollection["collection_name"] as! String?
                    else {
                    return //skip jsonCollection
                }
                dispatchGroup.enter()
                self.downloadZip(for: zipDownloadUrl, complition: { (downloadUrl, error) in
                    defer { dispatchGroup.leave() }
                    guard
                        error == nil,
                        let zippedFilePath = downloadUrl
                        else {
                            return //skip jsonCollection
                    }
                    let imagesCacheFolderFilePath = self.filePathFor(photoCollection: nil)
                    do {
                        /*Unzip to cache folder and rename unzipped folder to the title of the Collection*/
                        try Zip.unzipFile(zippedFilePath, destination: imagesCacheFolderFilePath)
                        
                        let unzippedFolderTitle = zipDownloadUrl.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "+", with: " ")
                        let collectionCacheFilePath = imagesCacheFolderFilePath.appendingPathComponent(unzippedFolderTitle, isDirectory: true)
                        let newCollectionCacheFilePath = imagesCacheFolderFilePath.appendingPathComponent(collectionTitle, isDirectory: true)
                        try FileManager.default.moveItem(at: collectionCacheFilePath, to: newCollectionCacheFilePath)
                        
                        /*init PhotoCollection with collected data*/
                        let photoCollection = PhotoCollection(title: collectionTitle, zipUrl: zipDownloadUrl, contentLocation: newCollectionCacheFilePath.trimUserDirectory)
                        
                        collections.append(photoCollection)
                    } catch {
                        let fileManager = FileManager.default
                        try? fileManager.removeItem(at: zippedFilePath)
                        
                        return //skip jsonCollection
                    }
                })
            }
            dispatchGroup.notify(queue: .main, execute: {
                UserDefaults.standard.cacheDownloadedImages = collections
                complition(PhotoResult.done(collections))
            })
        }
        
        task.resume()
        
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    static func collectPhotos(for collection: PhotoCollection, complition: @escaping ([UIImage]) -> ()) {
        guard
            let photoCollectionFilePath = collection.contentUrl
            else {
                return
        }
        /*collect urls, excluding the preview image*/
        DispatchQueue.global(qos: .userInitiated).async {
            var images: [UIImage] = []
            do {
                let fileManager = FileManager.default
                let photoUrls = try fileManager.contentsOfDirectory(at: photoCollectionFilePath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    .filter { (url) -> Bool in
                        return url.lastPathComponent.contains("_preview") == false
                    }.filter({ (url) -> Bool in
                        return url.pathExtension.contains("jpeg") || url.pathExtension.contains("jpg")
                    })
                /*decode into images and update the collection view*/
                for imageFilePath in photoUrls {
                    if let image = UIImage(contentsOfFile: imageFilePath.relativePath) {
                        images.append(image)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            DispatchQueue.main.async {
                complition(images)
            }
        }
    }
}




extension PhotoCollectionService {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        progressData?.append(data)
        let percentageDownloaded = Float(progressData!.count) / Float(estimatedTotal)
        progressCallback?(percentageDownloaded)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.estimatedTotal = Int(response.expectedContentLength)
        completionHandler(URLSession.ResponseDisposition.allow)
    }
}



//extension URL: ExpressibleByStringLiteral {
//    public init(stringLiteral value: StringLiteralType) {
//        self = URL(string: value)!
//    }
//}

