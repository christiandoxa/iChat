//
//  BackgroundCollectionViewCell.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 02/08/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit

class BackgroundCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    func generateCell(image: UIImage) {
        imageView.image = image
    }
}
