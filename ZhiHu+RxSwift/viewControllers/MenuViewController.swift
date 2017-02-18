//
//  MenuViewController.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/9.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Moya
import SwiftDate

class MenuViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let provider = RxMoyaProvider<ApiManager>()
    let dispose = DisposeBag()
    let themeArr = Variable([ThemeModel]())
    var bindtoNav: UITabBarController?
    var beganDate: Date?
    var endDate: Date?
    var showView = false {
        didSet {
            showView ? showMenu() : dismissMenu()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        provider
            .request(.getThemeList)
            .mapModel(ThemeResponseModel.self)
            .subscribe(onNext: { (model) in
                self.themeArr.value = model.others!
                var model = ThemeModel()
                model.name = "首页"
                self.themeArr.value.insert(model, at: 0)
                self.tableView.selectRow(at: IndexPath.init(row: 0, section: 0), animated: true, scrollPosition: .top)
            })
            .addDisposableTo(dispose)
        
        themeArr
            .asObservable()
            .bindTo(tableView.rx.items(cellIdentifier: "ThemeTableViewCell", cellType: ThemeTableViewCell.self)) {
                row, model, cell in
                cell.name.text = model.name
                cell.homeIcon.isHidden = row == 0 ? false : true
                cell.nameLeft.constant = row == 0 ? 50 : 15
        }
            .addDisposableTo(dispose)
        
        tableView.rx
            .modelSelected(ThemeModel.self)
            .subscribe(onNext: { (model) in
                self.showView = false
                self.showThemeVC(model)
            })
            .addDisposableTo(dispose)
    }

}

extension MenuViewController {
    
    static let shareInstance = createMenuView()
    
    private static func createMenuView() -> MenuViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        let menuView = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as? MenuViewController
        menuView?.view.frame = CGRect.init(x: -225, y: 0, width: 225, height: screenH)
        return menuView!
    }
    
    func showThemeVC(_ model: ThemeModel) {
        if model.id == nil {
            bindtoNav?.selectedIndex = 0
        } else {
            bindtoNav?.selectedIndex = 1
            NotificationCenter.default.post(name: Notification.Name.init(rawValue: "setTheme"), object: nil, userInfo: ["model": model])
            UserDefaults.standard.set(model.name, forKey: "themeName")
            UserDefaults.standard.set(model.thumbnail, forKey: "themeImgUrl")
            UserDefaults.standard.set(model.id!, forKey: "themeNameId")
        }
    }
    
    func swipeGesture(swipe: UISwipeGestureRecognizer) {
        if swipe.state == .ended {
            if swipe.direction == .left && showView {
                showView = false
            }
            if swipe.direction == .right && !showView {
                showView = true
            }
        }
    }
    
    func panGesture(pan: UIPanGestureRecognizer) {
        let xoff = pan.translation(in: view).x
        if pan.state == .began {
            beganDate = Date()
        }
        if pan.state == .ended {
            endDate = Date()
            //区分是轻扫还是滑动
            if endDate! < beganDate! + 150000000.nanoseconds {
                if xoff > 0 {
                    showView = true
                } else {
                    showView = false
                }
                return
            }
        }
        if (0 < xoff && xoff <= 225 && !showView) || (0 > xoff && xoff >= -225 && showView) {
            if pan.translation(in: view).x > 0 {
                moveMenu(pan.translation(in: view).x)
            } else {
                moveMenu(225 + pan.translation(in: view).x)
            }
            if pan.state == .ended {
                if showView {
                    if pan.translation(in: view).x < -175 {
                        showView = false
                    } else {
                        showView = true
                    }
                } else {
                    if pan.translation(in: view).x > 50 {
                        showView = true
                    } else {
                        showView = false
                    }
                }
            }
        }
    }
    
    func moveMenu(_ xoff: CGFloat) {
        let view = UIApplication.shared.keyWindow?.subviews.first
        let menuView = UIApplication.shared.keyWindow?.subviews.last
        UIApplication.shared.keyWindow?.bringSubview(toFront: (UIApplication.shared.keyWindow?.subviews[1])!)
        view?.transform = CGAffineTransform.init(translationX: xoff, y: 0)
        menuView?.transform = (view?.transform)!
    }
    
    func showMenu() {
        let view = UIApplication.shared.keyWindow?.subviews.first
        let menuView = UIApplication.shared.keyWindow?.subviews.last
        UIApplication.shared.keyWindow?.bringSubview(toFront: (UIApplication.shared.keyWindow?.subviews[1])!)
        UIView.animate(withDuration: 0.5, animations: { 
            view?.transform = CGAffineTransform.init(translationX: 225, y: 0)
            menuView?.transform = (view?.transform)!
        })
    }
    
    func dismissMenu() {
        let view = UIApplication.shared.keyWindow?.subviews.first
        let menuView = UIApplication.shared.keyWindow?.subviews.last
        UIApplication.shared.keyWindow?.bringSubview(toFront: (UIApplication.shared.keyWindow?.subviews[1])!)
        UIView.animate(withDuration: 0.5, animations: {
            view?.transform = CGAffineTransform.init(translationX: 0, y: 0)
            menuView?.transform = (view?.transform)!
        })
    }
    
}
