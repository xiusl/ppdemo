//
//  LKPhotoPreviewViewCell.swift
//  Like
//
//  Created by xiusl on 2019/11/25.
//  Copyright © 2019 likeeee. All rights reserved.
//

import UIKit
import Photos

class LKPhotoPreviewViewCell: UICollectionViewCell {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.scrollView)
        self.scrollView.addSubview(self.imageView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = self.bounds
        return imageView
    }()
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.frame = self.bounds
        scrollView.contentSize = self.bounds.size
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        return scrollView
    }()
    
    func setup(asset: LKAsset) {
        guard let mod = asset.asset else { return }
        

        let w = self.bounds.size.width
        let h = self.bounds.size.height
        
        let photoWidth = self.imageView.frame.size.width
        var size = PHImageManagerMaximumSize
        
        let phAsset = mod
        let aspectRatio =  CGFloat(phAsset.pixelWidth) / CGFloat(phAsset.pixelHeight)
        let pixelWidth = photoWidth

        let pixelHeight = pixelWidth / aspectRatio
        size = CGSize(width: pixelWidth, height: pixelHeight)
        
        var t = (h - pixelHeight) / 2.0
        if pixelHeight > h {
            t = 0
        }
        
        self.imageView.frame = CGRect(x: 0, y: t, width: w, height: pixelHeight)
        self.scrollView.contentSize = self.imageView.bounds.size;
        
        let opt: PHImageRequestOptions = PHImageRequestOptions()
        opt.resizeMode = .fast
        opt.isNetworkAccessAllowed = true
        let _ = PHImageManager.default().requestImage(for: mod, targetSize: size, contentMode: .default, options: opt) { (image, _) in
            self.imageView.image = image
        }
    }
    
}
