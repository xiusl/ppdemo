//
//  AppDelegate.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = BaseNavigationViewController(rootViewController: ViewController())
        window?.makeKeyAndVisible()
        return true
    }




}
let isIPad: Bool = {
    return UIDevice.current.model == "iPad"
}()
