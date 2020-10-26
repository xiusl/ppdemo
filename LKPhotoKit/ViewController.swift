//
//  ViewController.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/21.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // Do any additional setup after loading the view.
        
        let button = UIButton()
        button.frame = CGRect(x: 100, y: 100, width: 80, height: 40)
        button.setTitle("选择", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(buttonClickAction), for: .touchUpInside)
        view.addSubview(button)
        
        
        let button2 = UIButton()
        button2.frame = CGRect(x: 100, y: 160, width: 80, height: 40)
        button2.setTitle("拍视频", for: .normal)
        button2.setTitleColor(.black, for: .normal)
        button2.addTarget(self, action: #selector(button2ClickAction), for: .touchUpInside)
        view.addSubview(button2)
        
        testVersion()
        
        let v = LightProgressControl(frame: CGRect(x: 50, y: 300, width: 300, height: 60))
        v.backgroundColor = .lightGray
        view.addSubview(v)
        
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let filePath = cachePath.appending("/work.mp4")
        
        print(FileManager.default.fileExists(atPath: filePath))
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                
                try FileManager.default.removeItem(atPath: filePath)
               
                    print("delete success")
                
        
            } catch {
                
            }
        }
        
    }
    
    func testVersion() {
        assert(compareVersion("1.0", version2: "1.1") == -1, "soso")
        assert(compareVersion("1.0.1", version2: "1.1") == -1, "soso")
        assert(compareVersion("1.0.12", version2: "1.1") == -1, "soso")
        assert(compareVersion("1.2.1", version2: "1.2.13") == -1, "soso")
        
        assert(compareVersion("1.2.1", version2: "1.2.0") == 1, "soso")
        assert(compareVersion("1.2.13", version2: "1.2.12") == 1, "soso")
        assert(compareVersion("1.3.2", version2: "1.2.12") == 1, "soso")
        assert(compareVersion("1.2.101", version2: "1.1.1") == 1, "soso")
        
        
        assert(compareVersion("1.1", version2: "1.1") == 0, "soso")
    }
    
    private func compareVersion(_ version1: String, version2: String) -> Int {
        // v1 > v2: 1
        // v1 < v2: -1
        switch version1.compare(version2, options: .numeric, range: nil, locale: nil){
        case .orderedAscending:
            return -1
        case .orderedDescending:
            return 1
        case .orderedSame:
            return 0
        }
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//       let vc = LKPhotoPickerViewController(originalPhoto: true)
//        vc.modalPresentationStyle = .fullScreen
//        self.present(vc, animated: true, completion: nil)
    }
    
    @objc
    func buttonClickAction() {
        let vc = EyuCameraViewController()
        self.navigationController?.pushViewController(vc, animated: true)
//        vc.modalPresentationStyle = .fullScreen
//        self.present(vc, animated: true, completion: nil)
        
    }
    
    @objc
    func button2ClickAction() {
        let vc = EyuCameraViewController()
        vc.isVideo = true
        self.navigationController?.pushViewController(vc, animated: true)
//        vc.modalPresentationStyle = .fullScreen
//        self.present(vc, animated: true, completion: nil)
        
    }
}

