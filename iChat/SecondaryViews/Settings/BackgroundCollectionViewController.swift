//
//  BackgroundCollectionViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 02/08/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD

private let reuseIdentifier = "Cell"

class BackgroundCollectionViewController: UICollectionViewController {
    var backgrounds: [UIImage] = []
    let userDefaults = UserDefaults.standard
    private let imagesNameArray = ["bg0", "bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "b7",
                                   "bg8", "bg9", "bg10", "bg11"]

    override func viewDidLoad() {
        navigationItem.largeTitleDisplayMode = .never
        setupImageArray()
        let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self,
                action: #selector(resetToDefault))
        navigationItem.rightBarButtonItem = resetButton
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return backgrounds.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseIdentifier, for: indexPath)
                as! BackgroundCollectionViewCell
        cell.generateCell(image: backgrounds[indexPath.row])
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        userDefaults.set(imagesNameArray[indexPath.row], forKey: kBACKGROUBNDIMAGE)
        userDefaults.synchronize()
        ProgressHUD.showSuccess("Set!")
    }

    @objc func resetToDefault() {
        userDefaults.removeObject(forKey: kBACKGROUBNDIMAGE)
        userDefaults.synchronize()
        ProgressHUD.showSuccess("Set!")
    }

    func setupImageArray() {
        for imageName in imagesNameArray {
            let image = UIImage(named: imageName)
            if image != nil {
                backgrounds.append(image!)
            }
        }
    }
}
