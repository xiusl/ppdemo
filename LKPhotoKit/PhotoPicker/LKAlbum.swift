//
//  LKAlbum.swift
//  Like
//
//  Created by xiusl on 2019/11/22.
//  Copyright © 2019 likeeee. All rights reserved.
//

import UIKit
import Photos

class LKAsset: NSObject {
    var asset: PHAsset?
    var filePath: String?
    
    func getFilePath() -> String {
        asset?.requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler: { (input, _) in
            let url = input?.fullSizeImageURL
        })
        
        return "123"
    }
}

class LKAlbum: NSObject {
    var name: String = ""
    var count: Int = 0
    var models: Array<LKAsset> = []
    
    
    class func create(withCollection collection: PHAssetCollection, assetResult: PHFetchResult<PHAsset>) -> LKAlbum {
        let ablum = LKAlbum()
        ablum.name = collection.localizedTitle ?? ""
        ablum.count = assetResult.count
        
        let opt = PHImageRequestOptions()
        var arr:Array<LKAsset> = []
        assetResult.enumerateObjects { (asset, idx, stop) in
            let mod = LKAsset()
            mod.asset = asset
            arr.append(mod)
            
            PHImageManager.default().requestImageData(for: asset, options: opt) { (data, url, orientation, info) in
                
            }
        }
        ablum.models = arr
        
        return ablum
    }
}
