//
//  HomeViewController.swift
//  ZhiHu+RxSwift
//
//  Created by like on 2017/1/28.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit
import Moya
import RxSwift
import Kingfisher
import RxCocoa
import RxDataSources
import SwiftDate
import Then

class HomeViewController: UIViewController {

    let provider = MoyaProvider<ApiManager>()
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, storyModel>>(configureCell: { (dataSource, tv, indexPath, model) in
        let cell = tv.dequeueReusableCell(withIdentifier: "ListTableViewCell") as! ListTableViewCell
        cell.title.text = model.title
        cell.img.kf.setImage(with: URL.init(string: (model.images?.first)!))
        cell.morepicImg.isHidden = !(model.multipic ?? false)
        return cell
    })
    let dispose = DisposeBag()
    let dataArr = Variable([SectionModel<String, storyModel>]())
    var newsDate = ""
    let titleNum = Variable(0)
    var refreshView: RefreshView?
    let menuView = MenuViewController.shareInstance
//    let loadNewDataEvent = PublishSubject<Void>()
//    let loadMoreDataEvent = PublishSubject<Void>()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bannerView: BannerView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var customNav: UIView!
    @IBOutlet weak var headView: UIView!
    @IBOutlet weak var customNavHeight: NSLayoutConstraint!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var titleLab: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        setBarUI()
        addRefresh()
        
        dataArr
            .asObservable()
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: dispose)
        
        tableView.rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
                self.menuView.showView = false
                self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
                let detailVc = DetailViewController()
                self.dataArr.value.forEach { (sectionModel) in
                    sectionModel.items.forEach({ (storyModel) in
                        detailVc.idArr.append(storyModel.id!)
                    })
                }
                detailVc.id = model.id!
                self.navigationController?.pushViewController(detailVc, animated: true)
            })
            .disposed(by: dispose)
        
        tableView.rx
            .setDelegate(self)
            .disposed(by: dispose)
        
        menuButton.rx
            .tap
            .subscribe(onNext: { self.menuView.showView = !self.menuView.showView })
            .disposed(by: dispose)
        
        titleNum
            .asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (num) in
                if num == 0 {
                    self.titleLab.text = "今日要闻"
                } else {
                    if let date = DateInRegion(string: self.dataSource[num].model, format: DateFormat.custom("yyyyMMdd")) {
                        self.titleLab.text = "\(date.month)月\(date.day)日 \(date.weekday.toWeekday())"
                    }
                }
            })
            .disposed(by: dispose)
        
    }
    
}

extension HomeViewController {
    
    func loadData() {
//        loadNewDataEvent
//            .flatMap {
//                self.provider
//                    .request(.getNewsList)
//                    .mapModel(listModel.self)
//            }
//            .subscribe(onNext: { (model) in
//                self.dataArr.value = [SectionModel(model: model.date!, items: model.stories!)]
//                self.newsDate = model.date!
//                var arr = model.top_stories!
//                arr.insert(arr.last!, at: 0)
//                arr.append(arr[1])
//                self.bannerView.imgUrlArr.value = arr
//                self.pageControl.numberOfPages = model.top_stories!.count
//                self.refreshView?.endRefresh()
//            })
//            .addDisposableTo(dispose)
//        
//        loadNewDataEvent.onNext()
        
        provider.rx
            .request(.getNewsList)
            .mapModel(listModel.self)
            .subscribe(onSuccess: { (model) in
                self.dataArr.value = [SectionModel(model: model.date!, items: model.stories)]
                self.newsDate = model.date!
                var arr = model.top_stories!
                arr.insert(arr.last!, at: 0)
                arr.append(arr[1])
                self.bannerView.imgUrlArr.value = arr
                self.pageControl.numberOfPages = model.top_stories!.count
                self.refreshView?.endRefresh()
            })
            .disposed(by: dispose)
    }
    
    func loadMoreData() {
        provider.rx
            .request(.getMoreNews(newsDate))
            .mapModel(listModel.self)
            .subscribe(onSuccess: { (model) in
                self.dataArr.value.append(SectionModel(model: model.date!, items: model.stories))
                self.newsDate = model.date!
            })
            .disposed(by: dispose)
    }
    
    func setBarUI() {
        customNavHeight.constant = UIApplication.shared.statusBarFrame.size.height + 44
        tableView.frame = CGRect.init(x: 0, y: 0, width: screenW, height: screenH)
//        if kNavigationBarH > 64 {
//            headView.frame = CGRect.init(x: 0, y: 0, width: screenW, height: 200 + kNavigationBarH - 64)
//            tableView.tableHeaderView = headView
//        }
        
        bannerView.bannerDelegate = self
        UIApplication.shared.keyWindow?.addSubview(menuView.view)
        menuView.bindtoNav = navigationController?.tabBarController
        view.addGestureRecognizer(UIPanGestureRecognizer(target:self, action:#selector(panGesture(pan:))))
        menuView.view.addGestureRecognizer(UIPanGestureRecognizer(target:self, action:#selector(panGesture(pan:))))
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    func panGesture(pan: UIPanGestureRecognizer) {
        menuView.panGesture(pan: pan)
    }
    
    func addRefresh() {
        refreshView = RefreshView.init(frame: CGRect.init(x: 118, y: UIApplication.shared.statusBarFrame.size.height + 44 - 50, width: 40, height: 40))
        refreshView?.center.y = UIApplication.shared.statusBarFrame.size.height + 44 - 20.5
        refreshView?.backgroundColor = UIColor.clear
        customNav.addSubview(refreshView!)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == dataArr.value.count - 1 && indexPath.row == 0 {
            loadMoreData()
        }
        self.titleNum.value = (tableView.indexPathsForVisibleRows?.reduce(Int.max) { (result, ind) -> Int in return min(result, ind.section) })!
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section > 0 {
            return UILabel().then {
                $0.frame = CGRect.init(x: 0, y: 0, width: screenW, height: 38)
                $0.backgroundColor = UIColor.rgb(63, 141, 208)
                $0.textColor = UIColor.white
                $0.font = UIFont.systemFont(ofSize: 15)
                $0.textAlignment = .center
                if let date = DateInRegion(string: dataSource[section].model, format: DateFormat.custom("yyyyMMdd")) {
                    $0.text = "\(date.month)月\(date.day)日 \(date.weekday.toWeekday())"
                }
            }
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 38
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
}

extension HomeViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        bannerView.offY.value = Double(scrollView.contentOffset.y)
        customNav.backgroundColor = UIColor.colorFromHex(0x3F8DD0).withAlphaComponent(scrollView.contentOffset.y / 200)
        refreshView?.pullToRefresh(progress: -scrollView.contentOffset.y / 64)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= -64 {
            refreshView?.beginRefresh {
                self.loadData()
//                self.loadNewDataEvent.onNext()
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        refreshView?.resetLayer()
    }
    
}

extension HomeViewController: BannerDelegate {
    
    func selectedItem(model: storyModel) {
        menuView.showView = false
        let detailVc = DetailViewController()
        self.dataArr.value.forEach { (sectionModel) in
            sectionModel.items.forEach({ (storyModel) in
                detailVc.idArr.append(storyModel.id!)
            })
        }
        detailVc.id = model.id!
        self.navigationController?.pushViewController(detailVc, animated: true)
    }
    
    func scrollTo(index: Int) {
        pageControl.currentPage = index
    }
    
}








