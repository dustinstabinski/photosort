//
//  PhotoSortUnitTests.swift
//  PhotoSortUnitTests
//
//  Created by Dustin Stabinski on 2/23/22.
//

import XCTest
@testable import PhotoSort
import Photos

class PhotoSortUnitTests: XCTestCase {
    var lib: PhotoLibrary!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        lib = PhotoLibrary()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() throws {
        XCTAssert(!lib._albums.isEmpty)
        XCTAssert(lib._access == Access.granted)
    }
    
    func testCreateDeleteNewAlbum() async throws {
        await lib.createNewAlbum(title: "UnitTest")
        lib.fillAlbums()
        XCTAssert(lib._albums["UnitTest"] != nil)
        
        await lib.createNewAlbum(title: "UnitTest")
        lib.fillAlbums()
        XCTAssert(lib._albums["UnitTest 1"] != nil)
        
        await lib.deleteAlbum(assetCollection: lib._albums["UnitTest 1"]!)
        lib.fillAlbums()
        XCTAssert(lib._albums["UnitTest 1"] == nil)
        
        await lib.deleteAlbum(assetCollection: lib._albums["UnitTest"]!)
        lib.fillAlbums()
        XCTAssert(lib._albums["UnitTest"] == nil)
        
    }
    
    func testAddToRemoveFromAlbum() async throws {
        let options = PHFetchOptions()
        await lib.createNewAlbum(title: "UnitTest")
        await lib.createNewAlbum(title: "UnitTest2")
        lib.fillAlbums()
        let recents = lib._albums["Recents"]
        let dest = lib._albums["UnitTest"]
        let source = lib._albums["UnitTest2"]
        let assets = PHAsset.fetchAssets(in: recents!, options: options)
        let asset = assets.firstObject
        
        await lib.addToAlbum(asset: asset!, album: source!)
        
        await lib.removeFromAlbum(asset: asset!, album: source!)
        
        await lib.addToAlbum(asset: asset!, album: dest!)
        
        let fetchedAssetResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset!.localIdentifier], options: options)
        
        XCTAssert(fetchedAssetResult.count == 1)
        
        let fetchedAsset = fetchedAssetResult.firstObject
        let collection = PHAssetCollection.fetchAssetCollectionsContaining(fetchedAsset!, with: .album, options: options)
        
        XCTAssert(collection.count == 1)
        
        XCTAssert(collection.firstObject?.localizedTitle == "UnitTest")
        
        await lib.removeFromAlbum(asset: asset!, album: dest!)
        
        await lib.addToAlbum(asset: asset!, album: source!)
        
        let fetchedAssetResultBack = PHAsset.fetchAssets(withLocalIdentifiers: [asset!.localIdentifier], options: options)
        
        XCTAssert(fetchedAssetResultBack.count == 1)
        
        let fetchedAssetBack = fetchedAssetResult.firstObject
        let collectionBack = PHAssetCollection.fetchAssetCollectionsContaining(fetchedAssetBack!, with: .album, options: options)
        
        XCTAssert(collectionBack.count == 1)
        
        XCTAssert(collectionBack.firstObject?.localizedTitle == "UnitTest2")
        
        
        await lib.deleteAlbum(assetCollection: source!);
        await lib.deleteAlbum(assetCollection: dest!);
    }
    
    func testRemoveFromLib() async throws {
        let options = PHFetchOptions()
        let recents = lib._albums["Recents"]
        let assets = PHAsset.fetchAssets(in: recents!, options: options)
        let asset = assets.firstObject
        await lib.removeFromLibrary(asset: asset!)
        
        let collection = PHAssetCollection.fetchAssetCollectionsContaining(asset!, with: .smartAlbum, options: options)
        
        XCTAssert(collection.count == 0)

    }
    
    
    

}
