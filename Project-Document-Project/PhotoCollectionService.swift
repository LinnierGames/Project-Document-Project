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
        case finishedUnzipping(URL)
        case error(PhotoServiceError)
    }
    
    enum PhotoServiceError: Error {
        case couldNotParseJSON
        case badRequest(String)
        case zipCouldNotSaveToTempFolder
        case FailedToUnzip
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
            fetchPhotoCollections(photoResultHandler: complition)
        }
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     */
    private func fetchPhotoCollections(photoResultHandler: @escaping (PhotoResult) -> Void) {
        let request = URLRequest(url: baseUrl)
        let session = URLSession.shared
        
        /* Fetch json of list of photo collections */
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                return photoResultHandler(.error(.badRequest(error!.localizedDescription)))
            }
            
            /* json -> Models */
            guard
                let result = data,
                let photoCollections = try? JSONDecoder().decode([PhotoCollection].self, from: result)
                else {
                    return photoResultHandler(.error(.couldNotParseJSON))
            }
            
            let dispatchGroup = DispatchGroup()
            for aPhotoCollection in photoCollections {
                dispatchGroup.enter()
                self.fetchZip(from: aPhotoCollection, complition: { (result) in
                    switch result {
                    case .finishedUnzipping(let url):
                        aPhotoCollection.contentUrl = url
                    default: break
                    }
                    dispatchGroup.leave()
                })
                dispatchGroup.notify(queue: .main, execute: {
                    UserDefaults.standard.cacheDownloadedImages = photoCollections
                    photoResultHandler(PhotoResult.done(photoCollections))
                })
            }
        }
        
        task.resume()
        
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    private func fetchZip(from photoCollection: PhotoCollection, complition: @escaping (PhotoResult) -> ()) {
        /* download a zip */
        let zipDownloadUrl = photoCollection.zipUrl
        self.downloadZip(for: zipDownloadUrl, complition: { (tempFilePath, error) in
            guard
                error == nil else {
                    return complition(.error(.badRequest(error!.localizedDescription)))
            }
            
            guard let zippedFilePath = tempFilePath else {
                return complition(.error(.zipCouldNotSaveToTempFolder))
            }
            
            /* Unzip to cache folder and rename unzipped folder to the title of the Collection */
            do {
                let imagesCacheFolderFilePath = FileManager.default.imagesCacheFolder()
                try Zip.unzipFile(zippedFilePath, destination: imagesCacheFolderFilePath)
                
                /* Rename unzipped folder to collection title and reference location of unzipped folder */
                let unzippedFolderTitle = zipDownloadUrl.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "+", with: " ")
                let collectionCacheFileUrl = imagesCacheFolderFilePath.appendingPathComponent(unzippedFolderTitle, isDirectory: true)
                let newCollectionCacheFileUrl = imagesCacheFolderFilePath.appendingPathComponent(photoCollection.title, isDirectory: true)
                try FileManager.default.moveItem(at: collectionCacheFileUrl, to: newCollectionCacheFileUrl) //Rename old title to new title
                
                complition(.finishedUnzipping(newCollectionCacheFileUrl))
            } catch {
                let fileManager = FileManager.default
                try? fileManager.removeItem(at: zippedFilePath)
                
                return complition(.error(.FailedToUnzip))
            }
        })
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

