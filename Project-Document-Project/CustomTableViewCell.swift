//
//  CustomTableViewCell.swift
//  Project-Document-Project
//
//  Created by Erick Sanchez on 1/19/18.
//  Copyright © 2018 LinnierGames. All rights reserved.
//

import UIKit

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var loadingView: UIImageView!
    
    func configure(photoCollection: PhotoCollection) {
        labelTitle?.text = photoCollection.title
        imageview?.image = photoCollection.previewImage
    }
    
    func configure(photoCollection: PhotoCollection, progress: Double) {
        labelTitle?.text = photoCollection.title
        if progress < 1.0 {
            labelSubtitle?.text = "Downloading Zip.. \(String(format: "%.2f%", arguments: [progress * 100.0]))%"
        } else {
            labelSubtitle?.text = "Unzipping.."
        }
        
        let progressWidth = self.frame.size.width * CGFloat(progress)
        UIView.animate(withDuration: 0.01, delay: 0, options: .beginFromCurrentState, animations: { [unowned self] in
            self.loadingView?.frame = CGRect(x: 0, y: 0, width: progressWidth, height: self.frame.size.height)
        }, completion: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
