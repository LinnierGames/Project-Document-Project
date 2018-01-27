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
        let request = URLRequest(url: baseUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        
        /* Fetch json of list of photo collections */
        var jsonTask = DownloadService.shared.download(request: request)
        // jsonTask.progressHandler = { progress in } //too small of a download to show progress
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
                    var downloadTask = self.downloadZip(for: aPhotoCollection.zipUrl!, complition: { (result) in
                        defer { dispatchGroup.leave() }
                        switch result {
                        case .success(let zipData):
                            do {
                                let destinationFilePath = try self.unzip(data: zipData)
                                
                                /* Rename unzipped folder to collection title and reference location of unzipped folder */
                                let fileManager = FileManager.default
                                let unzippedFolderTitle = aPhotoCollection.zipUrl!.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "+", with: " ")
                                let collectionCacheFileUrl = destinationFilePath.appendingPathComponent(unzippedFolderTitle, isDirectory: true)
                                let newCollectionCacheFileUrl = destinationFilePath.appendingPathComponent(aPhotoCollection.title, isDirectory: true)
                                if collectionCacheFileUrl.lastPathComponent.lowercased() != newCollectionCacheFileUrl.lastPathComponent.lowercased() {
                                    try? fileManager.removeItem(at: newCollectionCacheFileUrl)
                                }
                                try fileManager.moveItem(at: collectionCacheFileUrl, to: newCollectionCacheFileUrl) //Rename old title to new title
                                
                                aPhotoCollection.contentUrl = newCollectionCacheFileUrl
                            } catch {
                                //TODO: handle throw when unzipping
                            }
                           
                        case .failure(let err):
                            print("ERROR \(err.localizedDescription)")
                        }
                    })
                    downloadTask.progressHandler = { progress in
                        self.delegate?.photoCollectionService?(self, didRecivedProgress: progress, for: aPhotoCollection)
                    }
                    downloadTask.resume()
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
     <#Lorem ipsum dolor sit amet.#>
     
     - parameter <#bar#>: <#Consectetur adipisicing elit.#>
     
     - returns: <#Sed do eiusmod tempor.#>
     */
    private func downloadZip(for zipUrl: URL, complition: @escaping (ResultType<Data>) -> ()) -> PhotoCollectionDataTask {
        let request = URLRequest(url: zipUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        
        let downloadTask = DownloadService.shared.download(request: request)
        downloadTask.completionHandler = complition
        
        return downloadTask
    }
    
    
    /**
     Unzip and save the contents, or images, of the url.
     
     - parameter data: collection to download the zip from
     
     - returns: the url of the unzipped folder
     */
    private func unzip(data zipData: Data) throws -> URL {
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
            
            return imagesCacheFolderFilePath
        } catch {
            throw error
        }
    }

    /**
     Fires a downloadTask of the shared url session, session, and returns the
     temp location of the download
     
     - parameter url: what to request over the internet
     - parameter DownloadLocation: contains the temp location
     - parameter Error
     */
    @available(*, deprecated)
    private func downloadZip(for url: URL, complition: @escaping (_ DownloadLocation: URL?, _ Error: Error?) -> ()) {
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

