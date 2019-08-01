//
//  SettingsTableViewController.swift
//  iChat
//
//  Created by Christian Doxa Hamasiah on 24/07/19.
//  Copyright © 2019 Christian Doxa Hamasiah. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var deleteButtonOutlet: UIButton!
    @IBOutlet weak var showAvatarStatusSwitch: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!
    var avatarSwitchStatus = false
    let userDefaults = UserDefaults.standard
    var firstLoad: Bool?

    override func viewDidAppear(_ animated: Bool) {
        if FUser.currentUser() != nil {
            setupUI()
            loadUserDefaults()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.tableFooterView = UIView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 5
        }
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 30
    }

    @IBAction func cleanCacheButtonPressed(_ sender: Any) {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                    atPath: getDocumentsUrl().path)
            for file in files {
                try FileManager.default.removeItem(
                        atPath: "\(getDocumentsUrl().path)/\(file)")
            }
            ProgressHUD.showSuccess("Cache cleaned.")
        } catch {
            ProgressHUD.showError("Couldn't clean Media file")
        }
    }

    @IBAction func showAvatarSwitchValueChanged(_ sender: Any) {
        avatarSwitchStatus = (sender as AnyObject).isOn
        saveUserDefaults()
    }

    @IBAction func tellAFriendButtonPressed(_ sender: Any) {
        let text = "Hey! Let's chat on iChat \(kAPPURL)"
        let objectsToShare: [Any] = [text]
        let activityViewController = UIActivityViewController(
                activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.setValue("Lets Chat on Ichat", forKey: "subject")
        present(activityViewController, animated: true)
    }

    @IBAction func logOutButtonPressed(_ sender: Any) {
        FUser.logOutCurrentUser { success in
            if success {
                self.showLoginView()
            }
        }
    }

    @IBAction func deleteAccountButtonPressed(_ sender: Any) {
        let optionMenu = UIAlertController(title: "Delete Account",
                message: "Are you sure you want to delete the account?",
                preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { alert in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { alert in

        }
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        if UI_USER_INTERFACE_IDIOM() == .pad {
            if let currentPopoverpresentioncontroller = optionMenu
                    .popoverPresentationController {
                currentPopoverpresentioncontroller.sourceView = deleteButtonOutlet
                currentPopoverpresentioncontroller.sourceRect = deleteButtonOutlet
                        .bounds
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                present(optionMenu, animated: true)
            }
        } else {
            present(optionMenu, animated: true)
        }
    }

    func showLoginView() {
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcome")
        self.present(mainView, animated: true)
    }

    func setupUI() {
        let currentUser = FUser.currentUser()!
        fullNameLabel.text = currentUser.fullname
        if currentUser.avatar != "" {
            imageFromData(pictureData: currentUser.avatar) { avatarImage in
                if avatarImage != nil {
                    avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                as? String {
            versionLabel.text = version
        }
    }

    func deleteUser() {
        //delete locally
        userDefaults.removeObject(forKey: kPUSHID)
        userDefaults.removeObject(forKey: kCURRENTUSER)
        userDefaults.synchronize()
        //delete from firebase
        reference(.User).document(FUser.currentId()).delete()
        FUser.deleteUser { error in
            if error != nil {
                DispatchQueue.main.async {
                    ProgressHUD.showError("Couldn't delete user")
                }
                return
            }
            self.showLoginView()
        }
    }

    func saveUserDefaults() {
        userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
        userDefaults.synchronize()
    }

    func loadUserDefaults() {
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
            userDefaults.synchronize()
        }
        avatarSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
        showAvatarStatusSwitch.isOn = avatarSwitchStatus
    }
}
