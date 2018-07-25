//
//  PhotoLibraryDataSource.swift
//
//  Created by dev on 12/20/16.
//  Copyright © 2016 lodoss. All rights reserved.
//

import Foundation
import UIKit
import AssetsLibrary

class PhotoLibraryDataSource : NSObject {
    var albumsArray: [ALAssetsGroup] = []
    var photosArray: [ALAsset] = []
    var assetsGroup = ALAssetsGroup()
    var assetsLibrary = ALAssetsLibrary()
    var completion : (() -> Void)?
    var currentMode = LibraryDataSourceMode.AlbumDataSourceMode
    
    func setupWith(mode:Int, completion:(()->Void)?, failure:(()->Void)?) {
        currentMode = mode
        if currentMode == LibraryDataSourceMode.AlbumDataSourceMode {
            getAlbumsFromLibraryWith(completion: completion, failure: failure)
        } else {
            getPhotosFromLibraryWith(completion: completion)
        }
    }
    
    func getAlbumsFromLibraryWith(completion:(()->Void)?, failure:(()->Void)?) {
        albumsArray.removeAll()
        
        let groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupSavedPhotos
        assetsLibrary.enumerateGroupsWithTypes(groupTypes, usingBlock: {(group, stop) in
            if let results = group {
                let onlyPhotosFilter = ALAssetsFilter.allPhotos()
                results.setAssetsFilter(onlyPhotosFilter)
                if (results.numberOfAssets()) > 0 {
                    albumsArray.append(results)
                }
                if let completionBlock = completion {
                    DispatchQueue.main.async {
                        completionBlock()
                    }
                }
            }
            }, failureBlock:{ (error) in
                if let fail = failure {
                    DispatchQueue.main.async {
                        fail()
                    }
                }
            })
    }
    
    func getPhotosFromLibraryWith(completion:(()->Void)?) {
        photosArray.removeAll()
        
        let onlyPhotosFilter = ALAssetsFilter.allPhotos()
        assetsGroup.setAssetsFilter(onlyPhotosFilter)
        assetsGroup.enumerateAssets(options: .concurrent) { (result, index, stop) in
            if let asset = result {
                photosArray.append(asset)
            }
            if let completionBlock = completion {
                DispatchQueue.main.async {
                    completionBlock()
                }
            }
        }
    }
    
    func photoAt(indexPath:NSIndexPath?) -> ALAsset? {
        if let path = indexPath {
            if (currentMode == LibraryDataSourceMode.PhotoDataSourceMode && photosArray.count > path.item) {
                return photosArray[path.item]
            }
        }
        return nil
    }
    
    func albumAt(indexPath:NSIndexPath?) -> ALAssetsGroup? {
        if let path = indexPath {
            if (currentMode == LibraryDataSourceMode.AlbumDataSourceMode && albumsArray.count > path.item) {
                return albumsArray[path.item]
            }
        }
        return nil
    }
    
    func numberOfAssets() -> Int {
        if (currentMode == LibraryDataSourceMode.AlbumDataSourceMode) {
            return albumsArray.count
        } else if (currentMode == LibraryDataSourceMode.PhotoDataSourceMode) {
            return photosArray.count
        }
        return 0
    }
}
