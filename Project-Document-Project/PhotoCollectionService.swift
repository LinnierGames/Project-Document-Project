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

@objc protocol PhotoCollectionServiecDelegate {
    @objc optional func photoCollectionService(_ service: PhotoCollectionService, didFinishDownloadingCollection collection: [PhotoCollection])
    
    @objc optional func photoCollectionService(_ service: PhotoCollectionService, didRecivedProgress progress: Double, for photoCollection: PhotoCollection)
}

class PhotoCollectionService: NSObject {
    
    lazy var session: URLSession = {
        return URLSession.shared
    }()
    
    var photoCollectionDataTasks: [PhotoCollection: PhotoCollectionDataTask] = [:]
    
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
    
    weak var delegate: PhotoCollectionServiecDelegate?
    
    public enum PhotoResult {
        case done([PhotoCollection])
        case error(PhotoServiceError)
    }
    
    public enum PhotoServiceError {
        case couldNotParseJSON
        case badRequest(String)
        case zipCouldNotSaveToTempFolder
        case FailedToUnzip
    }
    
    /** API call to collect the list of photo collections */
    public var baseUrl = URL(string: "https://s3-us-west-2.amazonaws.com/mob3/image_collection.json")!
    
    typealias ProgressType = (Double) -> ()
    
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
    public func getPhotoCollections(progress: ProgressType? = nil, complition: @escaping (_ PhotoResult: PhotoResult) -> ()) {
        if let collection = UserDefaults.standard.cacheDownloadedImages {
            complition(PhotoResult.done(collection))
        } else {
            fetchPhotoCollections(progress: progress, photoResultHandler: complition)
        }
    }
    
    /**
     Comense the fetching of all PhotoCollections. Starting with downloading
     the json data from the baseUrl.
     
     - parameter photoResultHandler: must notify upstream to the origianl caller
     of any progress, error, or complition of downloading
     */
    private func fetchPhotoCollections(progress: ProgressType? = nil, photoResultHandler: @escaping (PhotoResult) -> Void) {
        let request = URLRequest(url: baseUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        
        /* Fetch json of list of photo collections */
        var jsonTask = DownloadService.shared.download(request: request)
        jsonTask.progressHandler = progress
        jsonTask.completionHandler = { result in
            switch result {
            case .success(let jsonData):
                /* json -> Models */
                guard
                    let photoCollections = try? JSONDecoder().decode([PhotoCollection].self, from: jsonData)
                    else {
                        return photoResultHandler(.error(.couldNotParseJSON))
                }
                
                self.delegate?.photoCollectionService?(self, didFinishDownloadingCollection: photoCollections)
                
                /* Fetch Zips and save their unzipped location to aPhotoCollection */
                let dispatchGroup = DispatchGroup()
                for aPhotoCollection in photoCollections {
                    dispatchGroup.enter()
                    /* download the zip */
                    let request = URLRequest(url: aPhotoCollection.zipUrl!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
                    var downloadTask = DownloadService.shared.download(request: request)
                    downloadTask.completionHandler = { result in
                        defer { dispatchGroup.leave() }
                        switch result {
                        case .success(let zipData):
                            /* write zip data to disk */
                            let fileManager = FileManager.default
                            let tmpFolder = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.deletingLastPathComponent().appendingPathComponent("tmp", isDirectory: true)
                            let zipFileName = UUID().uuidString.appending(".tmp")
                            let zipUrlToSaveAt = tmpFolder.appendingPathComponent(zipFileName)
                            do {
                                try zipData.write(to: zipUrlToSaveAt)
                                
                                /* unzip contents to proper location */
                                let imagesCacheFolderFilePath = FileManager.default.imagesCacheFolder()
                                try Zip.unzipFile(zipUrlToSaveAt, destination: imagesCacheFolderFilePath)
                                
                                /* Rename unzipped folder to collection title and reference location of unzipped folder */
                                let unzippedFolderTitle = aPhotoCollection.zipUrl!.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "+", with: " ")
                                let collectionCacheFileUrl = imagesCacheFolderFilePath.appendingPathComponent(unzippedFolderTitle, isDirectory: true)
                                let newCollectionCacheFileUrl = imagesCacheFolderFilePath.appendingPathComponent(aPhotoCollection.title, isDirectory: true)
                                if collectionCacheFileUrl.lastPathComponent.lowercased() != newCollectionCacheFileUrl.lastPathComponent.lowercased() {
                                    try? fileManager.removeItem(at: newCollectionCacheFileUrl)
                                }
                                try fileManager.moveItem(at: collectionCacheFileUrl, to: newCollectionCacheFileUrl) //Rename old title to new title
                                
                                aPhotoCollection.contentUrl = newCollectionCacheFileUrl
                            } catch {
                                print("ERROR SAVING ZIP \(error.localizedDescription)")
                            }
                        case .failure(let err):
                            print("ERROR \(err.localizedDescription)")
                        }
                    }
                    downloadTask.progressHandler = { progress in
                        self.delegate?.photoCollectionService?(self, didRecivedProgress: progress, for: aPhotoCollection)
                    }
                    downloadTask.resume()
                    
                    //self.photoCollectionDataTasks[aPhotoCollection] = downloadTask
                }
                /* Once finished, call .done([PhotoCollection]) upstream */
                dispatchGroup.notify(queue: .main, execute: {
                    UserDefaults.standard.cacheDownloadedImages = photoCollections
                    //TODO: Check if any errors were made
                    photoResultHandler(PhotoResult.done(photoCollections))
                })
            case .failure(let err):
                photoResultHandler(.error(.badRequest(err.localizedDescription)))
            }
        }
        jsonTask.resume()
        
        
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
    private func fetchZip(from photoCollection: PhotoCollection, progress: ProgressType? = nil, complition: @escaping (_ Result: PhotoResult) -> ()) {
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
//                try Zip.unzipFile(zippedFilePath, destination: imagesCacheFolderFilePath)
                
                /* Rename unzipped folder to collection title and reference location of unzipped folder */
                let unzippedFolderTitle = zipDownloadUrl.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "+", with: " ")
                let collectionCacheFileUrl = imagesCacheFolderFilePath.appendingPathComponent(unzippedFolderTitle, isDirectory: true)
                let newCollectionCacheFileUrl = imagesCacheFolderFilePath.appendingPathComponent(photoCollection.title, isDirectory: true)
//                try FileManager.default.moveItem(at: collectionCacheFileUrl, to: newCollectionCacheFileUrl) //Rename old title to new title
                
//                complition(.finishedUnzipping(newCollectionCacheFileUrl))
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
    private func downloadZip(for url: URL, progress: ProgressType? = nil, complition: @escaping (_ DownloadLocation: URL?, _ Error: Error?) -> ()) {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
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

