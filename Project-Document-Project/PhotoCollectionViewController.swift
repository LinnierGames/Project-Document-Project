//
//  PhotoCollectionViewController.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/19/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cell"

class PhotoCollectionViewController: UICollectionViewController {
    
    var photoCollection: PhotoCollection?
    
    private var collectionOfImages: [UIImage]? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    // MARK: - RETURN VALUES
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionOfImages?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
        
        // Configure the cell
        let photo = collectionOfImages![indexPath.row]
        cell.thumbnailView.image = photo
        
        return cell
    }
    
    // MARK: - VOID METHODS
    
    private func updateUI() {
        guard
            let collection = photoCollection,
            let photoCollectionFilePath = collection.contentUrl
            else {
            return
        }
        /*collect urls, excluding the preview image*/
        do {
            let fileManager = FileManager.default
            let photoUrls = try fileManager.contentsOfDirectory(at: photoCollectionFilePath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                .filter { (url) -> Bool in
                    return url.lastPathComponent.contains("_preview") == false
                }.filter({ (url) -> Bool in
                    return url.pathExtension.contains("jpeg") || url.pathExtension.contains("jpg")
                })
            /*decode into images and update the collection view*/
            collectionOfImages = []
            for imageFilePath in photoUrls {
                if let image = UIImage(contentsOfFile: imageFilePath.relativePath) {
                    collectionOfImages!.append(image)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        collectionView!.reloadData()
    }
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
    
    // MARK: - IBACTIONS
    
    // MARK: - LIFE CYCLE
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateUI()
    }

}
