//
//  LKPhotoCropView.swift
//  Like
//
//  Created by tmt on 2020/5/9.
//  Copyright © 2020 likeeee. All rights reserved.
//

import UIKit

class LKPhotoCropView: UIView {

    let imageView = UIImageView()
    let cropArea = UIView()
    
    convenience init(image: UIImage, frame: CGRect) {
        self.init(frame: frame)
        addSubview(imageView)
        addSubview(cropArea)
        addSubview(topView)
        addSubview(leftView)
        addSubview(bottomView)
        addSubview(rightView)
        imageView.image = image
        setupLayout(with: image)
        applyStyle()
    }
    
    func setupImage(_ image: UIImage) {
        imageView.image = image
        setupLayout(with: image)
    }

    private func setupLayout(with image: UIImage) {
        
        let imageRatio: Double = Double(image.size.width / image.size.height)
        
        let viewH = self.frame.size.height
        let viewW = self.frame.size.width
        let center = CGPoint(x: viewW*0.5, y: viewH*0.5)
        if imageRatio < 1 { // 长图
            let w: CGFloat = 300//self.frame.size.width - 32
            let h: CGFloat = 400
            cropArea.bounds = CGRect(x: 0, y: 0, width: w, height: h)
            cropArea.center = center//self.center
            
            
            let scaledDownRatio = w / image.size.width
            imageView.frame.size.width = image.size.width * scaledDownRatio
            
            imageView.frame.size.height = imageView.frame.size.width / CGFloat(imageRatio)
            
            setupMaskView(viewW: viewW, viewH: viewH, w: w, h: h)
        } else if imageRatio > 1 { // 宽图
            let w: CGFloat = 300//self.frame.size.width - 32
            let h: CGFloat = 300 * 3 / 4
            cropArea.bounds = CGRect(x: 0, y: 0, width: w, height: h)
            cropArea.center = center//self.center
            
            
            imageView.frame.size.height = h
            imageView.frame.size.width = imageView.frame.size.height * CGFloat(imageRatio)
            setupMaskView(viewW: viewW, viewH: viewH, w: w, h: h)
        } else {
            
            let w: CGFloat = 300//self.frame.size.width - 32
            let h: CGFloat = 300
            cropArea.bounds = CGRect(x: 0, y: 0, width: w, height: h)
            cropArea.center = center//self.center
            
            imageView.frame.size = cropArea.frame.size
            setupMaskView(viewW: viewW, viewH: viewH, w: w, h: h)
        }
        
        imageView.center = center//self.center
    }
    
    private func setupMaskView(viewW: CGFloat, viewH: CGFloat, w: CGFloat, h: CGFloat) {
        leftView.frame = CGRect(x: 0, y: 0, width: (viewW-w)*0.5, height: viewH)
        topView.frame = CGRect(x: (viewW-w)*0.5, y: 0, width: w, height: (viewH-h)*0.5)
        rightView.frame = CGRect(x: viewW-(viewW-w)*0.5, y: 0, width: (viewW-w)*0.5, height: viewH)
        bottomView.frame = CGRect(x: (viewW-w)*0.5, y: viewH-(viewH-h)*0.5, width: w, height: (viewH-h)*0.5)
    }
    
    private func applyStyle() {
        clipsToBounds = true
        
        imageView.isUserInteractionEnabled = true
        imageView.isMultipleTouchEnabled = true
        
        cropArea.backgroundColor = .clear
        cropArea.isUserInteractionEnabled = false
        cropArea.layer.borderWidth = 1
        cropArea.layer.borderColor = UIColor.white.cgColor
    }
    
    private lazy var topView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        return view
    }()
    private lazy var leftView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        return view
    }()
    private lazy var bottomView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        return view
    }()
    private lazy var rightView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 0.5)
        return view
    }()
}
