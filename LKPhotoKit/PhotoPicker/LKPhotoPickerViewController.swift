//
//  LKPhotoPickerViewController.swift
//  Like
//
//  Created by xiusl on 2019/11/22.
//  Copyright © 2019 likeeee. All rights reserved.
//

import UIKit
import PhotosUI
import Photos


protocol LKPhotoPickerViewControllerDelegate {
    func photoPickerViewController(controller: LKPhotoPickerViewController, selectPhotos: Array<LKAsset>)
    func photoPickerViewController(controller: LKPhotoPickerViewController, selectAssets: Array<LKAsset>, selectPhotos: Array<UIImage>)
    func photoPickerViewController(controller: LKPhotoPickerViewController, cropImage: UIImage)
}

class LKPhotoPickerViewController: UINavigationController {

    var lk_delegate: LKPhotoPickerViewControllerDelegate?
    
    open var maxCount: Int = 9
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    private override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(withOldImage: Array<PHAsset>) {
        let vc = LKPhotoPickerRootViewController()
        vc.maxCount = self.maxCount
        super.init(rootViewController: vc)
    }
    init(originalPhoto: Bool, maxCount: Int = 9) {
        let vc = LKPhotoPickerRootViewController()
        vc.maxCount = maxCount
        super.init(rootViewController: vc)
    }
    init(originalPhoto: Bool, needCrop: Bool) {
        let vc = LKPhotoPickerRootViewController()
        vc.maxCount = 1
        vc.needCrop = true
        super.init(rootViewController: vc)
    }
    
}
class LKPhotoPickerRootViewController: UIViewController {

    var needCrop: Bool = false
    var maxCount: Int = 9
    var currentAlbum: LKAlbum = LKAlbum()
    var albums: Array<LKAlbum> = []
    var selectAssets: Array<LKAsset> = []
    
    weak var navVc: LKPhotoPickerViewController?
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navVc = self.navigationController as? LKPhotoPickerViewController
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    debugPrint("access")
                    DispatchQueue.main.async {
                        self.gerateData()
                    }
                } else {
                    debugPrint("not access")
                }
            }
        } else {
            self.gerateData()
        }
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.barView)
        self.barView.addSubview(self.finishButton)
//        self.barView.addSubview(self.previewButton)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(dismissClick))
        self.navigationItem.titleView = self.titleButton
    }
    @objc func dismissClick() {
        self.dismiss(animated: true, completion: nil)
    }
    func gerateData() {
        let opt = PHFetchOptions()
        opt.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        opt.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let opt1 = PHFetchOptions()
        opt1.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: false)]
        
        let smartAlbums :PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: opt1)
        
        var arr: Array<LKAlbum> = []
        smartAlbums.enumerateObjects { (collection, idx, stop)  in
            if !collection.isKind(of: PHAssetCollection.self) { return }
            if collection.estimatedAssetCount <= 0 { return }
            debugPrint(collection.localizedTitle ?? "")
            debugPrint(collection.estimatedAssetCount)
            
            let fetchResult: PHFetchResult = PHAsset.fetchAssets(in: collection, options: opt)
            
            print(fetchResult.count)
            if fetchResult.count <= 0 { return }
            
            let album = LKAlbum.create(withCollection: collection, assetResult: fetchResult)
            if (collection.assetCollectionSubtype == .smartAlbumUserLibrary) {
                arr.insert(album, at: 0)
            } else if (collection.assetCollectionSubtype.rawValue == 1000000201) {
                
            } else {
                arr.append(album)
            }
        }
        self.albums = arr
        self.currentAlbum = arr[0]
        self.collectionView.reloadData()
//        self.title = self.currentAlbum.name
        self.titleButton.setTitle(self.currentAlbum.name, for: .normal)
        self.titleButton.sizeToFit()
        self.fixButton(self.titleButton)
        self.tableView.reloadData()
    }
    
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let w = (self.view.frame.size.width - 6) / 4
        layout.itemSize = CGSize(width: w, height: w)
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        
//        collectionView.register(UICollectionViewCell.Type, forCellWithReuseIdentifier: "abc123")
        collectionView.register(LKPhotoViewCell.self, forCellWithReuseIdentifier: "abc123")
        
        return collectionView
    }()

    
    lazy var tableView: UITableView = {
        let h = self.view.frame.size.height
        let frame = CGRect(x: 0, y: -h, width: self.view.frame.size.width, height: h)
        let tableView = UITableView(frame: frame)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    lazy var titleButton: UIButton = {
        let titleButton = UIButton()
        titleButton.setTitleColor(.black, for: .normal)
        titleButton.setTitleColor(.theme, for: .selected)
        titleButton.addTarget(self, action: #selector(titleButtonClick(_:)), for: .touchUpInside)
        titleButton.setImage(Bundle.lk_topArrowImage(), for: .normal)
        return titleButton
    }()
    
    func fixButton(_ button: UIButton) {
        let m: CGFloat = 2.0
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0 - ( button.imageView?.bounds.size.width ?? 0) - m, bottom: 0, right: ( button.imageView?.bounds.size.width ?? 0) + m);
        button.imageEdgeInsets = UIEdgeInsets(top: 2, left: (button.titleLabel?.bounds.size.width ?? 0) + m, bottom: -2, right: 0 - (button.titleLabel?.bounds.size.width ?? 0) - m);
    }
    
    @objc func titleButtonClick(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        
        UIView.animate(withDuration: 0.2) {
            if btn.isSelected {
                let h = self.view.frame.size.height
                self.tableView.transform = CGAffineTransform(translationX: 0, y: h)
                btn.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            } else {
                self.tableView.transform = CGAffineTransform.identity
                btn.imageView?.transform = .identity
            }
        }
    }
    
    lazy var barView: UIView = {
        let barView = UIView()
        var h: CGFloat = 48
        if UIApplication.shared.statusBarFrame.size.height > 20 {
            h += 30
        }
        let w = self.view.bounds.size.width
        let top = self.view.bounds.size.height - h
        barView.frame = CGRect(x: 0, y: top, width: w, height: h)
        barView.backgroundColor = .white
        
        let line = UIImageView()
        line.frame = CGRect(x: 0, y: 0, width: w, height: 1)
        line.backgroundColor = UIColor(hex: 0xDDE4E6)
        barView.addSubview(line)
        
        return barView
    }()
    
    lazy var finishButton: UIButton = {
        let finishButton = UIButton()
        let w = self.view.bounds.size.width
        finishButton.frame = CGRect(x: w-64-16, y: 6, width: 64, height: 36)
        finishButton.backgroundColor = .theme
        finishButton.setTitle("完成", for: .normal)
        finishButton.layer.cornerRadius = 4
        finishButton.clipsToBounds = true
        finishButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        finishButton.addTarget(self, action: #selector(finishButtonClick), for: .touchUpInside)
        return finishButton
    }()

    lazy var previewButton: UIButton = {
        let previewButton = UIButton()
        previewButton.frame = CGRect(x: 16, y: 6, width: 64, height: 36)
        previewButton.setTitle("预览", for: .normal)
        previewButton.setTitleColor(.blackText, for: .normal)
        previewButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return previewButton
    }()
    
    @objc func finishButtonClick() {
        let photos = self.fetchImages()
        self.navVc?.lk_delegate?.photoPickerViewController(controller: self.navVc!, selectAssets: self.selectAssets, selectPhotos: photos)
        self.navVc?.dismiss(animated: true, completion: nil)
    }
    
    func fetchImages() -> Array<UIImage> {
        var photos: Array<UIImage> = []
        for _ in 0..<self.selectAssets.count {
            photos.append(UIImage())
        }
        
        for i in 0..<self.selectAssets.count {
            let asset = self.selectAssets[i]
            
            let opt: PHImageRequestOptions = PHImageRequestOptions()
            opt.isNetworkAccessAllowed = true
            opt.isSynchronous = true
            let _ = PHImageManager.default().requestImage(for: asset.asset!, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: opt) { (image, _) in
                photos[i] = image ?? UIImage()
            }
        }
        return photos
    }
}
extension LKPhotoPickerRootViewController: UICollectionViewDataSource, UICollectionViewDelegate, LKPhotoViewCellDelegate, LKPhotoPickerPreviewViewControllerDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentAlbum.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "abc123", for: indexPath) as! LKPhotoViewCell
        
        cell.setup(asset: self.currentAlbum.models[indexPath.row])
        
        cell.delegate = self
        
        let mdo = self.currentAlbum.models[indexPath.row]
        if self.containAsset(asset: mdo) {
            let reIdx = self.indexAsset(asset: mdo)
            let t = String(format: "%d", reIdx+1)
            cell.indexLabel.text = t
            cell.selectButton.isSelected = true
            cell.setupSelected(selected: true)
        } else {
            cell.indexLabel.text = ""
            cell.selectButton.isSelected = false
            cell.setupSelected(selected: false)
        }
        
        cell.selectButton.isHidden = self.needCrop
        cell.indexLabel.isHidden = self.needCrop
        cell.selectView.isHidden = self.needCrop
        
        return cell
    }
    
    func photoViewCell(cell: LKPhotoViewCell, selectButton: UIButton) {
        let idx = self.collectionView.indexPath(for: cell)!
        let mdo = self.currentAlbum.models[idx.row]
        
        if selectButton.isSelected {
            if self.selectAssets.count >= self.maxCount {
                selectButton.isSelected = false
                cell.setupSelected(selected: false)
                print("目前只支持一张图片")
                return
            }
            
            if !self.containAsset(asset: mdo) {
                self.selectAssets.append(mdo)
            }
        
            let reIdx = self.indexAsset(asset: mdo)
            let t = String(format: "%d", reIdx+1)
            cell.indexLabel.text = t
            
        } else {
            
            if self.containAsset(asset: mdo) {
                let reIdx = self.indexAsset(asset: mdo)
                self.selectAssets.remove(at: reIdx)
                
            }
            cell.indexLabel.text = ""
        }
        NotificationCenter.default.post(name: NSNotification.Name("LKPhotoCellReload_noti"), object: self.selectAssets)
        var title = "完成"
        if self.selectAssets.count > 0 {
            title = String(format: "完成(%d)", self.selectAssets.count)
        }
        self.finishButton.setTitle(title, for: .normal)
    }
        
    func containAsset(asset: LKAsset) -> Bool {
        for old_asset in self.selectAssets {
            if old_asset.asset?.localIdentifier == asset.asset?.localIdentifier {
                return true
            }
        }
        return false
    }
    func indexAsset(asset: LKAsset) -> Int {
        var i = 0
        for old_asset in self.selectAssets {
            if old_asset.asset?.localIdentifier == asset.asset?.localIdentifier {
                return i
            }
            i += 1
        }
        return i
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if needCrop {
            let assert = self.currentAlbum.models[indexPath.row];
            
            let opt: PHImageRequestOptions = PHImageRequestOptions()
            opt.resizeMode = .fast
            opt.isNetworkAccessAllowed = true
            opt.isSynchronous = true
            let _ = PHImageManager.default().requestImage(for: assert.asset!, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: opt) { (image, _) in
                
                let vc = LKPhotoCropViewController()
                vc.image = image
                self.navigationController?.pushViewController(vc, animated: true)
                
                vc.didFinishCropping = { cropImage in
                    self.navVc?.lk_delegate?.photoPickerViewController(controller: self.navVc!, cropImage: cropImage)
                    self.navVc?.dismiss(animated: true, completion: nil)
                }
            }
            
            return
        }
        let vc = LKPhotoPickerPreviewViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.assets = self.currentAlbum.models
        vc.selectAssets = self.selectAssets
        vc.currentIndex = indexPath.row
        vc.delegate = self
        vc.maxCount = self.maxCount
        self.present(vc, animated: true, completion: nil)
    }
    
    func previewViewController(cancleClick selectAssets: Array<LKAsset>) {
        self.selectAssets = selectAssets
        self.collectionView.reloadData()
    }
    
    func previewViewController(finishClick selectAssets: Array<LKAsset>) {
        self.selectAssets = selectAssets
        let photos = self.fetchImages()
        self.navVc?.lk_delegate?.photoPickerViewController(controller: self.navVc!, selectAssets: self.selectAssets, selectPhotos: photos)
    }
}

extension LKPhotoPickerRootViewController: UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "UITableViewCell")
        }
        
        let album = self.albums[indexPath.row]
        
        cell?.textLabel?.text = album.name
        
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentAlbum = self.albums[indexPath.row]
        self.collectionView.reloadData()
        
        UIView.animate(withDuration: 0.2) {
            self.tableView.transform = .identity
            self.titleButton.imageView?.transform = .identity
        }
        
        self.titleButton.setTitle(self.currentAlbum.name, for: .normal)
        self.titleButton.isSelected = false
        self.titleButton.sizeToFit()
        self.fixButton(self.titleButton)
    }
}


protocol LKPhotoPickerPreviewViewControllerDelegate {
    func previewViewController(cancleClick selectAssets: Array<LKAsset>)
    func previewViewController(finishClick selectAssets: Array<LKAsset>)
}
class LKPhotoPickerPreviewViewController: UIViewController {
    open var maxCount: Int = 9
    var assets: Array<LKAsset> = []
    var selectAssets: Array<LKAsset> = []
    var currentIndex: Int = 0
    
    var delegate: LKPhotoPickerPreviewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.barView)
        self.barView.addSubview(self.finishButton)
        
        let t = UIApplication.shared.statusBarFrame.size.height
        let btn = UIButton.init(type: .custom)
        btn.frame = CGRect(x: 0, y: t+2, width: 64, height: 40)
        btn.setTitle("取消", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(dismissClick), for: .touchUpInside)
        self.view.addSubview(btn)
        self.view.addSubview(self.titleLabel)
        
        
        self.titleLabel.text = String(format: "%zd/%zd", self.currentIndex+1, self.assets.count)
        self.collectionView.scrollToItem(at: IndexPath(row: self.currentIndex, section: 0), at: .left, animated: false)
        
        self.view.addSubview(self.selectButton)
        
        
        let mod = self.assets[self.currentIndex]
        if self.containAsset(asset: mod) {
            self.selectButton.isSelected = true
            let idx = self.indexAsset(asset: mod)
            self.selectButton.setTitle(String(format: "%d", idx+1), for: .normal)
        } else {
            self.selectButton.isSelected = false
            self.selectButton.setTitle("", for: .normal)
        }
    }
    
    @objc func dismissClick() {
        self.delegate?.previewViewController(cancleClick: self.selectAssets)
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        let w = self.view.frame.size.width
        let t = UIApplication.shared.statusBarFrame.size.height
        titleLabel.frame = CGRect(x: 100, y: t, width: w-200, height: 44)
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        return titleLabel
    }()
    
    lazy var selectButton: UIButton = {
        let selectButton = UIButton()
        let w = self.view.frame.size.width
        let t = UIApplication.shared.statusBarFrame.size.height
        selectButton.frame = CGRect(x: w-20-16, y: t+12, width: 20, height: 20)
        selectButton.setBackgroundImage(UIImage(named: "photo_picker_nor"), for: .normal)
        selectButton.setBackgroundImage(UIImage(named: "photo_picker_sel"), for: .selected)
        selectButton.addTarget(self, action: #selector(selectButtonClick(_:)), for: .touchUpInside)
        selectButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        return selectButton
    }()
    
    @objc func selectButtonClick(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        
        if btn.isSelected && self.selectAssets.count >= self.maxCount {
            btn.isSelected = false
            print("目前只支持一张图片")
            return
        }
        let mod = self.assets[self.currentIndex]
        if !self.containAsset(asset: mod) {
            self.selectAssets.append(mod)
            let idx = self.indexAsset(asset: mod)
            self.selectButton.setTitle(String(format: "%d", idx+1), for: .normal)
        } else {
            let idx = self.indexAsset(asset: mod)
            self.selectAssets.remove(at: idx)
            self.selectButton.isSelected = false
            self.selectButton.setTitle("", for: .normal)
        }
    }
    
    lazy var collectionView: UICollectionView = {
        
        
        let top = UIApplication.shared.statusBarFrame.size.height + 44
        var bottom: CGFloat = 48
        if UIApplication.shared.statusBarFrame.size.height > 20 {
            bottom += 20
        }
        let w = self.view.frame.size.width
        let h = self.view.frame.size.height
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: w, height: h-top-bottom)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        
        let frame = CGRect(x: 0, y: top,
                           width: self.view.frame.size.width,
                           height: self.view.frame.size.height-top-bottom)
        let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(LKPhotoPreviewViewCell.self, forCellWithReuseIdentifier: "LKPhotoPreviewViewCellID")
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    lazy var barView: UIView = {
        let barView = UIView()
        var h: CGFloat = 48
        if UIApplication.shared.statusBarFrame.size.height > 20 {
            h += 20
        }
        let w = self.view.bounds.size.width
        let top = self.view.bounds.size.height - h
        barView.frame = CGRect(x: 0, y: top, width: w, height: h)
        barView.backgroundColor = .white
        
        let line = UIImageView()
        line.frame = CGRect(x: 0, y: 0, width: w, height: 1)
        line.backgroundColor = UIColor(hex: 0xDDE4E6)
        barView.addSubview(line)
        
        return barView
    }()
    
    lazy var finishButton: UIButton = {
        let finishButton = UIButton()
        let w = self.view.bounds.size.width
        finishButton.frame = CGRect(x: w-64-16, y: 6, width: 64, height: 36)
        finishButton.backgroundColor = .theme
        finishButton.setTitle("完成", for: .normal)
        finishButton.layer.cornerRadius = 4
        finishButton.clipsToBounds = true
        finishButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        finishButton.addTarget(self, action: #selector(finishButtonClick), for: .touchUpInside)
        return finishButton
    }()
    
    @objc func finishButtonClick() {
        self.delegate?.previewViewController(finishClick: self.selectAssets)
//        self.dismiss(animated: false, completion: nil)
        let vc = self.presentingViewController
        
        self.dismiss(animated: false) {
            vc?.dismiss(animated: true, completion: {
                
            })
        }
    }
}

extension LKPhotoPickerPreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LKPhotoPreviewViewCellID", for: indexPath) as! LKPhotoPreviewViewCell
        
        let mod = self.assets[indexPath.row]
        cell.setup(asset: mod)
        return cell
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        self.currentIndex = Int(x / scrollView.frame.size.width)
        self.titleLabel.text = String(format: "%zd/%zd", self.currentIndex+1, self.assets.count)
        
        let mod = self.assets[self.currentIndex]
        if self.containAsset(asset: mod) {
            self.selectButton.isSelected = true
            let idx = self.indexAsset(asset: mod)
            self.selectButton.setTitle(String(format: "%d", idx+1), for: .normal)
        } else {
            self.selectButton.isSelected = false
            self.selectButton.setTitle("", for: .normal)
        }
        
    }
    
    func containAsset(asset: LKAsset) -> Bool {
           for old_asset in self.selectAssets {
               if old_asset.asset?.localIdentifier == asset.asset?.localIdentifier {
                   return true
               }
           }
           return false
       }
       func indexAsset(asset: LKAsset) -> Int {
           var i = 0
           for old_asset in self.selectAssets {
               if old_asset.asset?.localIdentifier == asset.asset?.localIdentifier {
                   return i
               }
               i += 1
           }
           return i
       }
}
