//
//  EyuWorkPhotoEidtBottomView.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/22.
//

import UIKit

class EyuWorkPhotoEidtBottomView: UIView {
    var lightValueChange: ((_ value: Int) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupViews() {
        addSubview(bgButton)
        addSubview(lightButton)
        addSubview(lightProgressView)
        addSubview(backgroundTemplateView)
        
        lightProgressView.valueChange = lightValueChange
    }

    func setup(lightValueChange: ((_ value: Int) -> Void)?) {
        lightProgressView.valueChange = lightValueChange
    }
    
    var currnetButton: UIButton?
    lazy var bgButton: UIButton = {
        let button = UIButton()
        button.setTitle("背景", for: .normal)
        button.setTitleColor(UIColor(red: 47/255.0, green: 47/255.0, blue: 47/255.0, alpha: 1), for: .normal)
        button.setTitleColor(UIColor(red: 65/255.0, green: 200/255.0, blue: 144/255.0, alpha: 1), for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(bgButtonAction), for: .touchUpInside)
        button.frame = CGRect(x: self.frame.size.width*0.5-80-20, y: 60, width: 80, height: 40)
        button.isSelected = true
        currnetButton = button
        return button
    }()
    
    lazy var lightButton: UIButton = {
        let button = UIButton()
        button.setTitle("亮度", for: .normal)
        button.setTitleColor(UIColor(red: 47/255.0, green: 47/255.0, blue: 47/255.0, alpha: 1), for: .normal)
        button.setTitleColor(UIColor(red: 65/255.0, green: 200/255.0, blue: 144/255.0, alpha: 1), for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(lightButtonAction), for: .touchUpInside)
        button.frame = CGRect(x: self.frame.size.width*0.5+20, y: 60, width: 80, height: 40)
        return button
    }()
    
    @objc
    private func bgButtonAction() {
        if currnetButton == bgButton { return }
        currnetButton?.isSelected = false
        bgButton.isSelected = true
        currnetButton = bgButton
        lightProgressView.isHidden = true
        backgroundTemplateView.isHidden = false
    }
    @objc
    private func lightButtonAction() {
        if currnetButton == lightButton { return }
        currnetButton?.isSelected = false
        lightButton.isSelected = true
        currnetButton = lightButton
        lightProgressView.isHidden = false
        backgroundTemplateView.isHidden = true
    }
    
    lazy var lightProgressView: LightProgressControl = {
        let view = LightProgressControl(frame: CGRect(x: (self.frame.size.width-280)*0.5, y: 0, width: 280, height: 60))
        view.isHidden = true
        return view
    }()
    lazy var backgroundTemplateView: WorkBackgrounTemplateView = {
        let view = WorkBackgrounTemplateView(frame: CGRect(x: 10, y: 0, width: self.frame.size.width-20, height: 60))
        return view
    }()
}

class LightProgressControl: UIView {
    
    var valueChange: ((_ value: Int) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bgView)
        addSubview(button)
        addSubview(label)
        
        bgView.frame = CGRect(x: 9, y: (frame.size.height-2)*0.5, width: frame.size.width-18, height: 2)
//        button.bounds = CGRect(x: 0, y: 0, width: 38, height: 38)
        button.frame = CGRect(x: (frame.size.width - 28) * 0.5, y: (frame.size.height-28)*0.5, width: 28, height: 28)
        label.frame = CGRect(x: (frame.size.width - 60) * 0.5, y: 5, width: 60, height: 16)
        label.text = "50"
        
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 202/255.0, green: 230/255.0, blue: 207/255.0, alpha: 1)
        return view
    }()
    lazy var button: UIButton = {
        let button = UIButton()
//        button.layer.borderColor = UIColor.red.cgColor
//        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(buttonTouchBegin(_:_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchEnd), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonTouchEnd), for: .touchCancel)
        button.addTarget(self, action: #selector(buttonTouchEnd), for: .touchUpOutside)
        button.addTarget(self, action: #selector(buttonTouchMove(_:_:)), for: .touchDragInside)
        button.setImage(UIImage(named: "slider_thumb"), for: .normal)
        button.setImage(UIImage(named: "slider_thumb"), for: .highlighted)
        return button
    }()

    
    var offset: CGFloat = 0
    @objc
    func buttonTouchBegin(_ button: UIButton, _ event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        let pointIn = touch.location(in: button)
        print(pointIn.x)
        offset = button.frame.size.width * 0.5 - pointIn.x
    }
    @objc
    func buttonTouchEnd() {
        
    }
    @objc
    func buttonTouchMove(_ button: UIButton, _ event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        let point = touch.location(in: self)
        
        let margin: CGFloat = 9
        
        var center = point.x + offset
        if center <= margin {
            center = margin
        } else if center + margin >= self.frame.size.width {
            center = self.frame.size.width - margin
        }
        print("进度：\( center / (self.frame.size.width-18) )")
        button.center = CGPoint(x: center, y: button.center.y)
        label.center = CGPoint(x: center, y: label.center.y)
        print(center)
        label.text = "\(Int((center-9) / (self.frame.size.width-18) * 100))"
        valueChange?(Int(label.text!) ?? 0)
    }
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 36/255.0, green: 38/255.0, blue: 41/255.0, alpha: 1)
        label.textAlignment = .center
        return label
    }()
}


class WorkBackgrounTemplateView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(collectionView)
        addSubview(emptyLabel)
    }
    var images: Array<String> = []
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emptyLabel.isHidden = !images.isEmpty
        return images.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell_ID", for: indexPath)
        var imageView = cell.contentView.viewWithTag(110) as? UIImageView
        if imageView == nil {
            imageView = UIImageView()
            imageView?.tag = 110
            imageView?.frame = CGRect(x: 0, y: 0, width: collectionView.frame.size.height, height: collectionView.frame.size.height)
            cell.contentView.addSubview(imageView!)
        }
        
        let imageUrl = self.images[indexPath.row]
        imageView?.sd_setImage(with: URL(string: imageUrl), completed: nil)
        
        return cell
    }
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let view = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell_ID")
        view.backgroundColor = .white
        return view
    }()
    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 20, y: (self.frame.size.height-20)*0.5, width: 100, height: 20)
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(red: 47/255.0, green: 47/255.0, blue: 47/255.0, alpha: 1)
        label.text = "背景模板制作中~"
        label.isHidden = true
        return label
    }()
}
