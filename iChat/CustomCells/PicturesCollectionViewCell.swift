//
//  PicturesCollectionViewCell.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 31/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit

class PicturesCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    func generateCell(image: UIImage) {
        imageView.image = image
    }
}
