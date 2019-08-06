//
//  RecentChatsTableViewCell.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 26/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit

protocol RecentChatsTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class RecentChatsTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var messageCounterLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageCounterBackground: UIView!
    var indexPath: IndexPath!
    let tapGesture = UITapGestureRecognizer()
    var delegate: RecentChatsTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        messageCounterBackground.layer.cornerRadius =
                messageCounterBackground.frame.width / 2
        tapGesture.addTarget(self, action: #selector(avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func generateCell(recentChat: NSDictionary, indexPath: IndexPath) {
        self.indexPath = indexPath
        nameLabel.text = recentChat[kWITHUSERFULLNAME] as? String
        let decryptedText = Encryption.decryptText(
                chatRoomId: recentChat[kCHATROOMID] as! String,
                encryptedMessage: recentChat[kLASTMESSAGE] as! String)
        lastMessageLabel.text = decryptedText
        messageCounterLabel.text = recentChat[kCOUNTER] as? String
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String) { avatarImage in
                if avatarImage != nil {
                    avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        if recentChat[kCOUNTER] as! Int != 0 {
            messageCounterLabel.text = "\(recentChat[kCOUNTER] as! Int)"
            messageCounterBackground.isHidden = false
            messageCounterLabel.isHidden = false
        } else {
            messageCounterBackground.isHidden = true
            messageCounterLabel.isHidden = true
        }
        var date: Date!
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        dateLabel.text = timeElapsed(date: date)
    }

    @objc func avatarTap() {
        delegate?.didTapAvatarImage(indexPath: indexPath)
    }
}
