//
//  WorkUploadViewController.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/29.
//

import UIKit
import SnapKit

class WorkUploadViewController: UIViewController {

    var image: UIImage?
    var originalImage: UIImage?
    var cropController: UIViewController?
    var accessController: UIViewController?
    var cameraController: UIViewController?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        setupViews()
        setupData()
        
        let navBackItem = UIBarButtonItem(title: "返回", style: .plain, target: self, action: #selector(navBackItemAction))
        self.navigationItem.leftBarButtonItem = navBackItem
    }
    
    @objc
    private func navBackItemAction() {
        let sheetView = EyuAlterSheetView()
        let sheetAction = EyuAlterSheetAction(title: "编辑照片") { [weak self] (action) in
            self?.backCropImageViewController()
        }
        let sheetAction1 = EyuAlterSheetAction(title: "退出发作品") { [weak self] (action) in
            guard let `self` = self else {return}
            self.navigationController?.popToViewController(self.accessController!, animated: true)
        }
        sheetView.addAction(sheetAction)
        sheetView.addAction(sheetAction1)
        sheetView.show()
    }
    private func backCropImageViewController() {
        if let vc = self.cropController as? EyuWorkPhotoCropViewController {
            if let originalIm = self.originalImage {
                vc.setupImage(originalIm)
            }
        }
        self.navigationController?.popToViewController(self.cropController!, animated: true)
    }
    private func backCameraViewController() {
        self.navigationController?.popToViewController(self.cameraController!, animated: true)
    }
    func setupData() {
        guard let im = self.image else { return }
        coverImageView.setupImage(im)
    }
    
    private func setupViews() {
        let navH = UIApplication.shared.statusBarFrame.size.height+44
        view.addSubview(titleLabel)
        titleLabel.frame = CGRect(x: isIPad ? 24 : 16, y: navH+20, width: 100, height: 36)
        view.addSubview(coverImageView)
        let imageW: CGFloat = isIPad ? 160 : 83
        coverImageView.frame = CGRect(x: isIPad ? 24 : 16, y: navH+72, width: imageW, height: imageW)
        view.addSubview(videoButton)
        videoButton.frame = CGRect(x: isIPad ? 24 : 16, y: navH+72+imageW+20, width: 90, height: 90)
        view.addSubview(coverVideoView)
        coverVideoView.frame = CGRect(x: (isIPad ? 24 : 16) + imageW + 12, y: navH+72, width: imageW, height: imageW)
        
        coverImageView.deleteHandler = {[weak self] in
            self?.deleteImageConfirm()
        }
    }
    func deleteImageConfirm() {
        let sheetView = EyuAlterSheetView()
        let sheetAction = EyuAlterSheetAction(title: "编辑照片") { [weak self] (action) in
            self?.backCropImageViewController()
        }
        let sheetAction1 = EyuAlterSheetAction(title: "删除照片") { [weak self] (action) in
            self?.backCameraViewController()
        }
        sheetView.addAction(sheetAction)
        sheetView.addAction(sheetAction1)
        sheetView.show()
    }
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "发作品"
        label.font = .systemFont(ofSize: 26, weight: .medium)
        label.textColor = UIColor(red: 26/255.0, green: 27/255.0, blue: 30/255.0, alpha: 1)
        return label
    }()
    private lazy var coverImageView: WorkCoverImageView = {
        return WorkCoverImageView()
    }()
    private lazy var coverVideoView: WorkCoverVideoView = {
        return WorkCoverVideoView()
    }()
    private lazy var videoButton: UIButton = {
        let button = UIButton()
        button.setTitle("拍视频", for: .normal)
        button.setTitleColor(.green, for: .normal)
        button.addTarget(self, action: #selector(videoButtonAction), for: .touchUpInside)
        return button
    }()
    
    @objc
    private func videoButtonAction() {
        let vc = EyuCameraViewController()
        vc.isVideo = true
        self.navigationController?.pushViewController(vc, animated: true)
        
        vc.didSelectVideo = { [weak self] (coverImage, asset) in
            self?.coverVideoView.setupBgImage(coverImage)
        }
    }
}

class WorkCoverImageView: UIView {
    var deleteHandler: (() -> ())?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    func setupImage(_ image: UIImage) {
        imageView.image = image
    }
    func setupBgImage(_ image: UIImage) {
        bgView.image = image
    }
    private func setupViews() {
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        
        addSubview(bgView)
        addSubview(imageView)
        addSubview(deleteButton)
        imageView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(6)
            make.right.bottom.equalToSuperview().offset(-6)
        }
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        deleteButton.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.size.equalTo(24)
        }
    }
    @objc
    private func deleteButtonAction() {
        deleteHandler?()
    }
    private lazy var bgView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor(red: 241/255.0, green: 241/255.0, blue: 245/255.0, alpha: 1)
        return view
    }()
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "work_delete"), for: .normal)
        button.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
        return button
    }()
}
class WorkCoverVideoView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    func setupImage(_ image: UIImage) {
        imageView.image = image
    }
    func setupBgImage(_ image: UIImage) {
        bgView.image = image
    }
    private func setupViews() {
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
        
        addSubview(bgView)
        addSubview(imageView)
        
        imageView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(6)
            make.right.bottom.equalToSuperview().offset(-6)
        }
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    private lazy var bgView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor(red: 241/255.0, green: 241/255.0, blue: 245/255.0, alpha: 1)
        view.contentMode = .scaleAspectFit
        return view
    }()
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
}
