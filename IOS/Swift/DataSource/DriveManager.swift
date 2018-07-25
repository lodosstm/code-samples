//
//  DriveManager.swift
//
//  Created by dev on 12/21/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import AssetsLibrary

class DriveManager: NSObject {
    var unseenSharedFilesDict: [String: [String]] = [:]
    static let sharedInstance = DriveManager()
    
    //MARK: - Download -
    
    class func download(file:Drive?, success:(()->Void)?, failure:(()->Void)?) {
        if let drive = file {
            if let uri = drive.uri {
                DriveNetworkManager.downloadFileWith(fileURI: uri, success: { (response) in
                    if let successBlock = success {
                        successBlock()
                    }
                }, failure: { (errorMessage) in
                    print("ERROR : \(errorMessage)")
                    if let failuerBlock = failure {
                        failuerBlock()
                    }
                })
            }
        }
    }
    
    class func downloadFileAndSaveItToTempDir(fileURL:String?, success:((_ filePath:String)->Void)?, failure:(()->Void)?) {
        if let urlString = fileURL {
            let lastPathComponent = urlString.lastPathComponent
            DriveNetworkManager.downloadFileWith(fileURI: urlString, success: { (response) in
                print("Download request was successful!")
                saveToFileWith(response: response)
            }, failure: { (errorMessage) in
                print("ERROR : \(errorMessage)")
                if let failuerBlock = failure {
                    failuerBlock()
                }
            })
        }
    }
    
    func saveToFileWith(response: Data) {
        let filePath = getFilePath()
        do {
            try response.write(to: filePath, options: .atomic)
            if let successBlock = success {
                successBlock(filePath.absoluteString)
            }
        } catch {
            print("ERROR : \(error.localizedDescription)")
            if let failuerBlock = failure {
                failuerBlock()
            }
        }
    }
    
    func getFilePath() -> String {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsUrl.appendingPathComponent(lastPathComponent)
        print("fileURL: \(filePath.absoluteString)")
        return filePath
    }
    
    class func removeTempFile(fileURL:String?) {
        if let urlString = fileURL {
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: urlString))
                print("File removed successfully")
            } catch {
                print("ERROR : \(error.localizedDescription)")
            }
        }
    }
    
    class func delete(drive:Drive?, success:(()->Void)?, failure:(()->Void)?) {
        if let driveToDelete = drive, let uriString = driveToDelete.uri {
            DriveNetworkManager.deleteFileWith(fileURI: uriString, success: { (response) in
                print("Drive was deleted successfully!")
                DriveDB.delete(drive: driveToDelete)
                if let successBlock = success {
                    successBlock()
                }
            }, failure: { (errorMessage) in
                print("ERROR : \(errorMessage)")
                if let failuerBlock = failure {
                    failuerBlock()
                }
            })
        }
    }
    
    class func canDriveBeDownloaded(drive:Drive?) -> Bool {
        if let driveToCheck = drive {
            if driveToCheck.isDirectory() || driveToCheck.thumbnail == nil {
                return false
            }
            return true
        }
        return false
    }
    
    //MARK: - Save to Library -
    
    class func save(image:UIImage?, toAlbum:String?) {
        DriveManager.save(image: image, toAlbum: toAlbum, success:nil)
    }
    
    class func saveImageFrom(data:Data?, toAlbum:String?) {
        if let imageData = data, let albumName = toAlbum {
            let image = UIImage(data: imageData)
            if let downloadedImage = image {
                DriveManager.save(image: downloadedImage, toAlbum: albumName)
            }
        }
    }
    
    class func save(image:UIImage?, toAlbum:String?, success:(()->Void)?) {
        if let downloadedImage = image, let albumName = toAlbum {
            let library = ALAssetsLibrary()
            library.save(downloadedImage, toAlbum: albumName, completion: { (assetURL, error) in
                print("Image successfully saved to album")
                if let successBlock = success {
                    successBlock()
                }
            }, failure: { (error) in
                if let saveError = error {
                    print("Image saving error: \(saveError.localizedDescription)")
                }
            })
        }
    }
    
    class func save(video:Data?, toAlbum:String?) {
        if let videoData = video, let albumName = toAlbum {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let filePath = documentsUrl.appendingPathComponent(Constants.kVideoName)
            print("fileURL: \(filePath.absoluteString)")
            
            do {
                try videoData.write(to: filePath, options: .atomic)
                DriveManager.saveVideoWith(fileURL: filePath, toAlbum: albumName, shouldDeleteFileOnCompletion: true)
            } catch {
                print("ERROR : \(error.localizedDescription)")
            }
        }
    }
    
    class func saveVideoWith(fileURL:URL?, toAlbum:String?, shouldDeleteFileOnCompletion:Bool) {
        if let videoURL = fileURL, let albumName = toAlbum {
            let library = ALAssetsLibrary()
            library.saveVideo(videoURL, toAlbum: albumName, completion: { (assetURL, error) in
                print("Video successfully saved to album")
                if shouldDeleteFileOnCompletion {
                    DriveManager.removeTempFile(fileURL: videoURL.absoluteString)
                }
            }, failure: { (error) in
                if let saveError = error {
                    print("Image saving error: \(saveError.localizedDescription)")
                }
                if shouldDeleteFileOnCompletion {
                    DriveManager.removeTempFile(fileURL: videoURL.absoluteString)
                }
            })
        }
    }
    
    //MARK: - Share notifications -
    
    func saveSharedFile(uri:String?, fromContactID:String?) {
        if let fileURI = uri, let contactID = fromContactID {
            if var sharedFiles = unseenSharedFilesDict[contactID] {
                if !sharedFiles.contains(fileURI) {
                    sharedFiles.append(fileURI)
                    NotificationCenter.default.post(name: NSNotification.Name("FileShared"), object: self, userInfo: ["FileSharedUserInfoKey":fileURI])
                    unseenSharedFilesDict[contactID] = sharedFiles
                }
            }
        }
    }
    
    func numberOfUnseenFilesFromUser(userID:String?) -> Int {
        if let idString = userID {
            if let sharedFiles = unseenSharedFilesDict[idString] {
                return sharedFiles.count
            }
        }
        return 0
    }
    
    func numberOfAllUnseenFiles() -> Int {
        var numberOfFiles = 0
        
        let sharedFiles = unseenSharedFilesDict.values
        for array in sharedFiles {
            numberOfFiles += array.count
        }
        
        return numberOfFiles
    }
    
    func clearUnseenFilesFromUser(userID:String?) {
        if let idString = userID {
            unseenSharedFilesDict[idString] = [String]()
        }
    }
    
    func clearAllUnseenFiles() {
        unseenSharedFilesDict = [String:[String]]()
    }
}
