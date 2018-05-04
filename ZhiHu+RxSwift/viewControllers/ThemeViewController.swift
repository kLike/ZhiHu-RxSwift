//
//  ThemeViewController.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/10.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit
import RxSwift
import Kingfisher
import RxCocoa
import RxDataSources
import Moya

class ThemeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headImg: UIImageView!
    @IBOutlet weak var headImgH: NSLayoutConstraint!
    @IBOutlet weak var titleLab: UILabel!
    @IBOutlet weak var menuButton: UIButton!
    
    let dispose = DisposeBag()
    let menuView = MenuViewController.shareInstance
    let provider = MoyaProvider<ApiManager>()
    let listModelArr = Variable([storyModel]())
    var id = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
        loadData()
        
        menuButton.rx.tap
            .subscribe(onNext: {
                self.menuView.showView = !self.menuView.showView
            })
            .disposed(by: dispose)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.init(rawValue: "setTheme"))
            .subscribe(onNext: { (noti) in
                let model = noti.userInfo?["model"] as! ThemeModel
                self.titleLab.text = model.name
                self.headImg.kf.setImage(with: URL.init(string: model.thumbnail!))
                self.id = model.id!
                self.loadData()
            })
            .disposed(by: dispose)
        
        //设置代理要放在绑定数据之前，否者无效！！！
        tableView.rx
            .setDelegate(self)
            .disposed(by: dispose)
        
        listModelArr
            .asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: "ListTableViewCell", cellType: ListTableViewCell.self)) {
                row, model, cell in
                cell.title.text = model.title
                cell.morepicImg.isHidden = !model.multipic
                if model.images != nil {
                    cell.img.isHidden = false
                    cell.titleRight.constant = 105
                    cell.img.kf.setImage(with: URL.init(string: (model.images?.first)!))
                } else {
                    cell.img.isHidden = true
                    cell.titleRight.constant = 15
                }
            }
            .disposed(by: dispose)
        
        tableView.rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
                self.menuView.showView = false
                self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
                let detailVc = DetailViewController()
                self.listModelArr.value.forEach({ (model) in
                    detailVc.idArr.append(model.id!)
                })
                detailVc.id = model.id!
                self.navigationController?.pushViewController(detailVc, animated: true)
            })
            .disposed(by: dispose)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension ThemeViewController {

    func setUI() {
        let imgH = UIApplication.shared.statusBarFrame.height + 44
        titleLab.text = UserDefaults.standard.object(forKey: "themeName") as! String?
        id = UserDefaults.standard.object(forKey: "themeNameId") as! Int
        headImg.kf.setImage(with: URL.init(string: UserDefaults.standard.object(forKey: "themeImgUrl") as! String))
        headImgH.constant = imgH
//        headImg.frame = CGRect.init(x: 0, y: -imgH, width: screenW, height: imgH)
//        tableView.frame = CGRect.init(x: 0, y: 0, width: screenW, height: screenH - imgH)
        view.addGestureRecognizer(UIPanGestureRecognizer(target:self, action:#selector(panGesture(pan:))))
    }
    
    func panGesture(pan: UIPanGestureRecognizer) {
        menuView.panGesture(pan: pan)
    }
    
    func loadData() {
        provider.rx
            .request(.getThemeDesc(id))
            .mapModel(listModel.self)
            .subscribe(onSuccess: { (model) in
                self.listModelArr.value = model.stories!
                self.tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: false)
                self.navigationController?.navigationBar.subviews.first?.alpha = 0
            })
            .disposed(by: dispose)
    }
    
}

extension ThemeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}
