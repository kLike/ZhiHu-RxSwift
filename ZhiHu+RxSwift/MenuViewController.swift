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

class MenuViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let provider = RxMoyaProvider<ApiManager>()
    let dispose = DisposeBag()
    let themeArr = Variable([ThemeModel]())
    var showView = false
    
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
            .setDelegate(self)
            .addDisposableTo(dispose)
        
        tableView.rx
            .modelSelected(ThemeModel.self)
            .subscribe(onNext: { (model) in
                print(model)
                self.showMenu()
            })
            .addDisposableTo(dispose)
    }

}

extension MenuViewController {
    
    static func createMenuView() -> MenuViewController {
        let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        let menuView = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as? MenuViewController
        menuView?.view.frame = CGRect.init(x: -225, y: 0, width: 225, height: screenH)
        return menuView!
    }
    
    func showMenu() {
        showView = !showView
        let view = UIApplication.shared.keyWindow?.subviews.first
        let menuView = UIApplication.shared.keyWindow?.subviews.last
        UIView.animate(withDuration: 0.5, animations: {
            view?.transform = self.showView ? CGAffineTransform.init(translationX: 225, y: 0) : CGAffineTransform.init(translationX: 0, y: 0)
            menuView?.transform = (view?.transform)!
        })
    }
    
}

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
}
