//
//  UserTableViewCell.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 24/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    var indexPath: IndexPath!
    var delegate: UserTableViewCellDelegate?
    let tapGestureRecognizer = UITapGestureRecognizer()

    override func awakeFromNib() {
        super.awakeFromNib()
        tapGestureRecognizer.addTarget(self, action: #selector(avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func generateCellWith(fUser: FUser, indexPath: IndexPath) {
        self.indexPath = indexPath
        fullNameLabel.text = fUser.fullname
        if fUser.avatar != "" {
            imageFromData(pictureData: fUser.avatar) { avatarImage in
                if avatarImage != nil {
                    avatarImageView.image = avatarImage?.circleMasked
                }
            }
        }
    }

    @objc func avatarTap() {
        delegate?.didTapAvatarImage(indexPath: indexPath)
    }
}
