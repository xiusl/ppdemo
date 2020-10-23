//
//  LkFileManager.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/23.
//

import UIKit

class LkFileManager: NSObject {
    class func homeDir() -> String {
        return NSHomeDirectory()
    }
    class func documentsDir() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    class func libraryDir() -> String {
        return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
    }
    class func preferencesDir() -> String {
        return libraryDir().appending("/Preferences")
    }
    class func cachesDir() -> String{
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    }
    class func tmpDir() -> String {
        return NSTemporaryDirectory()
    }
    
    class func createDir(at path: String) -> Bool {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }
        return true
    }
}
