//
//  PhotoLibrary.swift
//  PhotoSort (iOS)
//
//  Created by Dustin Stabinski on 2/20/22.
//

import Foundation
import Photos

class PhotoLibrary {
    func photoAuthorization() -> String {
        // 1
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            return "Authorized"
            // 2
        case .restricted, .denied:
            return "Unauthorized"
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                print(status)
            }
        default:
            return "nothing"
        }
        return "nothing"
    }
}
