//
//  EyuAlterSheetView.swift
//  LKPhotoKit
//
//  Created by duoji on 2020/10/29.
//

import UIKit

class EyuAlterSheetView: UIView {

    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
 
    private func setupView() {
        self.alpha = 0
        self.backgroundColor = UIColor(white: 0, alpha: 0.3)
        self.frame = CGRect(x: 0, y: 0,
                            width: UIScreen.main.bounds.size.width,
                            height: UIScreen.main.bounds.size.height)

        self.isHidden = true
        
        
        self.addSubview(self.contentView)
        contentView.addSubview(actionsView)
        contentView.addSubview(cancelAction)
    }
    @objc private func backgroundTap() {
        self.dismiss()
    }
    
    open func show() {
        if self.superview == nil {
            UIApplication.shared.keyWindow?.addSubview(self)
        }
        self.isHidden = false
        UIView.animate(withDuration: 0.25, animations: {
            self.contentView.transform = CGAffineTransform(translationX: 0, y: -self.contentView.bounds.size.height)
            self.alpha = 1.0
        }, completion: nil)
    }
    
    open func dismiss(remove: Bool = true) {
        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.transform = .identity
            self.alpha = 0.0001
        }) { (finished) in
            self.isHidden = true
            if remove {
                self.removeFromSuperview()
            }
        }
    }
    
    var actions: Array<EyuAlterSheetAction> = []
    open func addAction(_ action: EyuAlterSheetAction) {
        actions.append(action)
        reLayout()
    }
    
    private func reLayout() {
        actionsView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        let actionH: CGFloat = 50
        let actionW: CGFloat = contentView.frame.size.width - 32
        var actionT: CGFloat = 0
        var top = UIScreen.main.bounds.size.height - actionH * CGFloat(actions.count+1) - 16 - 10
        if UIApplication.shared.statusBarFrame.size.height > 20 {
            top = top - 34
        }
        var i = 0
        for action in actions {
            actionsView.addSubview(action)
            action.frame = CGRect(x: 0, y: actionT, width: actionW, height: actionH)
            actionT = actionT + actionH
            i = i + 1
            if i < actions.count {
                let line = UIImageView()
                line.frame = CGRect(x: 0, y: actionT-0.5, width: actionW, height: 0.50)
                line.backgroundColor = UIColor(red: 226/255.0, green: 224/255.0, blue: 224/255.0, alpha: 1)
                actionsView.addSubview(line)
            }
            let backHandle = action.clickHandler
            action.clickHandler = { [weak self] (action1) in
                backHandle?(action1)
                self?.dismiss()
            }
        }
        actionsView.frame = CGRect(x: 16, y: 0, width: actionW, height: actionT)
        
        actionT = actionT + 16
        cancelAction.frame = CGRect(x: 16, y: actionT, width: actionW, height: actionH)
        
        contentView.frame = CGRect(x: 0, y: self.frame.size.height, width: self.frame.size.width, height: self.frame.size.height-top)
    }
    deinit {
        print("退出")
    }
    private lazy var cancelAction: EyuAlterSheetAction = {
        let aciotn = EyuAlterSheetAction(title: "取消") { [weak self] (action) in
            self?.dismiss()
        }
        aciotn.layer.cornerRadius = 10
        aciotn.clipsToBounds = true
        return aciotn
    }()
    private lazy var contentView: UIView = {
        let contentView = UIView()
        let screenH = self.bounds.size.height
        let height: CGFloat = 0
        let width = self.bounds.size.width
        contentView.frame = CGRect(x: 0, y: screenH-height, width: width, height: height)
        contentView.backgroundColor = .clear
        contentView.transform = CGAffineTransform(translationX: 0, y: height)
        return contentView
    }()
    private lazy var actionsView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.backgroundColor = .white
        return view
    }()
}

class EyuAlterSheetAction: UIView {
    var clickHandler: ((EyuAlterSheetAction) -> Void)?
    init(title: String, handler: ((EyuAlterSheetAction) -> Void)?) {
        super.init(frame: .zero)
        backgroundColor = .white
        addSubview(label)
        
        let centerXConstraint = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let centerYConstraint = NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraints([centerXConstraint, centerYConstraint])
        
        label.text = title
        clickHandler = handler
        
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tapGest)
    }
    deinit {
        print("啊啊啊退出")
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    @objc
    private func tapAction() {
        clickHandler?(self)
    }
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1)
        return label
    }()
}
