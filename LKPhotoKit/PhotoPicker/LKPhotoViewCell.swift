//
//  LKPhotoViewCell.swift
//  Like
//
//  Created by xiusl on 2019/11/22.
//  Copyright © 2019 likeeee. All rights reserved.
//

import UIKit
import Photos

protocol LKPhotoViewCellDelegate {
    func photoViewCell(cell: LKPhotoViewCell, selectButton: UIButton)
}

class LKPhotoViewCell: UICollectionViewCell {
    var delegate: LKPhotoViewCellDelegate?
    var asset: LKAsset?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.selectButton)
        self.contentView.addSubview(self.selectView)
        self.contentView.addSubview(self.indexLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload(_:)), name: Notification.Name("LKPhotoCellReload_noti"), object: nil)
    }
    
    @objc func reload(_ noti: Notification) {
        let sets = noti.object as! Array<LKAsset>
        
        
        let index = self.indexAsset(assets: sets)
        if index == -1 {
            self.indexLabel.text = ""
        } else {
            self.indexLabel.text = String(format: "%d", index+1)
        }
    }
    
    func indexAsset(assets: Array<LKAsset>) -> Int {
        guard let asset = self.asset else {
            return -1
        }
        for (i, old_asset) in assets.enumerated() {
            if old_asset.asset?.localIdentifier == asset.asset?.localIdentifier {
                return i
            }
        }
        return -1
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    func setup(asset: LKAsset) {
        self.asset = asset
        guard let mod = asset.asset else { return }
        let phAsset = mod
        let photoWidth = self.imageView.frame.size.width
        var size = PHImageManagerMaximumSize
        if phAsset.pixelWidth < 400 {
            size = CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight)
        } else {
            
            let aspectRatio =  CGFloat(phAsset.pixelWidth) / CGFloat(phAsset.pixelHeight)
            var pixelWidth = photoWidth * 2
            if aspectRatio > 1.8 { // 宽图
                pixelWidth = pixelWidth * aspectRatio
            }
            if aspectRatio < 0.2 {
                pixelWidth = pixelWidth * 0.5
            }
            let pixelHeight = pixelWidth / aspectRatio
            size = CGSize(width: pixelWidth, height: pixelHeight)
        }
        
        
        let opt: PHImageRequestOptions = PHImageRequestOptions()
        opt.resizeMode = .fast
        opt.isNetworkAccessAllowed = true
        let _ = PHImageManager.default().requestImage(for: mod, targetSize: size, contentMode: .default, options: opt) { (image, _) in
            self.imageView.image = image
        }
    }
    
    lazy var selectButton: UIButton = {
        let selectButton = UIButton()
        let w = self.contentView.frame.size.width
        selectButton.frame = CGRect(x: w-40, y: 0, width: 40, height: 40)
//        selectButton.setBackgroundImage(UIImage(named: "photo_picker_nor"), for: .normal)
//        selectButton.setBackgroundImage(UIImage(named: "photo_picker_sel"), for: .selected)
        selectButton.addTarget(self, action: #selector(selectButtonClick(_:)), for: .touchUpInside)
//        selectButton.titleLabel?.font = UIFont.systemFontMedium(ofSize: 12)
        return selectButton
    }()
    
    lazy var selectView: UIImageView = {
        let selectView = UIImageView()
        let w = self.contentView.frame.size.width
        selectView.frame = CGRect(x: w-30, y: 10, width: 20, height: 20)
        selectView.image = Bundle.lk_indexBgNormalImage()//UIImage(named: "photo_picker_nor")
        return selectView
    }()
    
    func setupSelected(selected: Bool) {
        self.selectView.image = selected ? Bundle.lk_indexBgSelectImage() : Bundle.lk_indexBgNormalImage()//UIImage(named: selected ? "photo_picker_sel" : "photo_picker_nor")
    }
    
    lazy var indexLabel: UILabel = {
        let indexLabel = UILabel()
        let w = self.contentView.frame.size.width
        indexLabel.frame = CGRect(x: w-30, y: 10, width: 20, height: 20)
        indexLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        indexLabel.textColor = .white
        indexLabel.textAlignment = .center
        return indexLabel
    }()
    
    @objc func selectButtonClick(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        self.setupSelected(selected: btn.isSelected)
        self.delegate?.photoViewCell(cell: self, selectButton: btn)
    }
}
