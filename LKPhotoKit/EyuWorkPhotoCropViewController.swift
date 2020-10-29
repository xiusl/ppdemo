//
//  EyuWorkPhotoCropViewController.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/22.
//

import UIKit

class EyuWorkPhotoCropViewController: UIViewController, UIScrollViewDelegate {
    
    public var didFinishCropping: ((UIImage) -> Void)?
    var asster: LKAsset?
    var image: UIImage?
    var originalPhoto: UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        title = "矫正"
        
        let w = self.view.bounds.size.width
        let h = self.view.bounds.size.height
        
        
        guard let `image` = image else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        
        let topH = UIApplication.shared.statusBarFrame.size.height + 44
        let cropH = h - topH - 103
        let frame = CGRect(x: 0, y: topH, width: w, height: cropH)
        let v = LKPhotoCropView(image: image, frame: frame)
        
        self.view.addSubview(v)
        
        view.addSubview(bottomView)
        bottomView.addSubview(originalButton)
        bottomView.addSubview(doneButton)
        self.setupGestureRecognizers(v: v)
        
        self.vv = v
    }
    
    var vv: LKPhotoCropView?
    
    private let pinchGR = UIPinchGestureRecognizer()
    private let panGR = UIPanGestureRecognizer()
    
    func setupGestureRecognizers(v: LKPhotoCropView) {
        // Pinch Gesture
        pinchGR.addTarget(self, action: #selector(pinch(_:)))
        pinchGR.delegate = self
        v.imageView.addGestureRecognizer(pinchGR)
        
        // Pan Gesture
        panGR.addTarget(self, action: #selector(pan(_:)))
        panGR.delegate = self
        v.imageView.addGestureRecognizer(panGR)
    }
    
    
    lazy var bottomView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: self.view.frame.size.height-103, width: self.view.frame.size.width, height: 103)
        view.backgroundColor = .white
        return view
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: 12, y: 100, width: 64, height: 40)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    lazy var originalButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle("使用原图", for: .normal)
        button.setTitleColor(UIColor(red: 47/255.0, green: 47/255.0, blue: 47/255.0, alpha: 1), for: .normal)
        button.backgroundColor = UIColor(red: 246/255.0, green: 247/255.0, blue: 248/255.0, alpha: 1)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.frame = CGRect(x: self.view.frame.size.width * 0.5 - 10-138, y: 31, width: 138, height: 40)
        button.addTarget(self, action: #selector(originalButtonAction), for: .touchUpInside)
        return button
    }()
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle("裁剪", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 111/255.0, green: 220/255.0, blue: 123/255.0, alpha: 1)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.frame = CGRect(x: self.view.frame.size.width * 0.5 + 10, y: 31, width: 138, height: 40)
        button.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        return button
    }()
    
    @objc
    func originalButtonAction() {
        let vc = EyuWorkPhotoEditViewController()
        vc.image = image!
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @objc
    func doneButtonAction() {
        guard let v = self.vv else {
            return
        }
        guard let image = self.image else {
            return
        }
        
        let xCrop = v.cropArea.frame.minX - v.imageView.frame.minX
        let yCrop = v.cropArea.frame.minY - v.imageView.frame.minY
        let widthCrop = v.cropArea.frame.width
        let heightCrop = v.cropArea.frame.height
        let scaleRatio = image.size.width * image.scale / v.imageView.frame.width
        let scaledCropRect = CGRect(x: xCrop * scaleRatio,
                                    y: yCrop * scaleRatio,
                                    width: widthCrop * scaleRatio,
                                    height: heightCrop * scaleRatio)
        if let cgImage = image.toCIImage()?.toCGImage(),
            let imageRef = cgImage.cropping(to: scaledCropRect) {
            let croppedImage = UIImage(cgImage: imageRef)
            didFinishCropping?(croppedImage)
        
            
            UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil)
            
            let vc = EyuWorkPhotoEditViewController()
            vc.image = croppedImage
            self.navigationController?.pushViewController(vc, animated: true)
        }
//        self.navigationController?.popViewController(animated: true)
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    lazy var contentView: UIScrollView = {
        let view = UIScrollView()
        let w = self.view.bounds.size.width
        let h = self.view.bounds.size.height
        view.frame = CGRect(x: 0, y: 0, width: w, height: h-48)
        view.contentSize = CGSize(width: w, height: h-48)
        view.maximumZoomScale = 10;
        view.minimumZoomScale = 0.8;
        view.delegate = self;
        return view;
    }()
    
//    viewForZooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let w = scrollView.bounds.size.width
        let imW = self.imageView.bounds.size.width
        let h = scrollView.bounds.size.height
        let imH = self.imageView.bounds.size.height
        let x = w > imW ? (w-imW)*0.5 : 0;
        let y = h > imH ? (h-imH)*0.5 : 0;
        print("x: \(x), y:\(y), imW:\(imW), imH:\(imH)")
//        self.imageView.frame = CGRect(x: x, y: y, width: imW, height: imH);
//        scrollView.contentSize = CGSize(width: imW+30, height: imH+30)
    }
    
    @objc func cancelButtonAction() {
        self.navigationController?.popViewController(animated: true)
    }
}



extension EyuWorkPhotoCropViewController: UIGestureRecognizerDelegate {
    @objc
    func pinch(_ sender: UIPinchGestureRecognizer) {
        // TODO: Zoom where the fingers are (more user friendly)
        guard let v = self.vv else {
            return
        }
        switch sender.state {
        case .began, .changed:
            var transform = v.imageView.transform
            // Apply zoom level.
            transform = transform.scaledBy(x: sender.scale,
                                            y: sender.scale)
            v.imageView.transform = transform
        case .ended:
            pinchGestureEnded()
        case .cancelled, .failed, .possible:
            ()
        @unknown default:
            fatalError()
        }
        // Reset the pinch scale.
        sender.scale = 1.0
    }
    
    private func pinchGestureEnded() {
        guard let v = self.vv else {
            return
        }
        var transform = v.imageView.transform
        let kMinZoomLevel: CGFloat = 1.0
        let kMaxZoomLevel: CGFloat = 3.0
        var wentOutOfAllowedBounds = false
        
        // Prevent zooming out too much
        if transform.a < kMinZoomLevel {
            transform = .identity
            wentOutOfAllowedBounds = true
        }
        
        // Prevent zooming in too much
        if transform.a > kMaxZoomLevel {
            transform.a = kMaxZoomLevel
            transform.d = kMaxZoomLevel
            wentOutOfAllowedBounds = true
        }
        
        // Animate coming back to the allowed bounds with a haptic feedback.
        if wentOutOfAllowedBounds {
            generateHapticFeedback()
            UIView.animate(withDuration: 0.3, animations: {
                self.vv?.imageView.transform = transform
            })
        }
    }
    
    func generateHapticFeedback() {
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    // MARK: - Pan Gesture
    
    @objc
    func pan(_ sender: UIPanGestureRecognizer) {
        guard let v = self.vv else {
            return
        }
        let translation = sender.translation(in: view)
        let imageView = v.imageView
        
        // Apply the pan translation to the image.
        imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
        
        // Reset the pan translation.
        sender.setTranslation(CGPoint.zero, in: view)
        
        if sender.state == .ended {
            keepImageIntoCropArea()
        }
    }
    
    private func keepImageIntoCropArea() {
        guard let v = self.vv else {
            return
        }
        let imageRect = v.imageView.frame
        let cropRect = v.cropArea.frame
        var correctedFrame = imageRect
        
        // Cap Top.
        if imageRect.minY > cropRect.minY {
            correctedFrame.origin.y = cropRect.minY
        }
        
        // Cap Bottom.
        if imageRect.maxY < cropRect.maxY {
            correctedFrame.origin.y = cropRect.maxY - imageRect.height
        }
        
        // Cap Left.
        if imageRect.minX > cropRect.minX {
            correctedFrame.origin.x = cropRect.minX
        }
        
        // Cap Right.
        if imageRect.maxX < cropRect.maxX {
            correctedFrame.origin.x = cropRect.maxX - imageRect.width
        }
        
        // Animate back to allowed bounds
        if imageRect != correctedFrame {
            UIView.animate(withDuration: 0.3, animations: {
                self.vv?.imageView.frame = correctedFrame
            })
        }
    }
    
    /// Allow both Pinching and Panning at the same time.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension UIImage {
    func toCIImage() -> CIImage? {
        return self.ciImage ?? CIImage(cgImage: self.cgImage!)
    }
}

internal extension CIImage {
    func toUIImage() -> UIImage {
        /* If need to reduce the process time, than use next code. But ot produce a bug with wrong filling in the simulator.
         return UIImage(ciImage: self)
         */
        let context: CIContext = CIContext.init(options: nil)
        let cgImage: CGImage = context.createCGImage(self, from: self.extent)!
        let image: UIImage = UIImage(cgImage: cgImage)
        return image
    }
    
    func toCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        return nil
    }
}
