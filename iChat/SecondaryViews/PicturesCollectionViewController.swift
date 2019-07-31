//
//  PicturesCollectionViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 31/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class PicturesCollectionViewController: UICollectionViewController {
    var allImages: [UIImage] = []
    var allImageLinks: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "All Pictures"
        if allImageLinks.count > 0 {
            downloadImages()
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allImages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                for: indexPath) as! PicturesCollectionViewCell
        cell.generateCell(image: allImages[indexPath.row])
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photos = IDMPhoto.photos(withImages: allImages)
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayDoneButton = false
        browser?.setInitialPageIndex(UInt(indexPath.row))
        present(browser!, animated: true)
    }

    func downloadImages() {
        for imageLink in allImageLinks {
            downloadImage(imageUrl: imageLink) { image in
                if image != nil {
                    self.allImages.append(image!)
                    self.collectionView.reloadData()
                }
            }
        }
    }
}
