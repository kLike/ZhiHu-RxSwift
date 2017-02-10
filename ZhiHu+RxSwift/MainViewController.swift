//
//  MainViewController.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/10.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit

class MainViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector:#selector(self.changeVc), name: NSNotification.Name(rawValue: "AuthSuccessNotification"), object: nil)
    }

    func changeVc() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ThemeNavViewController") as! ThemeNavViewController
        self.present(vc, animated: false, completion: nil)
    }

}
