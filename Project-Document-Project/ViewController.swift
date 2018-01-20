//
//  ViewController.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    var collections: [PhotoCollection] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - RETURN VALUES
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        let photoCollection = collections[indexPath.row]
        cell.configure(photoCollection: photoCollection)
        
        return cell
    }
    
    // MARK: - VOID METHODS
    
    private func updateUI() {
        PhotoCollectionService().fetchPhotoCollections { [unowned self] (fetchedCollections) in
            self.collections = fetchedCollections
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
    
    // MARK: - IBACTIONS
    
    // MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateUI()
        tableView.rowHeight = 96
    }
}

