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

    var menuBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headImg: UIImageView!
    
    let dispose = DisposeBag()
    let menuView = MenuViewController.shareInstance
    let provider = RxMoyaProvider<ApiManager>()
    let listModelArr = Variable([storyModel]())
    var id = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
        loadData()
        
        menuBtn.rx.tap
            .subscribe(onNext: {
                self.menuView.showView = !self.menuView.showView
            })
            .addDisposableTo(dispose)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.init(rawValue: "setTheme"))
            .subscribe(onNext: { (noti) in
                let model = noti.userInfo?["model"] as! ThemeModel
                self.title = model.name
                self.headImg.kf.setImage(with: URL.init(string: model.thumbnail!))
                self.id = model.id!
                self.loadData()
            })
            .addDisposableTo(dispose)
        
        //设置代理要放在绑定数据之前，否者无效！！！
        tableView.rx
            .setDelegate(self)
            .addDisposableTo(dispose)
        
        listModelArr
            .asObservable()
            .bindTo(tableView.rx.items(cellIdentifier: "ListTableViewCell", cellType: ListTableViewCell.self)) {
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
            .addDisposableTo(dispose)
        
        tableView.rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
                self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
                let detailVc = DetailViewController()
                self.listModelArr.value.forEach({ (model) in
                    detailVc.idArr.append(model.id!)
                })
                detailVc.id = model.id!
                self.navigationController?.pushViewController(detailVc, animated: true)
            })
            .addDisposableTo(dispose)
    }

}

extension ThemeViewController {

    func setUI() {
        title = UserDefaults.standard.object(forKey: "themeName") as! String?
        id = UserDefaults.standard.object(forKey: "themeNameId") as! Int
        headImg.kf.setImage(with: URL.init(string: UserDefaults.standard.object(forKey: "themeImgUrl") as! String))
        menuBtn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 60))
        menuBtn.setImage(UIImage.init(named: "Back_White"), for: .normal)
        menuBtn.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -20, bottom: 0, right: 60)
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: menuBtn)
        navigationController?.navigationBar.subviews.first?.alpha = 0
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
        headImg.frame = CGRect.init(x: 0, y: -64, width: screenW, height: 64)
        tableView.frame = CGRect.init(x: 0, y: 0, width: screenW, height: screenH - 64)
        view.addGestureRecognizer(UIPanGestureRecognizer(target:self, action:#selector(panGesture(pan:))))
    }
    
    func panGesture(pan: UIPanGestureRecognizer) {
        menuView.panGesture(pan: pan)
    }
    
    func loadData() {
        provider
            .request(.getThemeDesc(id))
            .mapModel(listModel.self)
            .subscribe(onNext: { (model) in
                self.listModelArr.value = model.stories!
                self.tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: false)
            })
            .addDisposableTo(dispose)
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
