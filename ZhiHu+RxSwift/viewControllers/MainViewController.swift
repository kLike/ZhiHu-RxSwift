//
//  MainViewController.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/17.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit
import Kingfisher
import Moya
import RxSwift

class MainViewController: UITabBarController {

    let provider = RxMoyaProvider<ApiManager>()
    let launchView = UIImageView()
    let dispose = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLaunchView()
    }

    func setLaunchView() {
        
        launchView.frame = CGRect.init(x: 0, y: 0, width: screenW, height: screenH)
        launchView.alpha = 0.99
        launchView.backgroundColor = UIColor.black
        view.addSubview(launchView)
        
        provider
            .request(.getLaunchImg)
            .mapModel(LaunchModel.self)
            .subscribe(onNext: { (model) in
                if let imgModel = model.creatives?.first {
                    self.launchView.kf.setImage(with: URL.init(string: imgModel.url!), placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (_, _, _, _) in
                        UIView.animate(withDuration: 1.5, animations: {
                            self.launchView.alpha = 1
                        }) { (_) in
                            UIView.animate(withDuration: 0.3, animations: {
                                self.launchView.alpha = 0
                            }, completion: { (_) in
                                self.launchView.removeFromSuperview()
                            })
                        }
                    })
                }
            })
            .addDisposableTo(dispose)
        
    }
    
}
