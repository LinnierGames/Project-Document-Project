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
    @IBOutlet weak var imageview: UIImageView!
    
    func configure(photoCollection: PhotoCollection) {
        labelTitle.text = photoCollection.title
        imageview.image = photoCollection.previewImage
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
