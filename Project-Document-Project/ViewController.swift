//
//  ViewController.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, PhotoCollectionServiecDelegate {
    
    private enum ViewState {
        case DownloadingCollections
        case DownloadingImages
        case Success
        case Failed(Error)
    }
    
    private var viewState: ViewState = .DownloadingCollections
    
    var collections: [PhotoCollection] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var collectionDownloadProgress: [PhotoCollection: Double] = [:]

    // MARK: - RETURN VALUES
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let photoCollection = collections[indexPath.row]
        let downloadProgress = collectionDownloadProgress[photoCollection] ?? 0.0
        let isDownloading = downloadProgress != 1.0
        
        if isDownloading { //downloading zip
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell downloading", for: indexPath) as! CustomTableViewCell
            
            cell.configure(photoCollection: photoCollection, progress: downloadProgress)
            
            return cell
        } else { //done
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
            
            cell.configure(photoCollection: photoCollection)
            
            return cell
        }
    }
    
    // MARK: - VOID METHODS
    
    private func updateUI() {
        let photoService = PhotoCollectionService()
        photoService.delegate = self
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        photoService.getPhotoCollections { (result) in
            switch result {
            case .done(let photos):
                self.collections = photos
                //TODO: map { $0 = 1.0 }
                for c in self.collections {
                    self.collectionDownloadProgress[c] = 1.0
                }
                UIView.animate(withDuration: 0.25, animations: {
                    self.navigationItem.prompt = nil
                })
            case .error(let error):
                self.navigationItem.prompt = "Unexpected Error"
                let alertError = UIAlertController(title: nil, message: String(describing: error), preferredStyle: .alert)
                alertError.addAction(UIAlertAction(title: "Dismiss", style: .default))
                self.present(alertError, animated: true)
            }
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "show photos":
                let vc = segue.destination as! PhotoCollectionViewController
                let cell = sender as! CustomTableViewCell
                if let indexPath = tableView.indexPath(for: cell) {
                    let selectedPhotoCollection = collections[indexPath.row]
                    vc.photoCollection = selectedPhotoCollection
                }
                
            default: break
            }
        }
    }
    
    private func updateRow(for photoCollection: PhotoCollection) {
        guard
            let indexOfPhotoColletion = collections.index(where: { $0 == photoCollection }),
            let cell = tableView.cellForRow(at: IndexPath(row: indexOfPhotoColletion.hashValue, section: 0)) as! CustomTableViewCell?,
            let progress = collectionDownloadProgress[photoCollection]
            else { return print("could find index for progress") }
        
        if progress < 1.0 {
            cell.configure(photoCollection: photoCollection, progress: progress)
        } else {
            tableView.reloadRows(at: [IndexPath(row: indexOfPhotoColletion.hashValue, section: 0)], with: .none)
        }
        
    }
    
    // MARK: Photo Collection Service Delegate
    
    func photoCollectionService(_ service: PhotoCollectionService, didFinishDownloadingCollection collection: [PhotoCollection]) {
        self.navigationItem.prompt = "Downloading Images"
        self.collections = collection
    }
    
    func photoCollectionService(_ service: PhotoCollectionService, didRecivedProgress progress: Double, for photoCollection: PhotoCollection) {
        collectionDownloadProgress[photoCollection] = progress
        
        self.updateRow(for: photoCollection)
    }
    
    func photoCollectionService(_ service: PhotoCollectionService, didFinishDownloadingFor photoCollection: PhotoCollection) {
        self.updateRow(for: photoCollection)
    }
    
    // MARK: - IBACTIONS
    
    // MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateUI()
        tableView.rowHeight = 96
    }
}

