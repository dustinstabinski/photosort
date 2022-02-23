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
    var _access = Access.denied
    
    init() {
        _access = photoAuthorization()
        if (_access == Access.granted) {
            fillAlbums()
        }
    }
    
    
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
    
    func fillAlbums() -> Void {
        _albums.removeAll()
        let options = PHFetchOptions()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: options)
        
        buildAlbumDict(assetCollection: userAlbums);
        buildAlbumDict(assetCollection: smartAlbums);
    }
    
    func buildAlbumDict(assetCollection: PHFetchResult<PHAssetCollection>) -> Void {
        assetCollection.enumerateObjects({(asset, index, stop) in
            let title = asset.localizedTitle;
            if (title != nil) {
                if (self._albums[title!] == nil) {
                    self._albums[title!] = asset;
                } else {
                    // If there is a duplicate album name
                    var dupCount = 1
                    var dupTitle = title! + " " + String(dupCount)
                    while (self._albums[dupTitle] != nil) {
                        dupCount += 1
                        dupTitle = title! + " " + String(dupCount)
                    }
                    self._albums[dupTitle] = asset
                }
            }
        })
    }
    
    func createNewAlbum(title: String) async -> Void {
        do {
            try await PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            })
        }
        catch {
            print("Error creating album: \(String(describing: error)).")
        }
    }
    
    func deleteAlbum(assetCollection: PHAssetCollection) async -> Void {
        do {
        try await PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.deleteAssetCollections([assetCollection as Any] as NSArray)
        })
        } catch {
            print("Error deleting album: \(String(describing: error)).")
        }
    }
    
    func addToAlbum(asset: PHAsset, album: PHAssetCollection) async -> Void {
        do {
        try await PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest(for: album)!
            request.addAssets([asset as Any] as NSArray)
            })
        } catch {
            print("Error adding to album: \(String(describing: error)).")
        }
    }
    
    func removeFromAlbum(asset: PHAsset, album: PHAssetCollection) async -> Void {
        do {
        try await PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCollectionChangeRequest(for: album)!
                request.removeAssets([asset as Any] as NSArray)
            })
        } catch {
            print("Error remove from album: \(String(describing: error)).")
        }
    }
    
    func removeFromLibrary(asset: PHAsset) async -> Void {
        do {
        try await PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset as Any] as NSArray)
        })
        }
        catch {
            print("Error remove from library: \(String(describing: error)).")
        }
    }
    
   
}
