//
//  EyuWorkPhotoEditViewController.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/22.
//

import UIKit

class EyuWorkPhotoEditViewController: UIViewController {

    var image: UIImage!
    var cropController: UIViewController?
    var accessController: UIViewController?
    var cameraController: UIViewController?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor(red: 241/255.0, green: 241/255.0, blue: 245/255.0, alpha: 1)
        title = "装裱"
        
        let navRightItem = UIBarButtonItem(title: "下一步", style: .plain, target: self, action: #selector(navRightAction))
        self.navigationItem.rightBarButtonItem = navRightItem
        
        let imageSize = image.size
        
        let w = isIPad ? 360 : (self.view.frame.size.width - 140)
        let w2 = isIPad ? 400 : (self.view.frame.size.width - 100)
        var h = w
        var h2 = w2
        if imageSize.width < imageSize.height {
            h = w * 4 / 3
            h2 = h + 40
        } else if imageSize.width > imageSize.height {
            h = w * 3 / 4
            h2 = h + 40
        }
        
        
        let topH = UIApplication.shared.statusBarFrame.size.height + 44
        let viewH = self.view.frame.size.height - topH - bottomView.frame.size.height
        
        
        view.addSubview(sideView)
        sideView.frame = CGRect(x: (self.view.frame.size.width-w2)*0.5, y: (viewH-h2)*0.5+topH, width: w2, height: h2)
        sideView.image = UIImage.resizeImage("work_side")
        
        sideView.layer.shadowOffset = CGSize(width: 10, height: 10)
        sideView.layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor
        sideView.layer.shadowOpacity = 1
    
        sideView.addSubview(imageView)
        imageView.frame = CGRect(x: 20, y: 20, width: w, height: h)
        imageView.image = image
        
        view.addSubview(bottomView)
        bottomView.setup { [weak self] (value) in
            self?.adjustLight(to: value)
        }
    }
    @objc
    func navRightAction() {
        if let image = getNewImage() {
            
            let workVc = WorkUploadViewController()
            workVc.image = image
            workVc.originalImage = self.image
            workVc.cropController = self.cropController
            workVc.accessController = self.accessController
            workVc.cameraController = self.cameraController
            self.navigationController?.pushViewController(workVc, animated: true)
        } else {
            print("图片生成失败")
        }
            
       
    }
    private func getNewImage() -> UIImage? {
        UIGraphicsBeginImageContext(sideView.bounds.size)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        sideView.layer.render(in: ctx)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
    private func adjustLight(to value: Int) {
        let oldImage = self.image
        let superImage = oldImage?.toCIImage()
        let lighten = CIFilter(name: "CIColorControls")
        lighten?.setValue(superImage, forKey: kCIInputImageKey)
        lighten?.setValue( Double(value - 50) / 50.0 * 0.5, forKey: "inputBrightness")
        let res = lighten?.value(forKey: kCIOutputImageKey) as? CIImage
        let newImage = res?.toUIImage()
        
        self.imageView.image = newImage
        
        /*
         UIImage *myImage = [UIImage imageNamed:@"Superman"];
         CIContext *context = [CIContext contextWithOptions:nil];
         CIImage *superImage = [CIImage imageWithCGImage:myImage.CGImage];
         CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
         [lighten setValue:superImage forKey:kCIInputImageKey];

         // 修改亮度   -1---1   数越大越亮
         [lighten setValue:@(0.2) forKey:@"inputBrightness"];

         // 修改饱和度  0---2
         [lighten setValue:@(0.5) forKey:@"inputSaturation"];

         // 修改对比度  0---4
         [lighten setValue:@(2.5) forKey:@"inputContrast"];
         CIImage *result = [lighten valueForKey:kCIOutputImageKey];
         CGImageRef cgImage = [context createCGImage:result fromRect:[superImage extent]];

         // 得到修改后的图片
         myImage = [UIImage imageWithCGImage:cgImage];

         // 释放对象
         CGImageRelease(cgImage);
         */
    }
    

    var imageView: UIImageView = UIImageView()
    var sideView: UIImageView = UIImageView()
    
    lazy var bottomView: EyuWorkPhotoEidtBottomView = {
        var height: CGFloat = 103
        if UIApplication.shared.statusBarFrame.size.height > 20 {
            height = 103 + 20
        }
        let view = EyuWorkPhotoEidtBottomView(frame: CGRect(x: 0, y: self.view.frame.size.height-height, width: self.view.frame.size.width, height: height))
//        view.frame =
        view.backgroundColor = .white
        return view
    }()

}
extension UIImage {
    class func resizeImage(_ name: String) -> UIImage {
        guard let sourceImage: UIImage = UIImage.init(named: name) else {
                return UIImage.init()
        }
        let w = sourceImage.size.width * 0.5
        let h = sourceImage.size.height * 0.5
        let handledImage:UIImage = sourceImage.resizableImage(withCapInsets: .init(top: h, left: w, bottom: h, right: w))
        return handledImage
    }
}
