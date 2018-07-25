//
//  DriveVC.swift
//
//  Created by dev on 12/21/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit
import SWRevealTableViewCell
import MobileCoreServices
import AVKit
import AVFoundation

class DriveVC : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    @IBOutlet var driveTV: UITableView!
    @IBOutlet var driveCV: UICollectionView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var menuView: UIView!
    @IBOutlet var tableRefreshControl: UIRefreshControl!
    @IBOutlet var gridButton: UIButton!
    @IBOutlet var dismissMenuControl: UIControl!
    @IBOutlet var selectButton: UIButton!
    @IBOutlet var createFolderButton: UIButton!
    @IBOutlet var shadowView: UIControl!
    @IBOutlet var folderContainerCenterConstraint: NSLayoutConstraint!
    @IBOutlet var shareDialogContainerCenterConstraint: NSLayoutConstraint!
    @IBOutlet var shareDialogHeightConstraint: NSLayoutConstraint!
    @IBOutlet var deleteConfirmationCenterConstraint: NSLayoutConstraint!
    @IBOutlet var createFolderContainer: UIView!
    @IBOutlet var shareDialogContainer: UIView!
    @IBOutlet var deleteConfirmationView: UIView!
    @IBOutlet var emptyDriveView: UIView!
    @IBOutlet var emptyDriveLabel: UILabel!
    var uploadButton = UIBarButtonItem()
    var backButton = UIBarButtonItem()
    
    var parentURI = ""
    var drives = [Drive]()
    var selectedFiles = [Drive]()
    var dataSource = DriveDataSource(parentURI: "")
    var imagePickeringInProgress = false
    var isRefreshing = false
    var selectedChildDrive = Drive()
    var photosToUploadArray = [UIImage]()
    var shareDialog = ShareDialogVC()
    var imagePicker = AGImagePickerController()
    var tempFilePath = ""
    
    //MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        initDriveDataSource()
        setupImagePicker()
        hideShareDialogContainer(animated: false)
        hideCreateFolderContainer(animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DriveManager.removeTempFile(fileURL: tempFilePath)
        subscribe()
        setupDriveMode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (DriveModeManager.sharedInstance.mode == DriveMode.GridWithSelectionDriveMode) {
            switchToCollectionView()
        } else if (DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode) {
            switchToTableView()
        }
        
        hideMenu(animated: false)
        unsubscribe()
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Notifications -
    
    func subscribe() {
        NotificationCenter.default.addObserver(self, selector: #selector(DriveVC.shareSelectedFiles), name: NSNotification.Name(LocalNotificationKey.kShareButtonPressedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DriveVC.checkIfFileShouldBeDeleted), name: NSNotification.Name(LocalNotificationKey.kDeleteButtonPressedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DriveVC.downloadSelectedFiles), name: NSNotification.Name(LocalNotificationKey.kDownloadButtonPressedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DriveVC.refreshData), name: NSNotification.Name(LocalNotificationKey.kDriveRefreshInfoNotification), object: nil)
    }
    
    func unsubscribe() {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Init -
    
    func setupUI() {
        driveCV.delegate = self
        
        setupLoadingDriveMessage()
        showEmptyDriveView()
        setupNavBar()
        
        hideSeparators()
        setupRefreshControl()
        setupShareDialog()
        setupGestureRecognizer()
    }
    
    func hideSeparators() {
        driveTV.tableFooterView = UIView()
    }
    
    func setupShareDialog() {
        shareDialogHeightConstraint.constant = UIScreen.main.bounds.size.height - CGFloat(UIConstants.kDriveShareDialogTopMargin) - CGFloat(UIConstants.kDriveShareDialogBottomMargin) - CGFloat(UIConstants.kDriveContainersCenterMargin)
        view.setNeedsLayout()
    }
    
    func setupGestureRecognizer() {
        let gridRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DriveVC.switchToGridSelectionMode))
        gridRecognizer.minimumPressDuration = 0.5
        driveCV.addGestureRecognizer(gridRecognizer)
        
        let tableRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DriveVC.switchToTableSelectionMode))
        tableRecognizer.minimumPressDuration = 0.5
        driveTV.addGestureRecognizer(tableRecognizer)
    }
    
    //MARK: - Data source -
    
    func initDriveDataSource() {
        showActivityIndicator()
        dataSource = DriveDataSource(parentURI: parentURI)
        
        dataSource.getDriveDataFromDBWith { [weak self] in
            if let weakself = self {
                DispatchQueue.main.async {
                    weakself.reloadUI()
                    if weakself.dataSource.filesCount() > 0 {
                        weakself.hideEmptyDriveView()
                        weakself.hideActivityIndicator()
                    }
                }
            }
        }
        
        downloadNextPageOfFiles()
    }
    
    func downloadNextPageOfFiles() {
        if dataSource.allFilesDownloaded {
            return
        }
        
        dataSource.getDriveDataFromServerWith(success: { [weak self] in
            if let weakself = self {
                DispatchQueue.main.async {
                    if weakself.dataSource.filesCount() > 0 {
                        weakself.hideEmptyDriveView()
                        weakself.reloadUI()
                    } else {
                        weakself.setupEmptyDriveMessage()
                        weakself.showEmptyDriveView()
                    }
                    weakself.hideActivityIndicator()
                }
            }
        }) { [weak self] in
            if let weakself = self {
                DispatchQueue.main.async {
                    if weakself.dataSource.filesCount() > 0 {
                        weakself.hideEmptyDriveView()
                    } else {
                        weakself.setupErrorDriveMessage()
                        weakself.showEmptyDriveView()
                    }
                    weakself.hideActivityIndicator()
                }
            }
        }
    }
    
    func canCreateFolders() -> Bool {
        var canCreateFolders = false
        
        if let firstDrive = dataSource.driveAt(index: 0) {
            canCreateFolders = firstDrive.allowedToCreate && !dataSource.isRootFolder()
        } else {
            if let parentDrive = DriveDB.getDrivesWith(uri: parentURI).first {
                canCreateFolders = parentDrive.allowedToCreate && !dataSource.isRootFolder()
            }
        }
        
        return canCreateFolders
    }
    
    //MARK: - View operations -
    
    func disableControlsWithLeaveAbility() {
        uploadButton.isEnabled = false
        backButton.isEnabled = false
        driveTV.isUserInteractionEnabled = false
    }
    
    func enableControlsWithLeaveScreenAbility() {
        uploadButton.isEnabled = true
        backButton.isEnabled = true
        driveTV.isUserInteractionEnabled = true
    }
    
    func canNavigateToOtherScreen() -> Bool {
        return (uploadButton.isEnabled || backButton.isEnabled || driveTV.isUserInteractionEnabled) && !imagePickeringInProgress
    }
    
    //MARK: - Navigation Bar -
    
    func setupNavBar() {
        setupNavTitle()
        setupBackButton()
        setupNavBarItems()
        setupMenu()
        setupDriveMode()
    }
    
    func setupNavTitle() {
        var parentString = ""
        
        if dataSource.isRootFolder() {
            parentString = UIConstants.kDriveDefaultTitle
        }
        if let curDrive = DriveDB.getDrivesWith(uri: parentURI).first, parentString.isEmpty {
            if let driveName = curDrive.name {
                parentString = driveName
            }
        }
        let curUser = UserDB.getCurrentUserFromDB()
        if parentString == curUser.contactID {
            parentString = UIConstants.kMyDriveTitle
        }
        
        if let navController = self.navigationController {
            navigationItem.title = parentString
            let titleFont = UIFont(name: UIConstants.kFontOpenSansSemibold, size: CGFloat(UIConstants.kNavBarTitleFontSize))
            let textAttributes: [String:Any] = [NSForegroundColorAttributeName:UIColor.blue,
                                                NSFontAttributeName:titleFont]
            navController.navigationBar.titleTextAttributes = textAttributes
        }
    }
    
    func setupBackButton() {
        if !dataSource.isRootFolder() {
            backButton = UIBarButtonItem(image: UIImage(named:UIConstants.kBackIconImageName), style: .plain, target: self, action: #selector(DriveVC.navigateUpTheTree))
            backButton.tintColor = UIColor.gray
            navigationItem.leftBarButtonItem = backButton
        }
    }
    
    func setupNavBarItems() {
        var items = [UIBarButtonItem]()
        let isTable = DriveModeManager.sharedInstance.mode == DriveMode.TableDriveMode || DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode
        if isTable {
            let cancelButton = UIBarButtonItem(title: UIConstants.kCancelButtonTitle, style: .plain, target: self, action: #selector(DriveVC.cancelSelection))
            cancelButton.tintColor = UIColor.gray
            items.append(cancelButton)
        } else {
            let menuButton = UIBarButtonItem(image: UIImage(named:UIConstants.kMenuIconImageName), style: .plain, target: self, action: #selector(DriveVC.showMenu))
            menuButton.tintColor = UIColor.gray
            items.append(menuButton)
            
            if canCreateFolders() || dataSource.isRootFolder() {
                uploadButton = UIBarButtonItem(image: UIImage(named:UIConstants.kUploadIconImageName), style: .plain, target: self, action: #selector(DriveVC.showFilesListFromDeviceToUpload))
                uploadButton.tintColor = UIColor.gray
                items.append(uploadButton)
            }
            
        }
        navigationItem.rightBarButtonItems = items
    }
    
    //MARK: - Image Picker -
    
    func setupImagePicker() {
        imagePicker = AGImagePickerController(failureBlock: { [weak self] (error) in
            if let weakself = self {
                weakself.photosToUploadArray.removeAll()
                weakself.imagePicker.dismiss(animated: true, completion: {
                    weakself.imagePickeringInProgress = false
                })
            }
            }, andSuccessBlock: { [weak self] (info) in
                if let weakself = self, let infoArray = info {
                    weakself.photosToUploadArray.removeAll()
                    for item in infoArray {
                        weakself.photosToUploadArray.append(item as! UIImage)
                    }
                    UIApplication.shared.statusBarStyle = .default
                    weakself.imagePicker.dismiss(animated: true, completion: {
                        var uploadURI = ""
                        if weakself.dataSource.isRootFolder() {
                            uploadURI = String(format:"/files/%@/", UserDB.getCurrentUserFromDB().contactID)
                        } else {
                            uploadURI = weakself.parentURI
                        }
                        FileTransferProgressManager.upload(files: weakself.photosToUploadArray, toDriveParentURI: uploadURI)
                        weakself.photosToUploadArray.removeAll()
                        weakself.imagePickeringInProgress = false
                    })
                }
        })
        
        imagePicker.shouldChangeStatusBarStyle = true
        imagePicker.shouldShowSavedPhotosOnTop = false
    }
    
    //MARK: - Menu -
    
    func setupMenu() {
        updateMenuButtonsState()
        selectButton.isEnabled = !dataSource.isRootFolder()
        createFolderButton.isEnabled = canCreateFolders()
        menuView.isUserInteractionEnabled = false
    }
    
    func updateMenuButtonsState() {
        let isTable = DriveModeManager.sharedInstance.mode == DriveMode.TableDriveMode || DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode
        var gridButtonTitle = UIConstants.kListViewButtonTitle
        if isTable {
            gridButtonTitle = UIConstants.kGridViewButtonTitle
        }
        gridButton.setTitle(gridButtonTitle, for: .normal)
        
        let isInSelectMode = DriveModeManager.sharedInstance.mode == DriveMode.GridWithSelectionDriveMode || DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode
        var selectButtonTitle = UIConstants.kSelectButtonTitle
        if isInSelectMode {
            selectButtonTitle = UIConstants.kDeselectButtonTitle
        }
        selectButton.setTitle(selectButtonTitle, for: .normal)
    }
    
    func showMenu() {
        navigationItem.rightBarButtonItem?.isEnabled = false
        UIView.animate(withDuration: 0.5, animations: { 
            self.menuView.alpha = 1.0
            }) { (finished) in
                if finished {
                    self.dismissMenuControl.isHidden = false
                    self.menuView.isUserInteractionEnabled = true
                }
        }
    }
    
    func hideMenu(animated:Bool) {
        if animated {
            UIView.animate(withDuration: 0.5, animations: {
                self.menuView.alpha = 0
            }) { (finished) in
                if finished {
                    self.dismissMenuControl.isHidden = true
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    self.menuView.isUserInteractionEnabled = false
                }
            }
        } else {
            menuView.alpha = 0
            dismissMenuControl.isHidden = true
            navigationItem.rightBarButtonItem?.isEnabled = true
            menuView.isUserInteractionEnabled = false
        }
    }
    
    //MARK: - File selection -
    
    func clearSelection() {
        selectedFiles.removeAll()
        driveCV.reloadData()
        
        DriveBottomMenuManager.disableShareButton()
        DriveBottomMenuManager.disableDeleteButton()
    }
    
    func deselect(items:[Drive]) {
        for item in items {
            if let index = selectedFiles.index(of: item) {
                selectedFiles.remove(at:index)
            }
        }
        driveCV.reloadData()
    }
    
    //MARK: - Pull to refresh -
    
    func setupRefreshControl() {
        tableRefreshControl = UIRefreshControl()
        driveTV.addSubview(tableRefreshControl)
        tableRefreshControl.addTarget(self, action: #selector(DriveVC.refreshData), for: .valueChanged)
    }
    
    func refreshData() {
        tableRefreshControl.endRefreshing()
        isRefreshing = true
        showActivityIndicator()
        dataSource = DriveDataSource(parentURI: parentURI)
        
        dataSource.getDriveDataFromServerWith(success: { [weak self] in
            if let weakself = self {
                if weakself.dataSource.filesCount() > 0 {
                    weakself.hideEmptyDriveView()
                    weakself.reloadUI()
                } else {
                    weakself.setupEmptyDriveMessage()
                    weakself.showEmptyDriveView()
                }
            }
            }) { [weak self] in
                if let weakself = self {
                    if weakself.dataSource.filesCount() > 0 {
                        weakself.hideEmptyDriveView()
                    } else {
                        weakself.setupErrorDriveMessage()
                        weakself.showEmptyDriveView()
                    }
                    weakself.hideActivityIndicator()
                }
        }
    }
    
    func reloadUI() {
        DispatchQueue.main.async {
            self.driveTV.reloadData()
            self.driveCV.reloadData()
        }
    }
    
    //MARK: - Activity Indicator -
    
    func showActivityIndicator() {
        activityIndicator.startAnimating()
        
        driveCV.isUserInteractionEnabled = false
        driveTV.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        
        driveCV.isUserInteractionEnabled = true
        driveTV.isUserInteractionEnabled = true
    }
    
    //MARK: - Bottom menu -
    
    func updateBottomMenuButtonsState () {
        let hasSelectedFiles = selectedFiles.count > 0
        var isDeletable = hasSelectedFiles
        var isSharable = hasSelectedFiles
        var isDownloadable = hasSelectedFiles
        
        for file in selectedFiles {
            if !file.allowedToDelete {
                isDeletable = false
            }
            if !file.allowedToShare {
                isSharable = false
            }
            if !DriveManager.canDriveBeDownloaded(drive: file) {
                isDownloadable = false
            }
        }
        
        if isDeletable {
            DriveBottomMenuManager.enableDeleteButton()
        } else {
            DriveBottomMenuManager.disableDeleteButton()
        }
        
        if isSharable {
            DriveBottomMenuManager.enableShareButton()
        } else {
            DriveBottomMenuManager.disableShareButton()
        }
        
        if isDownloadable {
            DriveBottomMenuManager.enableDownloadButton()
        } else {
            DriveBottomMenuManager.disableDownloadButton()
        }
    }
    
    func disableBottomMenu() {
        DriveBottomMenuManager.disableDeleteButton()
        DriveBottomMenuManager.disableShareButton()
        DriveBottomMenuManager.disableDownloadButton()
    }
    
    func showShareDialogWith(files:[Drive]) {
        shareDialog.filesToShare = files
        shareDialog.updateContactList()
        showShareDialogContainer()
    }
    
    func shareSelectedFiles() {
        disableBottomMenu()
        showShareDialogWith(files: selectedFiles)
    }
    
    func checkIfFileShouldBeDeleted() {
        var shouldShowConfirmation = false
        
        for file in selectedFiles {
            if file.isConversationFilesFolder() || file.isInsideConversationFilesFolder() {
                shouldShowConfirmation = true
            }
        }
        
        if shouldShowConfirmation {
            showDeleteConfirmation()
        } else {
            deleteSelectedFiles()
        }
    }
    
    func deleteSelectedFiles() {
        if selectedFiles.count == 0 {
            return
        }
        
        disableBottomMenu()
        showActivityIndicator()
        for (idx, obj) in selectedFiles.enumerated() {
            DriveManager.delete(drive: obj, success: {[weak self] in
                if let weakself = self {
                    if idx == weakself.selectedFiles.count-1{
                        weakself.updateBottomMenuButtonsState()
                        weakself.refreshData()
                        weakself.cancelSelection()
                    }
                }
                }, failure: {[weak self] in
                    if let weakself = self {
                        if idx == weakself.selectedFiles.count-1{
                            weakself.updateBottomMenuButtonsState()
                            weakself.refreshData()
                            weakself.cancelSelection()
                        }
                    }
            })
        }
    }
    
    func downloadSelectedFiles() {
        disableBottomMenu()
        FileTransferProgressManager.download(files: selectedFiles)
    }
    
    //MARK: - Containers animation -
    
    func showCreateFolderContainer() {
        UIHelper .show(view: createFolderContainer, withCenterYConstraint: folderContainerCenterConstraint, darkTransparentView: shadowView)
    }
    
    func hideCreateFolderContainer(animated:Bool) {
        UIHelper.hide(view: createFolderContainer, withCenterYConstraint: folderContainerCenterConstraint, darkTransparentView: shadowView, animated: animated)
    }
    
    func showShareDialogContainer() {
        UIHelper.show(view: shareDialogContainer, withCenterYConstraint: shareDialogContainerCenterConstraint, darkTransparentView: shadowView)
    }
    
    func hideShareDialogContainer(animated:Bool) {
        let isSelected = DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode || DriveModeManager.sharedInstance.mode == DriveMode.GridWithSelectionDriveMode
        if isSelected {
            cancelSelection()
        }
        
        UIHelper.hide(view: shareDialogContainer, withCenterYConstraint: shareDialogContainerCenterConstraint, darkTransparentView: shadowView, animated: animated)
    }
    
    func showDeleteConfirmation() {
        UIHelper .show(view: deleteConfirmationView, withCenterYConstraint: deleteConfirmationCenterConstraint, darkTransparentView: shadowView)
    }
    
    func hideDeleteConfirmation(animated:Bool) {
        UIHelper.hide(view: deleteConfirmationView, withCenterYConstraint: deleteConfirmationCenterConstraint, darkTransparentView: shadowView, animated: animated)
    }
    
    //MARK: - Drive View switching -
    
    func setupDriveMode() {
        let isTable = DriveModeManager.sharedInstance.mode == DriveMode.TableDriveMode || DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode
        if isTable {
            switchToTableView()
        } else {
            switchToCollectionView()
        }
    }
    
    func switchToCollectionView() {
        driveCV.isHidden = false
        driveTV.isHidden = true
        DriveModeManager.sharedInstance.previousMode = DriveModeManager.sharedInstance.mode
        DriveModeManager.sharedInstance.mode = DriveMode.GridDriveMode
        clearSelection()
        updateUIForSelectedStates(selected: false)
        driveCV.reloadData()
    }
    
    func switchToTableView() {
        driveCV.isHidden = true
        driveTV.isHidden = false
        DriveModeManager.sharedInstance.previousMode = DriveModeManager.sharedInstance.mode
        DriveModeManager.sharedInstance.mode = DriveMode.TableDriveMode
        updateUIForSelectedStates(selected: false)
        driveTV.reloadData()
    }
    
    func switchToGridSelectionMode() {
        if dataSource.isRootFolder() {
            return
        }
        
        driveCV.isHidden = false
        driveTV.isHidden = true
        DriveModeManager.sharedInstance.previousMode = DriveModeManager.sharedInstance.mode
        DriveModeManager.sharedInstance.mode = DriveMode.GridWithSelectionDriveMode
        updateUIForSelectedStates(selected: true)
        driveCV.reloadData()
    }
    
    func switchToTableSelectionMode() {
        if dataSource.isRootFolder() {
            return
        }
        
        driveCV.isHidden = true
        driveTV.isHidden = false
        DriveModeManager.sharedInstance.previousMode = DriveModeManager.sharedInstance.mode
        DriveModeManager.sharedInstance.mode = DriveMode.TableWithSelectionDriveMode
        updateUIForSelectedStates(selected: true)
        driveTV.reloadData()
    }
    
    func updateUIForSelectedStates(selected:Bool) {
        if selected {
            DriveBottomMenuManager.showBottomMenu()
        } else {
            DriveBottomMenuManager.hideBottomMenu()
        }
        updateMenuButtonsState()
        setupNavBarItems()
    }
    
    func cancelSelection() {
        clearSelection()
        if DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode {
            switchToTableView()
        } else if DriveModeManager.sharedInstance.mode == DriveMode.GridWithSelectionDriveMode {
            switchToCollectionView()
        }
    }
    
    //MARK: - EmptyDataSet methods -
    
    func showEmptyDriveView() {
        DispatchQueue.main.async {
            emptyDriveView.isHidden = false
            driveCV.backgroundColor = .clear
            driveTV.backgroundColor = .clear
        }
    }
    
    func hideEmptyDriveView() {
        DispatchQueue.main.async {
            emptyDriveView.isHidden = true
            driveCV.backgroundColor = .white
            driveTV.backgroundColor = .white
        }
    }
    
    func setupLoadingDriveMessage() {
        DispatchQueue.main.async {
            emptyDriveLabel.text = UIConstants.kLoadingFilesMessage
        }
    }
    
    func setupEmptyDriveMessage() {
        DispatchQueue.main.async {
            emptyDriveLabel.text = UIConstants.kNoFilesMessage
        }
    }
    
    func setupErrorDriveMessage() {
        DispatchQueue.main.async {
            emptyDriveLabel.text = UIConstants.kFilesUnavailableMessage
        }
    }
    
    //MARK: - IBActions -
    
    @IBAction func selectButtonPressed(_ sender: AnyObject) {
        hideMenu(animated: false)
        switch DriveModeManager.sharedInstance.mode {
        case .TableDriveMode:
            switchToTableSelectionMode()
        case .GridDriveMode:
            switchToGridSelectionMode()
        case .GridWithSelectionDriveMode:
            switchToCollectionView()
        default:
            switchToTableView()
        }
    }
    
    @IBAction func modeSwitchButtonPressed(_ sender: AnyObject) {
        hideMenu(animated: false)
        switch DriveModeManager.sharedInstance.mode {
        case .TableDriveMode:
            switchToCollectionView()
        case .GridDriveMode:
            switchToTableView()
        case .GridWithSelectionDriveMode:
            switchToTableSelectionMode()
        default:
            switchToGridSelectionMode()
        }
        updateMenuButtonsState()
    }
    
    @IBAction func createFolderButtonPressed(_ sender: AnyObject) {
        hideMenu(animated: false)
        showCreateFolderContainer()
    }
    
    @IBAction func dismissMenuControlTapped(_ sender: AnyObject) {
        hideMenu(animated: true)
    }
    
    @IBAction func shadowViewTapped(_ sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func cancelDeletionButtonPressed(_ sender: AnyObject) {
        hideActivityIndicator()
        hideDeleteConfirmation(animated: true)
    }
    
    @IBAction func confirmDeletionButtonPressed(_ sender: AnyObject) {
        hideDeleteConfirmation(animated: true)
        deleteSelectedFiles()
    }
    
    //MARK: - Navigation -
    
    func navigateDownTheTreeIfPossible(selectedDrive:Drive) {
        if canNavigateToOtherScreen() {
            disableControlsWithLeaveAbility()
            if selectedDrive.isDirectory() {
                if let childrenDriveVC = .storyboard?.instantiateViewController(withIdentifier: "DriveVCIdentifier") as? DriveVC, let driveUri = selectedDrive.uri {
                    childrenDriveVC.parentURI = driveUri
                    navigationController?.pushViewController(childrenDriveVC, animated: true)
                }
            }
        }
    }
    
    func navigateUpTheTree() {
        if canNavigateToOtherScreen() {
            disableControlsWithLeaveAbility()
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func showDriveInfo() {
        if canNavigateToOtherScreen() {
            disableControlsWithLeaveAbility()
            performSegue(withIdentifier: "showDriveInfo", sender: self)
        }
    }
    
    func showFilesListFromDeviceToUpload() {
        if canNavigateToOtherScreen() {
            imagePickeringInProgress = true
            disableControlsWithLeaveAbility()
            imagePicker.selection = photosToUploadArray
            present(imagePicker, animated: true, completion: nil)
        }
    }
}

//MARK: - TableView methods -

extension DriveVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.filesCount()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var driveCell = tableView.dequeueReusableCell(withIdentifier: "DriveTVCellIdentifier", for: indexPath) as? DriveTVCell
        if driveCell == nil{
            driveCell = DriveTVCell()
        }
        driveCell?.delegate = self
        driveCell?.dataSource = self
        driveCell?.cellRevealMode = .normal
        
        if let curDrive = dataSource.driveAt(index: indexPath.row) {
            driveCell?.setupCellWith(drive: curDrive, isRoot: dataSource.isRootFolder())
            if DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode {
                driveCell?.enterSelectionMode(isSelected: selectedFiles.contains(curDrive))
            } else {
                driveCell?.exitSelectionMode()
            }
        }
        
        if !tableView.isHidden && indexPath.item == dataSource.filesCount()-3 {
            downloadNextPageOfFiles()
        }
        
        return driveCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let curDrive = dataSource.driveAt(index: indexPath.row) {
            let isInSelectionMode = DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode
            if isInSelectionMode {
                if let curDriveIndex = selectedFiles.index(of: curDrive) {
                    selectedFiles.remove(at: curDriveIndex)
                } else {
                    selectedFiles.append(curDrive)
                }
                updateBottomMenuButtonsState()
                tableView.reloadData()
            } else {
                if curDrive.isDirectory() {
                    navigateDownTheTreeIfPossible(selectedDrive: curDrive)
                } else {
                    UIHelper.openFile(selectedDrive: curDrive)
                }
            }
        }
    }
}

//MARK: - CollectionView methods -

extension DriveVC: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.filesCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var driveCell = collectionView.dequeueReusableCell(withReuseIdentifier: "DriveCVCellIdentifier", for: indexPath) as? DriveCVCell
        if driveCell == nil{
            driveCell = DriveCVCell()
        }
        if let curDrive = dataSource.driveAt(index: indexPath.row) {
            driveCell?.setupCellWith(drive: curDrive, isRoot: dataSource.isRootFolder())
            if DriveModeManager.sharedInstance.mode == DriveMode.TableWithSelectionDriveMode {
                driveCell?.enterSelectionMode(isSelected: selectedFiles.contains(curDrive))
            } else {
                driveCell?.exitSelectionMode()
            }
        }
        
        if !collectionView.isHidden && indexPath.item == dataSource.filesCount()-3 {
            downloadNextPageOfFiles()
        }
        
        return driveCell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let curDrive = dataSource.driveAt(index: indexPath.row) {
            let isInSelectionMode = DriveModeManager.sharedInstance.mode == DriveMode.GridWithSelectionDriveMode
            if isInSelectionMode {
                if let curDriveIndex = selectedFiles.index(of: curDrive) {
                    selectedFiles.remove(at: curDriveIndex)
                } else {
                    selectedFiles.append(curDrive)
                }
                updateBottomMenuButtonsState()
                collectionView.reloadData()
            } else {
                if curDrive.isDirectory() {
                    navigateDownTheTreeIfPossible(selectedDrive: curDrive)
                } else {
                    UIHelper.openFile(selectedDrive: curDrive)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flow = collectionViewLayout as! UICollectionViewFlowLayout
        let cellsWidth = (UIScreen.main.bounds.size.width - 2*flow.minimumInteritemSpacing - 2*flow.sectionInset.left - 2*collectionView.frame.origin.x)
        let itemWidth = cellsWidth / 3
        return CGSize(width:itemWidth, height:itemWidth)
    }
}

//MARK: - SWRevealTableViewCell methods -

extension DriveVC: SWRevealTableViewCellDelegate, SWRevealTableViewCellDataSource {
    
    func revealTableViewCell(_ revealTableViewCell: SWRevealTableViewCell!, willMoveTo position: SWCellRevealPosition) {
        if position == .center {
            return
        }
        
        for cell in driveTV.visibleCells {
            if cell == revealTableViewCell {
                continue
            }
            
            (cell as! SWRevealTableViewCell).setRevealPosition(.center, animated: true)
        }
    }
    
    func rightButtonItems(in revealTableViewCell: SWRevealTableViewCell!) -> [Any]! {
        var itemsArray = [SWCellButtonItem]()
        
        if !dataSource.isRootFolder() {
            if let indexPath = driveTV.indexPath(for: revealTableViewCell) {
                if let curDrive = dataSource.driveAt(index: indexPath.row) {
                    
                    if !curDrive.isDirectory() {
                        if let infoItem = infoItem() {
                            itemsArray.append(infoItem)
                        }
                    }
                    
                    if curDrive.allowedToShare {
                        if let shareItem = shareItem() {
                            itemsArray.append(shareItem)
                        }
                    }
                    
                    if DriveManager.canDriveBeDownloaded(drive: curDrive) {
                        if let downloadItem = downloadItem() {
                            itemsArray.append(downloadItem)
                        }
                    }
                    
                    if curDrive.allowedToDelete {
                        if let deleteItem = downloadItem() {
                            itemsArray.append(deleteItem)
                        }
                    }
                }
            }
        }
        return itemsArray
    }
    
    func infoItem() -> SWCellButtonItem? {
        let infoItem = SWCellButtonItem(title: UIConstants.kInfoButtonTitle, handler: {[weak self] (item, cell) -> Bool in
            if let weakself = self {
                weakself.selectedChildDrive = curDrive
                weakself.showDriveInfo()
            }
            return true
        })
        
        infoItem?.backgroundColor = UIColor.blue
        infoItem?.image = UIImage(named: UIConstants.kInfoIconImageName)
        infoItem?.tintColor = UIColor.white
        infoItem?.width = CGFloat(UIConstants.kDriveRevealButtonDefaultWidth)
        
        return infoItem
    }
    
    func shareItem() -> SWCellButtonItem? {
        let shareItem = SWCellButtonItem(title: UIConstants.kShareButtonTitle, handler: {[weak self] (item, cell) -> Bool in
            if let weakself = self {
                weakself.showShareDialogWith(files:[curDrive])
            }
            return true
        })
        shareItem?.backgroundColor = UIColor.green
        shareItem?.image = UIImage(named: UIConstants.kShareIconImageName)
        shareItem?.tintColor = UIColor.white
        shareItem?.width = CGFloat(UIConstants.kDriveRevealButtonDefaultWidth)
        
        return shareItem
    }
    
    func downloadItem() -> SWCellButtonItem? {
        let downloadItem = SWCellButtonItem(title: UIConstants.kDownloadButtonTitle, handler: {(item, cell) -> Bool in
            FileTransferProgressManager.download(files: [curDrive])
            return true
        })
        downloadItem?.backgroundColor = UIColor.orange
        downloadItem?.image = UIImage(named: UIConstants.kDownloadIconImageName)
        downloadItem?.tintColor = UIColor.white
        downloadItem?.width = CGFloat(UIConstants.kDriveRevealButtonDefaultWidth)
        
        return downloadItem
    }
    
    func deleteItem() -> SWCellButtonItem? {
        let deleteItem = SWCellButtonItem(title: UIConstants.kDeleteButtonTitle, handler: {[weak self] (item, cell) -> Bool in
            if let weakself = self {
                weakself.deleteDrive()
            }
            return true
        })
        deleteItem?.backgroundColor = UIColor.red
        deleteItem?.image = UIImage(named: UIConstants.kDeleteButtonIconName)
        deleteItem?.tintColor = UIColor.white
        deleteItem?.width = CGFloat(UIConstants.kDriveRevealButtonDefaultWidth)
        
        return deleteItem
    }
    
    func deleteDrive() {
        showActivityIndicator()
        if curDrive.isConversationFilesFolder() || curDrive.isInsideConversationFilesFolder() {
            selectedFiles.append(curDrive)
            showDeleteConfirmation()
        } else {
            DriveManager.delete(drive: curDrive, success: { [weak self] in
                if let weakweak = weakself {
                    weakweak.refreshData()
                }
                }, failure: nil)
        }
    }
}
