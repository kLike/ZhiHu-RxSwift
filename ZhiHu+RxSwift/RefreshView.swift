//
//  RefreshView.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/9.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit

class RefreshView: UIView {

    let circleLayer = CAShapeLayer()

    let indicatorView = UIActivityIndicatorView().then {
        $0.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
    }
    
    fileprivate var refreshing = false
    fileprivate var endRef = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        creatCircleLayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleLayer.position = CGPoint(x: frame.width/2, y: frame.height/2)
        indicatorView.center = CGPoint(x: frame.width/2, y: frame.height/2)
    }
    
    func creatCircleLayer() {
        circleLayer.path = UIBezierPath(arcCenter: CGPoint(x: 8, y: 8),
                               radius: 8,
                               startAngle: CGFloat(M_PI_2),
                               endAngle: CGFloat(M_PI_2 + 2*M_PI),
                               clockwise: true).cgPath
        circleLayer.strokeColor = UIColor.white.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeStart = 0.0
        circleLayer.strokeEnd = 0.0
        circleLayer.lineWidth = 1.0
        circleLayer.lineCap = kCALineCapRound
        circleLayer.bounds = CGRect(x: 0, y: 0, width: 16, height: 16)
        circleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.addSublayer(circleLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension RefreshView {
    
    func pullToRefresh(progress: CGFloat) {
        circleLayer.strokeEnd = progress
    }
    
    func beginRefresh(begin: @escaping () -> Void) {
        if refreshing {
            return
        }
        refreshing = true
        circleLayer.removeFromSuperlayer()
        addSubview(indicatorView)
        indicatorView.startAnimating()
        begin()
    }
    
    func endRefresh() {
        refreshing = false
        indicatorView.stopAnimating()
        indicatorView.removeFromSuperview()
    }
    
    func resetLayer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.creatCircleLayer()
        }
    }
    
}
