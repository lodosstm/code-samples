//
//  SettingsListVC.swift
//
//  Created by dev on 12/15/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit

class SettingsListVC: UIViewController {
    
    var currentUser = Contact()
    @IBOutlet var avatarIV: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateProfileData()
    }
    
    //MARK: - Configuration -
    
    func setupUI() {
        setupNavBar()
        setupAvatarImageView()
    }
    
    func setupNavBar() {
        if let navController = self.navigationController {
            navigationItem.title = UIConstants.kSettingsScreenTitle
            let titleFont = UIFont(name: UIConstants.kFontOpenSansSemibold,
                                   size: CGFloat(UIConstants.kNavBarTitleFontSize))
            let textAttributes: [String:Any] = [NSForegroundColorAttributeName:.blue,
                                                NSFontAttributeName:titleFont]
            navController.navigationBar.titleTextAttributes = textAttributes
        }
    }
    
    func setupAvatarImageView() {
        avatarIV.layer.cornerRadius = avatarIV.frame.size.height / 2
        avatarIV.clipsToBounds = true
    }
    
    //MARK: - UI -
    
    func updateProfileData() {
        fillProfileWithData()
        updateCurrentUserFromBackendServer()
    }
    
    func fillProfileWithData() {
        currentUser = UserSession.getCurrentUser()
        setupUserAvatarWith(url: currentUser.avatarURL)
    }
    
    func setupUserAvatarWith(url:String?) {
        if let avatarURL = url {
            if !avatarURL.isEmpty {
                self.avatarIV.setImageWith(URL(string: avatarURL)!)
            }
        }
    }
    
    func showLogoutConfirmationAlert() {
        let alertController = UIAlertController(title: UIConstants.kLogoutAlertTitle, message: UIConstants.kLogoutAlertMessage, preferredStyle: .alert)
        
        let noAction = UIAlertAction(title: UIConstants.kLogoutAlertButtonNo, style: .default, handler: nil)
        alertController.addAction(noAction)
        
        let yesAction = UIAlertAction(title: UIConstants.kLogoutAlertButtonYes, style: .default) { (action) in
            self.performLogoutRequest()
        }
        alertController.addAction(yesAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Data -
    
    func updateCurrentUserFromBackendServer() {
        ProfileSocketsManager.getCurrentUserSettingsWith { [weak self] (responseDict) in
            if responseDict[DictionaryKey.kErrorParameter] != nil {
                print("ERROR! Can't get user profile from server.")
            } else {
                UserSession.saveCurrentUserFrom(dictionary: responseDict)
                if let weakSelf = self {
                    weakSelf.fillProfileWithData()
                }
            }
        }
    }
    
    //MARK: - Logout -
    
    func performLogoutRequest() {
        let logoutCompletion = { [weak self] () -> Void in
            DataClearingManager.clearDataOnLogout()
            if let weakSelf = self {
                weakSelf.returnToLandingScreen()
            }
        }
        
        AuthNetworkManager.logoutWith(success: { (response) in
                logoutCompletion()
            }) { (errorMessage) in
                print("ERROR! Logout error: %@", errorMessage)
        }
    }
    
    //MARK: - IBActions -
    
    @IBAction func logoutButtonPressed(_ sender: AnyObject) {
        self.showLogoutConfirmationAlert()
    }
    
    //MARK: - Navigation -
    
    func returnToLandingScreen() {
        self.performSegue(withIdentifier: "returnToLoginVC", sender: self)
    }
}
