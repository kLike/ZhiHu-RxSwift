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

    let provider = RxMoyaProvider<ApiManager>()
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, storyModel>>()
    let dispose = DisposeBag()
    let dataArr = Variable([SectionModel<String, storyModel>]())
    var newsDate = ""
    var barImg = UIView()
    let titleNum = Variable(0)
    var refreshView: RefreshView?
    let menuView = MenuViewController.shareInstance
//    let loadNewDataEvent = PublishSubject<Void>()
//    let loadMoreDataEvent = PublishSubject<Void>()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bannerView: BannerView!
    @IBOutlet weak var menuBtn: UIBarButtonItem!
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        setBarUI()
        addRefresh()
        
        dataSource.configureCell = { (dataSource, tv, indexPath, model) in
            let cell = tv.dequeueReusableCell(withIdentifier: "ListTableViewCell") as! ListTableViewCell
            cell.title.text = model.title
            cell.img.kf.setImage(with: URL.init(string: (model.images?.first)!))
            cell.morepicImg.isHidden = !model.multipic
            return cell
        }
        
        dataArr
            .asObservable()
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(dispose)
        
        tableView.rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
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
            .addDisposableTo(dispose)
        
        tableView.rx
            .setDelegate(self)
            .addDisposableTo(dispose)
        
        menuBtn.rx
            .tap
            .subscribe(onNext: { self.menuView.showView = !self.menuView.showView })
            .addDisposableTo(dispose)
        
        titleNum
            .asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (num) in
                if num == 0 {
                    self.title = "今日要闻"
                } else {
                    let date = try! DateInRegion.init(string: self.dataSource[num].model, format: DateFormat.custom("yyyyMMdd"))
                    self.title = "\(date.month)月\(date.day)日 \(date.weekday.toWeekday())"
                }
            })
            .addDisposableTo(dispose)
        
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
        
        provider
            .request(.getNewsList)
            .mapModel(listModel.self)
            .subscribe(onNext: { (model) in
                self.dataArr.value = [SectionModel(model: model.date!, items: model.stories!)]
                self.newsDate = model.date!
                var arr = model.top_stories!
                arr.insert(arr.last!, at: 0)
                arr.append(arr[1])
                self.bannerView.imgUrlArr.value = arr
                self.pageControl.numberOfPages = model.top_stories!.count
                self.refreshView?.endRefresh()
            })
            .addDisposableTo(dispose)
    }
    
    func loadMoreData() {
        provider
            .request(.getMoreNews(newsDate))
            .mapModel(listModel.self)
            .subscribe(onNext: { (model) in
                self.dataArr.value.append(SectionModel(model: model.date!, items: model.stories!))
                self.newsDate = model.date!
            })
            .addDisposableTo(dispose)
    }
    
    func setBarUI() {
        barImg = (navigationController?.navigationBar.subviews.first)!
        barImg.alpha = 0
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.barTintColor = UIColor.rgb(63, 141, 208)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
        tableView.frame = CGRect.init(x: 0, y: -64, width: screenW, height: screenH)
        bannerView.bannerDelegate = self
        UIApplication.shared.keyWindow?.addSubview(menuView.view)
        menuView.bindtoNav = navigationController?.tabBarController
        view.addGestureRecognizer(UIPanGestureRecognizer(target:self, action:#selector(panGesture(pan:))))
        menuView.view.addGestureRecognizer(UIPanGestureRecognizer(target:self, action:#selector(panGesture(pan:))))
    }
    
    func panGesture(pan: UIPanGestureRecognizer) {
        menuView.panGesture(pan: pan)
    }
    
    func addRefresh() {
        refreshView = RefreshView.init(frame: CGRect.init(x: 118, y: -42, width: 40, height: 40))
        refreshView?.backgroundColor = UIColor.clear
        view.addSubview(refreshView!)
    }
    
}

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == dataArr.value.count - 1 && indexPath.row == 0 {
            loadMoreData()
        }
        DispatchQueue.global().async {
            self.titleNum.value = (tableView.indexPathsForVisibleRows?.reduce(Int.max) { (result, ind) -> Int in return min(result, ind.section) })!
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section > 0 {
            return UILabel().then {
                $0.frame = CGRect.init(x: 0, y: 0, width: screenW, height: 38)
                $0.backgroundColor = UIColor.rgb(63, 141, 208)
                $0.textColor = UIColor.white
                $0.font = UIFont.systemFont(ofSize: 15)
                $0.textAlignment = .center
                let date = try! DateInRegion.init(string: dataSource[section].model, format: DateFormat.custom("yyyyMMdd"))
                $0.text = "\(date.month)月\(date.day)日 \(date.weekday.toWeekday())"
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
        barImg.alpha = scrollView.contentOffset.y / 200
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








