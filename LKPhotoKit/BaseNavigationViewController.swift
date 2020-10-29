//
//  BaseNavigationViewController.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/29.
//

import UIKit

class BaseNavigationViewController: KLTNavigationController, UINavigationControllerDelegate {
    var popDelegate: UIGestureRecognizerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.navigationBar.barTintColor = .white
        // 标题颜色
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        // 去掉阴影线
        self.navigationBar.shadowImage = UIImage.init()
        
        self.popDelegate = self.interactivePopGestureRecognizer?.delegate
        self.delegate = self
    }
    

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        //实现滑动返回的功能
        if viewController == self.viewControllers[0] {
            self.interactivePopGestureRecognizer?.delegate = self.popDelegate
        } else {
            self.interactivePopGestureRecognizer?.delegate = nil
        }
    }

}
