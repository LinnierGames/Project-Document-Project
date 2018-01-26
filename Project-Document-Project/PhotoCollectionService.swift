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
    
    //TODO: use progress call backs
    var progressCallback: ProgressCallback?
    var progressData: Data?
    var estimatedTotal: Int = 0
    
    private override init() {
        super.init()
    }
    
    /**
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    public init(_ extentions: [String] = ["tmp"]) {
        
        for extention in extentions {
            Zip.addCustomFileExtension(extention)
        }
    }
    
    public enum PhotoResult {
        case done([PhotoCollection])
        case downloading(Double)
        case unzipping(Double)
        case finishedUnzipping(URL)
        case error(PhotoServiceError)
    }
    
    public enum PhotoServiceError: Error {
        case couldNotParseJSON
        case badRequest(String)
        case zipCouldNotSaveToTempFolder
        case FailedToUnzip
    }
    
    /** API call to collect the list of photo collections */
    public var baseUrl = URL(string: "https://s3-us-west-2.amazonaws.com/mob3/image_collection.json")!
    
    /**
     Collect the list of photo collections, fetching their titles and images
     include the preview image. If photo collections have been cached, into
     UserDefaults, complition will return the content that was saved from a
     pervious fetch. Otherwise, a network call will be made to fetch the
     collections.
     
     - parameter PhotoResult:
        - done: finshed downloading photo collection and their titles. Use
     the associated type to read the collection
        - error: PhotoServiceError
            - Could Not Parse JSON: contents of base url may be incorrect after
            downloading
            - Bad Request: read the assocaited type for a message
            - Zipp could not be saved
            - Failed to Unzip: unsupported file type
     */
    public func getPhotoCollections(complition: @escaping (_ PhotoResult: PhotoResult) -> ()) {
        if let collection = UserDefaults.standard.cacheDownloadedImages {
            complition(PhotoResult.done(collection))
        } else {
            fetchPhotoCollections(photoResultHandler: complition)
        }
    }
    
    /**
     Comense the fetching of all PhotoCollections. Starting with downloading
     the json data from the baseUrl.
     
     - parameter photoResultHandler: must notify upstream to the origianl caller
     of any progress, error, or complition of downloading
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
            
            /* Fetch Zips and save their unzipped location to aPhotoCollection */
            let dispatchGroup = DispatchGroup()
            for aPhotoCollection in photoCollections {
                dispatchGroup.enter()
                self.fetchZip(from: aPhotoCollection, complition: { (photoResult) in
                    switch photoResult {
                    case .finishedUnzipping(let url):
                        aPhotoCollection.contentUrl = url
                    case .error:
                        photoResultHandler(photoResult)
                    default: break
                    }
                    dispatchGroup.leave()
                })
                
                /* Once finished, call .done([PhotoCollection]) upstream */
                dispatchGroup.notify(queue: .main, execute: {
                    UserDefaults.standard.cacheDownloadedImages = photoCollections
                    photoResultHandler(PhotoResult.done(photoCollections))
                })
            }
        }
        
        task.resume()
        
    }
    
    /**
     Download, unzip, and save the contents, or images, of the
     photoCollection.zipUrl.
     
     - parameter photoCollection: collection to download the zip from
     - parameter Result: either containing the destination url of the unzipped
     download or an error
         - .finishedUnzipping: contains the destination url of the unzipped
         folder of images
         - .error:
             - zipCouldNotSaveToTempFolder
             - failedToUnzip
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    private func fetchZip(from photoCollection: PhotoCollection, complition: @escaping (_ Result: PhotoResult) -> ()) {
        let zipDownloadUrl = photoCollection.zipUrl!
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
     Fires a downloadTask of the shared url session, session, and returns the
     temp location of the download
     
     - parameter url: what to request over the internet
     - parameter DownloadLocation: contains the temp location
     - parameter Error
     */
    private func downloadZip(for url: URL, complition: @escaping (_ DownloadLocation: URL?, _ Error: Error?) -> ()) {
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
    
    /**
     Using the given collection.contentUrl, iterate through the urls for only
     the images excluding the preview image.
     
     - parameter collection: what collection to filter through its images
     - Images: the list of images
     */
    static func collectPhotos(for collection: PhotoCollection, complition: @escaping ([UIImage]?, _ Error: Error?) -> ()) {
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
                /* filter out the _preview image and only collect jpeg and jpg */
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
                DispatchQueue.main.async {
                    complition(images, nil)
                }
            } catch {
                complition(nil, error)
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

