//
//  ViewController.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/17/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var collections: [PhotoCollection] = [] {
        didSet {
            //update table
        }
    }

    // MARK: - RETURN VALUES
    
    // MARK: - VOID METHODS
    
    /*
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     if let identifier = segue.identifier {
     switch identifier {
     case <#pattern#>:
     <#code#>
     default:
     break
     }
     }
     }*/
    
    private func updateUI() {
        PhotoCollectionService().fetchPhotoCollections { [unowned self] (fetchedCollections) in
            self.collections = fetchedCollections
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBACTIONS
    
    // MARK: - LIFE CYCLE
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
        
    }

}

