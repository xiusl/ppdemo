//
//  EyuCameraViewController.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/21.
//

import UIKit
import AVFoundation
import TZImagePickerController
import PhotosUI

class EyuCameraViewController: UIViewController {
    
    var accessController: UIViewController?
    
    var didSelectVideo: ((UIImage, URL) -> (Void))?
    
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    var microphoneDevice: AVCaptureDevice!
    
    var photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    var audioDeviceInput: AVCaptureDeviceInput?
    var videoDeviceInput: AVCaptureDeviceInput?
    
    var videoDataOutput: AVCaptureVideoDataOutput!
    var audioDataOutput: AVCaptureAudioDataOutput!
    let dataOutputQueue = DispatchQueue(label: "com.eyuschool.camera.queue")
    let dataWriteQueue = DispatchQueue(label: "com.eyuschool.camera.queue")
    
    var position: AVCaptureDevice.Position = .back
    
    var isVideo: Bool = false
    var imageView = UIImageView()
    
    var animateActivity: Bool = false
    var takePhoto: Bool = false
    var recording: Bool = false
    
    var recordTime = 0.0
    
    
    
    var videoUrl: URL!
    var assetWriter: AVAssetWriter?
    var assetWriterVideoInput: AVAssetWriterInput?
    var assetWriterAudioInput: AVAssetWriterInput?
    
    
    var timer: Timer?
    
    var navBarBgView: UIView?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarBgView = self.navigationController?.navigationBar.subviews.first
        navBarBgView?.alpha = 0
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navBarBgView?.alpha = 1
    }
    var aWidth: CGFloat = 100
    override func viewDidLoad() {
        self.aWidth = self.view.frame.size.width
        super.viewDidLoad()
        view.backgroundColor = .white
        
        
        let captureTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AutoFocusGesture(_:)))
        captureTapGesture.numberOfTapsRequired = 1
        captureTapGesture.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(captureTapGesture)
        
        
        
        setupPreviewLayer()
        setupViews()
        configSession()
        requestAuthorization()
        
        if isVideo {
            //            setupAssetWriter()
        }
        
        var width: CGFloat = 44
        if isIPad {
            width = 80
        }
        let selectView = EyuPhotoCropSizeSelectView()
        selectView.frame = CGRect(x: 0, y: 0, width: width*3, height: 44)
        self.navigationItem.titleView = selectView
        
        selectView.sizeScaleChange = { value in
            self.resizePreview(scale: value)
        }
    }
    var scale: CGFloat = 4/3.0
    func resizePreview(scale: CGFloat) {
        var top = UIApplication.shared.statusBarFrame.size.height + 44
        self.scale = scale
        
        var width = aW
        let screenH = UIScreen.main.bounds.size.height
        let screenW = UIScreen.main.bounds.size.height
        let contentH = screenH - top - self.bottomView.bounds.size.height
        
        var h = CGFloat(Int(width / scale))
        var left: CGFloat = 0
        if h > contentH { //
            if h <= screenH {
                top = 0
            } else {
                top = 0
                h = screenH
                width = h * scale
                left = (screenW - width)/2
            }
        } else {
            top = top + (contentH - h) / 2
        }
        
        
        
        if scale == 1 {
            self.previewLayer.frame = CGRect(x: left, y: top, width: width, height: h)
        } else if scale < 1 {
            self.previewLayer.frame = CGRect(x: left, y: top, width: width, height: h)
        } else {
            self.previewLayer.frame = CGRect(x: left, y: top, width: width, height: h)
        }
    }
    
    func configSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        

    }
    let aW = UIScreen.main.bounds.size.width
    let aH = UIScreen.main.bounds.size.width * 3 / 4
    func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: captureSession)
//        self.previewLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height-167)
        
        
        self.previewLayer.frame = CGRect(x: 0, y: 160, width: aW, height: aH)
        self.previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer.masksToBounds = true
        self.view.layer.addSublayer(previewLayer)
    }
    
    
    private func setupViews() {
        view.addSubview(bottomView)
        bottomView.addSubview(selectPhotoButton)
        bottomView.addSubview(swapCameraButton)
        bottomView.addSubview(takePhotoButton)
        bottomView.addSubview(guideButton)
        
        imageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        imageView.contentMode = .scaleAspectFit
        bottomView.addSubview(imageView)
    }
    private lazy var bottomView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: self.view.frame.size.height-167, width: self.view.frame.size.width, height: 157)
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var selectPhotoButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setTitleColor(UIColor(red: 36/255.0, green: 38/255.0, blue: 42/255.0, alpha: 1), for: .normal)
        button.frame = CGRect(x: self.view.frame.size.width*0.5-146, y: 56, width: 64, height: 64)
        button.setup(image: UIImage(named: "shot_album"), title: "从相册选择", titlePosition: .bottom, additionalSpacing: 7.5, state: .normal)
        button.addTarget(self, action: #selector(selectPhotoButtonAction), for: .touchUpInside)
        return button
    }()
    private lazy var swapCameraButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.setTitleColor(UIColor(red: 36/255.0, green: 38/255.0, blue: 42/255.0, alpha: 1), for: .normal)
        button.frame = CGRect(x: self.view.frame.size.width*0.5+32+50, y: 56, width: 64, height: 64)
        button.setup(image: UIImage(named: "shot_rotate"), title: "切换摄像头", titlePosition: .bottom, additionalSpacing: 7.5, state: .normal)
        button.addTarget(self, action: #selector(swapCameraAction), for: .touchUpInside)
        return button
    }()
    private lazy var takePhotoButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: self.view.frame.size.width*0.5-32, y: 56, width: 64, height: 64)
        button.backgroundColor = .green
        button.addTarget(self, action: #selector(takePhotoAction), for: .touchUpInside)
        button.clipsToBounds = true
        button.layer.cornerRadius = 32
        button.setTitle(isVideo ? "开始":"拍照", for: .normal)
        button.setTitle(isVideo ? "完成":"拍照", for: .selected)
        return button
    }()
    private lazy var guideButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect(x: (self.view.frame.size.width-400)*0.5, y: 20, width: 400, height: 20)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(UIColor(red: 36/255.0, green: 38/255.0, blue: 41/255.0, alpha: 1), for: .normal)
        button.setImage(UIImage(named: "camera_guide"), for: .normal)
        button.setTitle(isVideo ? "拍个小视频介绍你的作品故事吧～" : "拍一张作品给老师吧～", for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        return button
    }()
    
    
    
    @objc
    private func takePhotoAction() {
        if isVideo {
            recording = !recording
            if recording {
                if assetWriter == nil {
                    self.setupAssetWriter()
                }
                takePhotoButton.isSelected = true
            } else {
                takePhotoButton.isSelected = false
                endRecording()
                self.timer?.invalidate()
                self.timer = nil
            }
        } else {
            let width = self.previewLayer.bounds.size.width
            let height = self.previewLayer.bounds.size.height
            
           
            let settings = AVCapturePhotoSettings()
            let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                        kCVPixelBufferWidthKey as String: width,
                                           kCVPixelBufferHeightKey as String: height] as [String : Any]

            settings.previewPhotoFormat = previewFormat
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    @objc
    private func swapCameraAction() {
        if position == .back {
            swapCamera(to: .front)
            position = .front
        } else {
            swapCamera(to: .back)
            position = .back
        }
    }
    @objc
    private func selectPhotoButtonAction() {
        //        let vc = LKPhotoPickerViewController(originalPhoto: true)
        let vc = TZImagePickerController(maxImagesCount: 1, delegate: self)!
        
        vc.allowTakeVideo = false
        vc.allowTakePicture = false
        vc.allowPickingVideo = isVideo
        vc.allowPickingImage = !isVideo
        vc.allowPickingGif = false
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
        
    }
    
    func destroyWrite() {
        self.assetWriter = nil;
        self.assetWriterAudioInput = nil;
        self.assetWriterVideoInput = nil;
        self.videoUrl = nil;
        self.recordTime = 0;
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    deinit {
        print("销毁")
        
        destroyWrite()
    }
    
    
    func swapCamera(to position: AVCaptureDevice.Position) {
        if let deviceInput = self.videoDeviceInput {
            captureSession.beginConfiguration()
            captureSession.removeInput(deviceInput)
            
            guard let device = getCaptureDevice(with: position) else {
                // 提示摄像头不可用
                self.showAlter(title: "提示", message: "相机不可使用，请检查设备", action: "确定", handler: nil)
                return
            }
            
            captureDevice = device
            do {
                let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                if captureSession.canAddInput(captureDeviceInput) {
                    captureSession.addInput(captureDeviceInput)
                    self.videoDeviceInput = captureDeviceInput
                }
            } catch {
                print(error.localizedDescription)
                return
            }
            captureSession.commitConfiguration()
        }
    }
    
    @objc
    func AutoFocusGesture(_ tapGest: UITapGestureRecognizer) {
        let touchPoint: CGPoint = tapGest.location(in: self.view)
        //GET PREVIEW LAYER POINT
        let convertedPoint = self.previewLayer.captureDevicePointConverted(fromLayerPoint: touchPoint)
        
        //Assign Auto Focus and Auto Exposour
        if let device = self.captureDevice {
            do {
                try! device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = convertedPoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = convertedPoint
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            }
        }
    }
    
    @objc
    func closeController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func requestAuthorization() {
        DispatchQueue.global().async {
            switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .authorized:
                DispatchQueue.main.async {
                    self.openCamera()
                }
            case .denied, .notDetermined, .restricted:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted) in
                    DispatchQueue.main.async {
                        if granted {
                            self?.openCamera()
                        } else {
                            // 提示打开相机权限
                            self?.showAlter(title: "提示", message: "没有权限，请在设置中开启相机权限", action: "确定", handler: nil)
                        }
                    }
                }
            default:
                fatalError()
            }
            
            if self.isVideo {
                switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
                case .authorized:
                    DispatchQueue.main.async {
                        self.openMic()
                    }
                case .denied, .notDetermined, .restricted:
                    AVCaptureDevice.requestAccess(for: .audio) { [weak self] (granted) in
                        DispatchQueue.main.async {
                            if granted {
                                self?.openMic()
                            } else {
                                self?.showAlter(title: "提示", message: "没有权限，请在设置中开启麦克风权限", action: "确定", handler: nil)
                            }
                        }
                    }
                default:
                    fatalError()
                }
            }
        }
        
        
        
    }
    
    func openMic() {
        guard let device = getMicrophoneDevice() else {
            self.showAlter(title: "提示", message: "麦克风不可使用，请检查设备", action: "确定", handler: nil)
            return
        }
        self.microphoneDevice = device
        do {
            let audioInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            self.audioDeviceInput = audioInput
        } catch {
            print(error.localizedDescription)
        }
        
        audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        if captureSession.canAddOutput(audioDataOutput) {
            captureSession.addOutput(audioDataOutput)
        }
        
        captureSession.commitConfiguration()
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    func openCamera() {
        guard let device = getCaptureDevice(with: .back) else {
            self.showAlter(title: "提示", message: "相机不可使用，请检查设备", action: "确定", handler: nil)
            return
        }
        self.captureDevice = device
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            self.videoDeviceInput = captureDeviceInput
        } catch {
            print(error.localizedDescription)
        }
        
        
        self.videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        captureSession.commitConfiguration()
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    
    func setupAssetWriter() {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let filePath = cachePath.appending("/work.mp4")
        self.videoUrl = URL(fileURLWithPath: filePath)
        
        do {
            assetWriter = try AVAssetWriter(url: self.videoUrl, fileType: .mp4)
            
            let width = self.previewLayer.bounds.size.width
            let height = self.previewLayer.bounds.size.height
            
            let compressionProperties: Dictionary<String, Any> = [
                AVVideoAverageBitRateKey: 6.0 * width*height,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
            let videoSetting: Dictionary<String, Any> = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                AVVideoWidthKey: width*2,
                AVVideoHeightKey: height*2,
                AVVideoCompressionPropertiesKey: compressionProperties
            ]
            
            
            let audioSetting: Dictionary<String, Any> = [
                AVEncoderBitRatePerChannelKey: 28000,
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 22050
            ]
            
            assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSetting)
            assetWriterVideoInput!.expectsMediaDataInRealTime = true
            assetWriterVideoInput!.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi * 0.5))
            
            
            
            assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSetting)
            assetWriterAudioInput!.expectsMediaDataInRealTime = true
            
            if assetWriter!.canAdd(assetWriterVideoInput!) {
                assetWriter!.add(assetWriterVideoInput!)
            } else {
                print("AssetWriter audioInput append Failed")
            }
            if assetWriter!.canAdd(assetWriterAudioInput!) {
                assetWriter!.add(assetWriterAudioInput!)
            } else {
                print("AssetWriter videoInput append Failed")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func endRecording() {
        self.didEnd = true
        if let assetWriter = self.assetWriter {
            self.dataWriteQueue.async {
                
                assetWriter.finishWriting {
                    //                ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                    //                [lib writeVideoAtPathToSavedPhotosAlbum:weakSelf.videoUrl completionBlock:nil];
                    PHPhotoLibrary.shared().performChanges { [weak self] in
//                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: self!.videoUrl)
                        
                        if let req: PHAssetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self!.videoUrl) {
                            
                        }
                        
                    } completionHandler: { [weak self] (flag, error) in
                        print("写入相册\(String(describing: error))")
                        if flag {
                            DispatchQueue.main.async {
                                self?.didSelectVideo?(self!.getVideoPreview(url: self!.videoUrl.absoluteString), self!.videoUrl)
                                self?.navigationController?.popViewController(animated: true)
                            }
                            
                        }
                    }
                    
                }
            }
            
        }
    }
    func getVideoPreview(url: String) -> UIImage {
        let asset = AVURLAsset(url: URL(string: url)!)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let time: CMTime = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
        var actualTime: CMTime = CMTimeMakeWithSeconds(0, preferredTimescale: 0)
        do {
            let im = try gen.copyCGImage(at: time, actualTime: &actualTime)
            return UIImage(cgImage: im)
        } catch {
            return UIImage()
        }
    }
    var canWrite: Bool = false
    var didEnd: Bool = false
}

extension EyuCameraViewController  {
    func getCaptureDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position).devices
        if availableDevices.first != nil {
            return availableDevices.first
        } else {
            return nil
        }
    }
    func getMicrophoneDevice() -> AVCaptureDevice? {
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInMicrophone], mediaType: AVMediaType.audio, position: .unspecified).devices
        if availableDevices.first != nil {
            return availableDevices.first
        } else {
            return nil
        }
    }
    
}
extension EyuCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if isVideo {
            //            objc_sync_enter(self)
            
            
            self.dataWriteQueue.async {
                
                
                //                objc_sync_enter(self)
                guard let assetWriter = self.assetWriter else {
                    //                    objc_sync_exit(self)
                    return
                }
                if assetWriter.status != .writing && assetWriter.status != .unknown {
                    //                    objc_sync_exit(self)
                    return
                }
                if assetWriter.inputs.isEmpty {
                    //                    objc_sync_exit(self)
                    return
                }
                
                objc_sync_enter(self)

                if self.didEnd {
                    objc_sync_exit(self)
                    return
                }
                objc_sync_exit(self)
                
                if !self.canWrite && connection == self.videoDataOutput?.connection(with: .video) {
                    print("开始线程：\(Thread.current)")
                    if assetWriter.startWriting() {
                        assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                        self.canWrite = true
                    } else {
                        print("开始失败")
                        print(assetWriter.error?.localizedDescription ?? "")
                        //                        objc_sync_exit(self)
                        return
                    }
                }
            
                if let _ = self.timer {
                    
                } else {
                    DispatchQueue.main.async { [self] in
                        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
                    }
                    
                }
            
            if connection == self.videoDataOutput?.connection(with: .video) {
                if let videoInput = self.assetWriterVideoInput, videoInput.isReadyForMoreMediaData {
                        
                    if videoInput.append(sampleBuffer) {
                        
                    } else {
                        print("视频写入失败")
                        
                    }
                    
                }
            } else if connection == self.audioDataOutput?.connection(with: .audio) {
                    if let audioInput = self.assetWriterAudioInput, audioInput.isReadyForMoreMediaData {
                        if audioInput.append(sampleBuffer) {
                            
                        } else {
                            print("音频写入失败")
                        }
                    }
            }
            }
            //                objc_sync_exit(self)
            
            //            objc_sync_exit(self)
        } else {
            if connection.isVideoStabilizationSupported {
                connection.videoOrientation = .portrait
            }
            
            if takePhoto {
                takePhoto = false
                var orientation = UIImage.Orientation.up
                switch UIDevice.current.orientation {
                case .landscapeLeft:
                    orientation = .left
                    
                case .landscapeRight:
                    orientation = .right
                    
                case .portraitUpsideDown:
                    orientation = .down
                    
                default:
                    orientation = .up
                }
                
                if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer, orientation: orientation) {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        let vc = EyuWorkPhotoCropViewController()
                        vc.originalPhoto = image
                        vc.image = image
                        vc.accessController = self.accessController
                        vc.cameraController = self
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }
            
        }
    }

    
    func getImageFromSampleBuffer(buffer:CMSampleBuffer, orientation: UIImage.Orientation) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let bWidth =  CVPixelBufferGetWidth(pixelBuffer)
            let bHeight =  CVPixelBufferGetHeight(pixelBuffer)
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect) {
//                if let aimage = image.cropping(to: CGRect(x: 0, y: 100, width: aWidth, height: aWidth)) {
                    return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: orientation)
//                }
            }
            
        }
        return nil
    }
    func calculateAspectRatioCrop(cgImage : CGImage, aspectRatio: CGFloat) -> CGRect {
        var width = CGFloat(cgImage.width)
        var height = CGFloat(cgImage.height)
        
        
        
        return CGRect(x: 0, y: 100, width: 375, height: 375)
    }
    
    @objc func updateProgress() {
        if recordTime > 8.0 {
            // 最长录制时间
        }
        
        recordTime = recordTime + 0.05
//        self.timeLabel.text = formateTime(videocurrent: CGFloat(recordTime))
        self.guideButton.setTitle(formateTime(videocurrent: CGFloat(recordTime)), for: .normal)
    }
    
    func formateTime(videocurrent: CGFloat) -> String {
//        [NSString stringWithFormat:@"%02li:%02li",lround(floor(videocurrent/60.f)),lround(floor(videocurrent/1.f))%60];
        return String(format: "%02li:%02li", lround(floor(Double(videocurrent)/60.0)),lround(floor(Double(videocurrent)/1.0))%60)
    }
}
    extension EyuCameraViewController {
        func showAlter(title: String, message: String, action: String, handler: ((UIAlertAction) -> Void)?) {
            //        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: action, style: .default, handler: handler)
            alert.addAction(action)
            
            self.present(alert, animated: true, completion: nil)
            //        }
        }
    }
    
    extension EyuCameraViewController: TZImagePickerControllerDelegate {
        func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
            if photos.isEmpty { return }
            guard let image = photos.first else { return }
            let vc = EyuWorkPhotoCropViewController()
            vc.originalPhoto = image
            vc.image = image
            vc.accessController = self.accessController
            vc.cameraController = self
            self.navigationController?.pushViewController(vc, animated: true)
        }
        func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingVideo coverImage: UIImage!, sourceAssets asset: PHAsset!) {
            getURL(of: asset) { [weak self] (url) in
                if let `url` = url {
                    self?.didSelectVideo?(coverImage, url)
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
        func getURL(of asset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
            if asset.mediaType == .video {
                let options: PHVideoRequestOptions = PHVideoRequestOptions()
                options.version = .original
                PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                    if let urlAsset = asset as? AVURLAsset {
                        let localVideoUrl: URL = urlAsset.url as URL
                        completionHandler(localVideoUrl)
                    } else {
                        completionHandler(nil)
                    }
                })
            }
        }
    }

extension EyuCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,  didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,  previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings:  AVCaptureResolvedPhotoSettings, bracketSettings:   AVCaptureBracketedStillImageSettings?, error: Error?) {
            
            if let error = error {
                print("-----error occure : \(error.localizedDescription)")
            }
            
            if  let sampleBuffer = photoSampleBuffer,
                let previewBuffer = previewPhotoSampleBuffer,
                let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                print(UIImage(data: dataImage)?.size as Any)
                
                let dataProvider = CGDataProvider(data: dataImage as CFData)
                let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImage.Orientation.right)
//
//                self.session.stopRunning()
//                self.imgView.image = image
                let sImage = self.cropImageToSquare(image)
                
                self.imageView.image = sImage
                self.imageView.isHidden = false
                
            } else {
                print("some error here")
            }
        }
    
    
    func cropImageToSquare(_ image: UIImage) -> UIImage {
                let orientation: UIDeviceOrientation = UIDevice.current.orientation
                var imageWidth = image.size.width
                var imageHeight = image.size.height
                switch orientation {
                case .landscapeLeft, .landscapeRight:
                    // Swap width and height if orientation is landscape
                    imageWidth = image.size.height
                    imageHeight = image.size.width
                default:
                    break
                }

                // The center coordinate along Y axis
                let rcy = imageHeight * 0.5
                
                var h = imageWidth *  3 / 4
        
        if self.scale == 1 {
            h = imageWidth
        } else if self.scale > 1 {
            h = imageWidth *  3 / 4
        } else {
            h = imageWidth *  4 / 3
        }
        
        
                let rect = CGRect(x: rcy - h * 0.5, y: 0, width: h, height: imageWidth)
                let imageRef = image.cgImage?.cropping(to: rect)
                return UIImage(cgImage: imageRef!, scale: 1.0, orientation: image.imageOrientation)
            }


    // Used when image is taken from the front camera.
    func flipImage(image: UIImage!) -> UIImage! {
            let imageSize: CGSize = image.size
            UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.rotate(by: CGFloat(Double.pi/2.0))
            ctx.translateBy(x: 0, y: -imageSize.width)
            ctx.scaleBy(x: imageSize.height/imageSize.width, y: imageSize.width/imageSize.height)
            ctx.draw(image.cgImage!, in: CGRect(x: 0.0,
                                                y: 0.0,
                                                width: imageSize.width,
                                                height: imageSize.height))
            let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return newImage
    }
}



class EyuPhotoCropSizeSelectView: UIView {
    private var font = UIFont.systemFont(ofSize: 9, weight: .bold)
    override init(frame: CGRect) {
        super.init(frame: frame)
        if isIPad {
            font = UIFont.systemFont(ofSize: 12, weight: .bold)
        }
        setupViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    var currentItem: EyuPhotoCropSizeSelectViewItem?
    var sizeScaleChange: ((CGFloat) -> ())?
    func setupViews() {
//        self.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button34)
        addSubview(button43)
        addSubview(button1)
        
        var width: CGFloat = 44
        if isIPad {
            width = 80
        }
        
        button34.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.width.equalTo(width)
            make.height.equalTo(44)
        }
        button43.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalTo(button34.snp.right)
            make.width.equalTo(width)
            make.height.equalTo(44)
        }
        button1.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.left.equalTo(button43.snp.right)
            make.width.equalTo(width)
            make.height.equalTo(44)
        }
        
        
        button34.isSelected = true
        currentItem = button34
    }
    lazy var button34: EyuPhotoCropSizeSelectViewItem = {
        let button = EyuPhotoCropSizeSelectViewItem()
        button.setTitle("3:4")
        button.setTitleColor(.black)
        button.titleLabel.font = font
        button.setupScale(0.2)
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(buttonClickAction(_:)))
        button.addGestureRecognizer(tapGest)
        return button
    }()
    lazy var button43: EyuPhotoCropSizeSelectViewItem = {
        let button = EyuPhotoCropSizeSelectViewItem()
        button.setTitle("4:3")
        button.setTitleColor(.black)
        button.titleLabel.font = font
        button.setupScale(1.2)
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(buttonClickAction(_:)))
        button.addGestureRecognizer(tapGest)
        return button
    }()
    lazy var button1: EyuPhotoCropSizeSelectViewItem = {
        let button = EyuPhotoCropSizeSelectViewItem()
        button.setTitle("1:1")
        button.setTitleColor(.black)
        button.titleLabel.font = font
        button.setupScale(1)
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(buttonClickAction(_:)))
        button.addGestureRecognizer(tapGest)
        return button
    }()
    @objc
    private func buttonClickAction(_ gest: UITapGestureRecognizer) {
        guard let button = gest.view as? EyuPhotoCropSizeSelectViewItem else { return }
        currentItem?.isSelected = false
        button.isSelected = true
        currentItem = button
        
        let title = button.titleLabel.text
        if title == "3:4" {
            sizeScaleChange?(CGFloat(3/4.0))
        } else if title == "4:3" {
            sizeScaleChange?(CGFloat(4/3.0))
        } else if title == "1:1" {
            sizeScaleChange?(1.0)
        }
    }
//    override var intrinsicContentSize: CGSize {
//        get {
//            var width: CGFloat = 44 * kRatioWidth
//            if isIPad {
//                width = 80
//            }
//            return CGSize(width: width*3, height: 44)
//        }
//    }
}


class EyuPhotoCropSizeSelectViewItem: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(borderView)
        self.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    func setupScale(_ scale: CGFloat) {
        self.titleLabel.sizeToFit()
        let titleWidth = self.titleLabel.bounds.size.width + 4
        if scale < 1 {
            self.borderView.bounds = CGRect(x: 0, y: 0, width: titleWidth, height: titleWidth*4/3)
        } else if scale > 1 {
            self.borderView.bounds = CGRect(x: 0, y: 0, width: titleWidth, height: titleWidth*3/4)
        } else {
            self.borderView.bounds = CGRect(x: 0, y: 0, width: titleWidth, height: titleWidth)
        }
        var width: CGFloat = 44
        if isIPad {
            width = 80
        }
        
        self.borderView.center = CGPoint(x: width/2.0, y: 22)
    }
    lazy var borderView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.cornerRadius = 1
        view.clipsToBounds = true
        return view
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    func setTitle(_ title: String) {
        self.titleLabel.text = title
    }
    func setTitleColor(_ color: UIColor) {
        self.titleLabel.textColor = color
    }
//    override func setTitle(_ title: String?, for state: UIControlState) {
//        super.setTitle(title, for: state)
//
//        self.titleLabel?.sizeToFit()
//        let titleWidth = (self.titleLabel?.bounds.size.width ?? 16)
//
//        if title == "3:4" {
//            self.borderView().bounds = CGRect(x: 0, y: 0, width: titleWidth, height: titleWidth*4/3)
//        } else if title == "4:3" {
//            self.borderView().bounds = CGRect(x: 0, y: 0, width: titleWidth, height: titleWidth*3/4)
//        } else if title == "1:1" {
//            self.borderView().bounds = CGRect(x: 0, y: 0, width: titleWidth, height: titleWidth)
//        }
//
//        var width: CGFloat = 44 * kRatioWidth
//        if isIPad {
//            width = 80
//        }
//
//        self.borderView().center = CGPoint(x: width/2.0, y: 22)
//    }
    
    var isSelected: Bool = false {
        didSet {
            borderView.layer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.black.cgColor
            self.titleLabel.textColor = isSelected ? UIColor.red : UIColor.black
        }
    }

}
