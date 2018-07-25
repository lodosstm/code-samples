//
//  DriveNetworkManager.swift
//
//  Created by dev on 12/14/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import AFNetworking
import UIKit

class DriveNetworkManager: NSObject {
    
    class func setupHTTPSessionManager() -> AFHTTPSessionManager {
        let cookieDict = UserDefaults.standard.object(forKey: UserDefaultsKey.kUserDefaultsCookieKey) as? [String:Any]
        let manager = AFHTTPSessionManager(baseURL: URL(string: RestData.kBaseDriveURL))
        manager.requestSerializer = AFJSONRequestSerializer()
        if let cookie = cookieDict {
            manager.requestSerializer.setValue(String(format: "%@=%@; Domain=https://example.com", DictionaryKey.kSessionIDParameter,  cookie[DictionaryKey.kSessionIDParameter] as! String), forHTTPHeaderField: DictionaryKey.kSetCookieHeader)
        }
        manager.requestSerializer.setValue(DictionaryKey.kTrueValue, forHTTPHeaderField: DictionaryKey.kAccessControlHeader)
        manager.requestSerializer.setValue(DictionaryKey.kApplicationJSONValue, forHTTPHeaderField: DictionaryKey.kAcceptHeader)
        
        return manager
    }
    
    class func getFilesWith(parentURI:String?, offset:Int, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if let parent = parentURI {
            var finalURI = parent
            if (finalURI.range(of: "command=") == nil) {
                finalURI = finalURI.appending("?command=getchildren&format=json")
            }
            if (offset != 0) {
                finalURI = finalURI.appending(String(format:"&offset=%d", offset))
            }
            
            finalURI = finalURI.appending(String(format:"&count=%d", 20))
            
            let manager = DriveNetworkManager.setupHTTPSessionManager()
            manager.get(parent, parameters: nil, progress: nil, success: {
                requestOperation, response in
                if let successHandler = success {
                    successHandler(response)
                }
                }, failure: {
                    requestOperation, error in
                    if let failureHandler = failure {
                        failureHandler(error.localizedDescription)
                    }
            })
        }
    }
    
    class func downloadFileWith(fileURI:String?, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if let uri = fileURI {
            let manager = DriveNetworkManager.setupHTTPSessionManager()
            let requestPath = String(format:"%@?command=download", uri)
            manager.get(requestPath, parameters: nil, progress: {
                progress in
                NotificationCenter.default.post(name: NSNotification.Name(LocalNotificationKey.kFileDownloadProgress), object: nil, userInfo: [LocalNotificationKey.kFileDownloadProgressKey:progress])
                }, success: {
                requestOperation, response in
                if let successHandler = success {
                    successHandler(response)
                }
                }, failure: {
                    requestOperation, error in
                    if let failureHandler = failure {
                        failureHandler(error.localizedDescription)
                    }
            })
        }
    }
    
    class func deleteFileWith(fileURI:String?, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if let uri = fileURI {
            let manager = DriveNetworkManager.setupHTTPSessionManager()
            let requestPath = String(format:"%@?command=delete", uri)
            manager.get(requestPath, parameters: nil, progress: nil, success: {
                    requestOperation, response in
                    if let successHandler = success {
                        successHandler(response)
                    }
                }, failure: {
                    requestOperation, error in
                    if let failureHandler = failure {
                        failureHandler(error.localizedDescription)
                    }
            })
        }
    }
    
    class func upload(image:UIImage?, parentURI:String?, fileName:String?, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if let imageToUpload = image, let uri = parentURI, let file = fileName {
            let imageData = UIImageJPEGRepresentation(imageToUpload, 0.8)
            if let data = imageData {
                DriveNetworkManager.upload(data: data, parentURI: uri, fileName: file, success: success, failure: failure)
            }
        }
    }
    
    class func upload(data:Data?, parentURI:String?, fileName:String?, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if let imageData = data, var uri = parentURI, let file = fileName {
            if (!uri.hasSuffix("/")) {
                uri = uri.appending("/")
            }
            var path = uri.appending(file)
            path = path.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            if (path.hasPrefix("/") && path.characters.count > 1) {
                path = path.substring(from: path.index(path.startIndex, offsetBy:1))
            }
            
            let manager = DriveNetworkManager.setupHTTPSessionManager()
            manager.requestSerializer.setValue(DictionaryKey.kFormDataValue, forHTTPHeaderField: DictionaryKey.kContentTypeHeader)
            
            let request = AFHTTPRequestSerializer().multipartFormRequest(withMethod: RestData.kPUTMethod, urlString: path, parameters: nil, constructingBodyWith: { (formData) in
                formData.appendPart(withForm: imageData, name: "")
                }, error: nil)
            let uploadTask = manager.uploadTask(with: request as URLRequest, from: nil, progress: { (progress) in
                    NotificationCenter.default.post(name: NSNotification.Name(LocalNotificationKey.kFileUploadProgress), object: nil, userInfo: [LocalNotificationKey.kFileUploadProgressKey:progress])
                }, completionHandler: { (response, responseObject, error) in
                    if let uploadError = error {
                        if let failureHandler = failure {
                            failureHandler(uploadError.localizedDescription)
                        }
                    } else {
                        if let successHandler = success {
                            successHandler(responseObject)
                        }
                    }
            })
            uploadTask.resume()
        }
    }
    
    class func searchFilesWith(text:String?, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if let searchText = text  {
            let path = String(format:"search?q=%@", searchText)
            let manager = DriveNetworkManager.setupHTTPSessionManager()
            manager.post(path, parameters: nil, progress: nil, success: {
                requestOperation, response in
                if let successHandler = success {
                    successHandler(response)
                }
                }, failure: {
                    requestOperation, error in
                    if let failureHandler = failure {
                        failureHandler(error.localizedDescription)
                    }
            })
        }
    }
    
    class func renameFileWith(uri:String?, newName:String?, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if var name = newName, let fileURI = uri {
            if (name.range(of: " ") != nil) {
                name = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            
            let path = String(format:"%@?command=rename&newname=%@", fileURI, name)
            let manager = DriveNetworkManager.setupHTTPSessionManager()
            manager.get(path, parameters: nil, progress: nil, success: {
                requestOperation, response in
                if let successHandler = success {
                    successHandler(response)
                }
                }, failure: {
                    requestOperation, error in
                    if let failureHandler = failure {
                        failureHandler(error.localizedDescription)
                    }
            })
        }
    }
    
    class func getMetadataForFileWith(idString:String?, success:((_ responseObject:Any)->Void)?, failure:((_ errorMessage:String)->Void)?) {
        if let fileID = idString {
            let path = String(format:"files/%@/%@/%@?command=getmetadata", UserDB.getCurrentUserFromDB().contactID, DictionaryKey.kDefaultConversationFilesFolderName, fileID)
            let manager = DriveNetworkManager.setupHTTPSessionManager()
            manager.get(path, parameters: nil, progress: nil, success: {
                requestOperation, response in
                if let successHandler = success {
                    successHandler(response)
                }
                }, failure: {
                    requestOperation, error in
                    if let failureHandler = failure {
                        failureHandler(error.localizedDescription)
                    }
            })
        }
    }
    
    class func stringFrom(contactsArray:[Contact]?) -> String {
        var finalString = ""
        
        if let arrayOfElements = contactsArray {
            for (_, obj) in arrayOfElements.enumerated() {
                finalString = finalString.appending(String(format:"%@;", obj.contactID))
            }
        }
        if (finalString.hasSuffix(";")) {
            finalString = finalString.substring(to: finalString.index(before: finalString.endIndex))
        }
        
        return finalString
    }
}
