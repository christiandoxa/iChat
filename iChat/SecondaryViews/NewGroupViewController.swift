//
//  NewGroupViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 2019-08-04.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD

class NewGroupViewController: UIViewController, UICollectionViewDataSource,
        UICollectionViewDelegate, GroupMemberCollectionViewCellDelegate {
    @IBOutlet weak var editAvatarButtonOutlet: UIButton!
    @IBOutlet weak var groupIconImageView: UIImageView!
    @IBOutlet weak var groupSubjectTextField: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    var memberIds: [String] = []
    var allMembers: [FUser] = []
    var groupIcon: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        groupIconImageView.isUserInteractionEnabled = true
        groupIconImageView.addGestureRecognizer(iconTapGesture)
        updateParticipantsLabel()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMembers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                for: indexPath) as! GroupMemberCollectionViewCell
        cell.delegate = self
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
        return cell
    }

    @objc func createButtonPressed(_ sender: Any) {
        print("create tap")
    }

    @IBAction func groupIconTapped(_ sender: Any) {
        print("icon tap")
    }

    @IBAction func editIconButtonPressed(_ sender: Any) {
        print("edit tap")
    }

    func didClickDeleteButton(indexPath: IndexPath) {
        allMembers.remove(at: indexPath.row)
        memberIds.remove(at: indexPath.row)
        collectionView.reloadData()
        updateParticipantsLabel()
    }

    func updateParticipantsLabel() {
        participantsLabel.text = "PARTICIPANTS: \(allMembers.count)"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Create", style: .plain, target: self,
                    action: #selector(createButtonPressed))
        ]
        navigationItem.rightBarButtonItem!.isEnabled = allMembers.count > 0
    }
}
