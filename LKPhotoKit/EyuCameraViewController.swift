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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle("关闭", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(closeController), for: .touchUpInside)
        button.frame = CGRect(x: 16, y: 64, width: 80, height: 36)
        view.addSubview(button)
        
        
        let captureTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AutoFocusGesture(_:)))
        captureTapGesture.numberOfTapsRequired = 1
        captureTapGesture.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(captureTapGesture)
        
        
        setupViews()
        setupPreviewLayer()
        configSession()
        requestAuthorization()
        
        if isVideo {
            //            setupAssetWriter()
        }
    }
    
    func configSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
    }
    func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: captureSession)
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height-167)
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
    }
    private lazy var bottomView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: self.view.frame.size.height-167, width: self.view.frame.size.width, height: 157)
        view.backgroundColor = .white
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
            takePhoto = true
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
            

            
            let compressionProperties: Dictionary<String, Any> = [
                AVVideoAverageBitRateKey: 6.0 * 1280*720,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
            let videoSetting: Dictionary<String, Any> = [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
                AVVideoWidthKey: 1280*2,
                AVVideoHeightKey: 720*2,
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
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: orientation)
                
            }
            
        }
        return nil
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

