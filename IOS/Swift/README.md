# Swift Samples

# Samples of Data Sources

## ContactsDataSource

This component is used to fetch contacts information from local data base or server.  It also provides methods to manage user contacts (filter, search, delete etc.)

### Files

* [ContactsDataSource.swift](DataSource/ContactsDataSource.swift)

## ContactsPresenceDataSource

This component is used to retreive, change and save presence status of user's contact.  

### Files

* [ContactsPresenceDataSource.swift](DataSource/ContactsPresenceDataSource.swift)

## DriveManager

This component is used to download, save and remove files from device's file system. It also provides functionality to manage badges for file-related user notifications.  

### Files

* [DriveManager.swift](DataSource/DriveManager.swift)

## PhotoLibraryDataSource

This component is used to create albums in device's Gallery and save photos there.  

### Files

* [PhotoLibraryDataSource.swift](DataSource/PhotoLibraryDataSource.swift)

# Samples of Data Base (DB) Services

## ContactsDB

This component is used to save, select, modify and delete data in Contacts database table.  

### Files

* [ContactsDB.swift](DB/ContactsDB.swift)

## ContactsAndCallsRelationsDB

This component is used to fetch and manage data in ContactsAndCallsRelations database table.  

### Files

* [ContactsAndCallsRelationsDB.swift](DB/ContactsAndCallsRelationsDB.swift)

# Samples of Network Services

## BaseSocketsManager

This component is used to establish and close connection with server using json rpc protocol. It is a wrapper for basic  SocketRocket methods with addition of interruptions handlers.

### Files

* [BaseSocketsManager.swift](Network/BaseSocketsManager.swift)

## DriveNetworkManager

This component is used to establish network connection via TCP/IP and implement files related api including methods to upload, download, search, rename files and folders.  

### Files

* [DriveNetworkManager.swift](Network/DriveNetworkManager.swift)

# Samples of View Controllers (VC)

## SettingsListVC

This component is used for common Settings page in average application. It shows user profile data and logout option.  

### Files

* [SettingsListVC.swift](VC/SettingsListVC.swift)

## ChatListVC

This component is used to display a list of chats in messenger application. Chats with short information (including names and avatars of the people who take part in conversation, the last message, date of the last message etc.) are listed in a table view and sorted by the date of the last message.

Screen has 2 tabs for conversations with your contacts and with ither people.
When no chats are available for user a special message is shown.

In the navigation bar there is a special view for current user's presence status. Users can change their status to "online", "away", "do not disturb" options. Similar presence badges are placed on private chats to show interlocutor's status.

Conponent `ChatListVC` uses component `ChatsContactsTableViewDelegate` as data source and delegate for it's table views.

### Files

* [ChatListVC.swift](VC/ChatListVC.swift)

## ChatsContactsTableViewDelegate

This component is used as data source and delegate for UITableViews. It is created with table view, parent view controller and a pagination delegate object. It fetches data from the local database and provides appropriate methods to show data in the table view.

### Files

* [ChatsContactsTableViewDelegate.swift](VC/ChatsContactsTableViewDelegate.swift)

## DriveVC

This component is used to show list of folders and file in simple Dropbox like application. Files and folders can be viewed in list and grid modes. Editing mode with ability to perform a certain action on group of selected files is available too. View controller provides functionality to create new folders, download and upload files from device's gallery and share files with user's contacts. If folder contains no files a special message is shown to user.

### Files

* [DriveVC.swift](VC/DriveVC.swift)


# Samples of VIPER Modules

## Video List

This module is used to show list of  available YouTube videos to user. 

### Files

* [VideoListAssembly.swift](ViperModuleSamples/VideoList/Assembly/VideoListAssembly.swift)
* [VideoListInteractor.swift](ViperModuleSamples/VideoList/Interactor/VideoListInteractor.swift)
* [VideoListInteractorInput.swift](ViperModuleSamples/VideoList/Interactor/VideoListInteractorInput.swift)
* [VideoListInteractorOutput.swift](ViperModuleSamples/VideoList/Interactor/VideoListInteractorOutput.swift)
* [VideoListPresenter.swift](ViperModuleSamples/VideoList/Presenter/VideoListPresenter.swift)
* [VideoListRouter.swift](ViperModuleSamples/VideoList/Router/VideoListRouter.swift)
* [VideoListViewController.swift](ViperModuleSamples/VideoList/View/VideoListViewController.swift)
* [VideoListViewController.xib](ViperModuleSamples/VideoList/View/VideoListViewController.xib)
* [VideoListViewInput.swift](ViperModuleSamples/VideoList/View/VideoListViewInput.swift)
* [VideoListViewOutput.swift](ViperModuleSamples/VideoList/View/VideoListViewOutput.swift)
* [VideoListItemTableViewCell.swift](ViperModuleSamples/VideoList/View/Cells/VideoListItemTableViewCell.swift)
* [VideoListItemTableViewCell.xib](ViperModuleSamples/VideoList/View/Cells/VideoListItemTableViewCell.xib)