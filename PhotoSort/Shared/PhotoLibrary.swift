//
//  PhotoLibrary.swift
//  PhotoSort (iOS)
//
//  Created by Dustin Stabinski on 2/20/22.
//

import Foundation
import Photos
import UIKit
import SwiftUI

enum Access {
    case granted
    case denied
    
}

class PhotoLibrary {
    
    var _albums: [String: PHAssetCollection] = [:]
    
    func photoAuthorization() -> Access {
        // 1
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    switch status {
                        case .authorized:
                            print("Authorized")
                        default:
                            print("Denied")
                        }
                }
            case .authorized:
                return Access.granted
            default:
                return Access.denied
            }
        
        return Access.denied
    }
    
    func fillAlbums() -> String {
        let options = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: options)
        
        buildAlbumDict(assetCollection: userAlbums);
        buildAlbumDict(assetCollection: smartAlbums);
        return ""
    }
    
    func buildAlbumDict(assetCollection: PHFetchResult<PHAssetCollection>) -> Void {
        assetCollection.enumerateObjects({(asset, index, stop) in
            let title = asset.localizedTitle;
            if (title != nil) {
                if (self._albums[title!] != nil) {
                    self._albums[title!] = asset;
                } else {
                    var dupCount = 1
                    var dupTitle = title! + String(dupCount)
                    while (self._albums[dupTitle] != nil) {
                        dupCount += 1
                        dupTitle = title! + String(dupCount)
                    }
                    self._albums[dupTitle] = asset
                }
            }
        })
    }
}
