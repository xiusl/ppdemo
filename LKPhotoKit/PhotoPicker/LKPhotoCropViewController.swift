//
//  LKPhotoCropViewController.swift
//  Like
//
//  Created by xiu on 2020/4/27.
//  Copyright © 2020 likeeee. All rights reserved.
//

import UIKit
import Photos

class LKPhotoCropViewController: UIViewController, UIScrollViewDelegate {
    
    public var didFinishCropping: ((UIImage) -> Void)?
    var asster: LKAsset?
    var image: UIImage?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        
        let w = self.view.bounds.size.width
        let h = self.view.bounds.size.height
        
        
        guard let `image` = image else { return }
        
        let frame = CGRect(x: 0, y: 0, width: w, height: h)
        let v = LKPhotoCropView(image: image, frame: frame)
        
        self.view.addSubview(v)
        
        self.view.addSubview(self.cancelButton)
        self.view.addSubview(self.doneButton)
        
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
    

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: 12, y: 100, width: 64, height: 40)
        button.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        return button
    }()
    
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle("完成", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: 100, y: 100, width: 64, height: 40)
        button.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        return button
    }()
    
    @objc
    func doneButtonAction() {
        guard let v = self.vv else {
            return
        }
        guard let image = v.imageView.image else {
            return
        }
        
        let xCrop = v.cropArea.frame.minX - v.imageView.frame.minX
        let yCrop = v.cropArea.frame.minY - v.imageView.frame.minY
        let widthCrop = v.cropArea.frame.width
        let heightCrop = v.cropArea.frame.height
        let scaleRatio = image.size.width / v.imageView.frame.width
        let scaledCropRect = CGRect(x: xCrop * scaleRatio,
                                    y: yCrop * scaleRatio,
                                    width: widthCrop * scaleRatio,
                                    height: heightCrop * scaleRatio)
        if let cgImage = image.toCIImage()?.toCGImage(),
            let imageRef = cgImage.cropping(to: scaledCropRect) {
            let croppedImage = UIImage(cgImage: imageRef)
            didFinishCropping?(croppedImage)
        }
        self.navigationController?.popViewController(animated: true)
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
    
    lazy var cropView: PhotoCropView = {
        let w = self.view.bounds.size.width
        let h = self.view.bounds.size.height
        let frame = CGRect(x: 0, y: 0, width: w, height: h)
        let view = PhotoCropView(frame: frame)
        return view
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

class PhotoCropView: UIView {
    private var topLeft: CGPoint = .zero
    private var topRight: CGPoint = .zero
    private var bottomLeft: CGPoint = .zero
    private var bottomRight: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let viewH = frame.size.height
        let viewW = frame.size.width
        
        self.backgroundColor = UIColor(hex: 0x000000, alpha: 0.3)
        
        let cropWH = viewW - 32
        let cropT = (viewH - cropWH) * 0.5
        
        topLeft = CGPoint(x: 16, y: cropT)
        topRight = CGPoint(x: viewW - 16, y: cropT)
        bottomLeft = CGPoint(x: 16, y: cropT + cropWH)
        bottomRight = CGPoint(x: viewW - 16, y: cropT + cropWH)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
//        let w = rect.size.width
//        let h = rect.size.height
        
        let x = self.topLeft.x
        let y = self.topLeft.y
        let wh = self.topRight.x - self.topLeft.x
        
        let f = CGRect(x: x, y: y, width: wh, height: wh)
        let path = UIBezierPath(rect: f)
        UIColor.white.set()
        path.lineWidth = 1
        path.stroke()
        
        UIColor.clear.set()
        path.fill(with: .clear, alpha: 0)
        
        let path2 = UIBezierPath()
        UIColor.white.set()
        path2.lineWidth = 2
        
        path2.move(to: CGPoint(x: self.topLeft.x+20, y: self.topLeft.y))
        path2.addLine(to: self.topLeft)
        path2.addLine(to: CGPoint(x: self.topLeft.x, y: self.topLeft.y+20))
        
        path2.move(to: CGPoint(x: self.topRight.x-20, y: self.topRight.y))
        path2.addLine(to: self.topRight)
        path2.addLine(to: CGPoint(x: self.topRight.x, y: self.topRight.y+20))
        
        path2.move(to: CGPoint(x: self.bottomLeft.x+20, y: self.bottomLeft.y))
        path2.addLine(to: self.bottomLeft)
        path2.addLine(to: CGPoint(x: self.bottomLeft.x, y: self.bottomLeft.y-20))

        path2.move(to: CGPoint(x: self.bottomRight.x, y: self.bottomRight.y-20))
        path2.addLine(to: self.bottomRight)
        path2.addLine(to: CGPoint(x: self.bottomRight.x-20, y: self.bottomRight.y))
        
        path2.stroke()
        
        let path3 = UIBezierPath()
        UIColor.white.set()
        path3.lineWidth = 1
    }
}


extension LKPhotoCropViewController: UIGestureRecognizerDelegate {
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

