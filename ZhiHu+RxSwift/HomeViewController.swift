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

    private let provider = RxMoyaProvider<ApiManager>()
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, storyModel>>()
    let dispose = DisposeBag()
    let dataArr = Variable([SectionModel<String, storyModel>]())
    var newsDate = ""
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        dataSource.configureCell = { (dataSource, tv, indexPath, model) in
            let cell = tv.dequeueReusableCell(withIdentifier: "ListTableViewCell") as! ListTableViewCell
            cell.title.text = model.title
            cell.img.kf.setImage(with: URL.init(string: (model.images?.first)!))
            return cell
        }
        
        dataArr
            .asObservable()
            .bindTo(tableView.rx.items(dataSource: dataSource))
            .addDisposableTo(dispose)
        
        tableView.rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
                print(model)
                self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
            })
            .addDisposableTo(dispose)
        
        tableView.rx
            .setDelegate(self)
            .addDisposableTo(dispose)
        
    }
    
    func loadData() {
        provider
            .request(.getNewList)
            .mapModel(listModel.self)
            .subscribe(onNext: { (model) in
                self.dataArr.value = [SectionModel(model: model.date!, items: model.stories!)]
                self.newsDate = model.date!
            })
            .addDisposableTo(dispose)
    }
    
    func loadMoreData() {
        provider
            .request(.getMoreNew(newsDate))
            .mapModel(listModel.self)
            .subscribe(onNext: { (model) in
                self.dataArr.value.append(SectionModel(model: model.date!, items: model.stories!))
                self.newsDate = model.date!
            })
            .addDisposableTo(dispose)
    }
    
}

extension HomeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == dataArr.value.count - 1 && indexPath.row == 0 {
            loadMoreData()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section > 0 {
            return UILabel().then {
                $0.frame = CGRect.init(x: 0, y: 0, width: screenW, height: 38)
                $0.backgroundColor = UIColor.rgb(63, g: 141, b: 208)
                $0.textColor = UIColor.white
                $0.font = UIFont.systemFont(ofSize: 15)
                $0.textAlignment = .center
                let date = try! DateInRegion.init(string: dataSource[section].model, format: DateFormat.custom("yyyyMMdd"))
                $0.text = "\(date.month)月\(date.day)日 \(date.weekdayName)"
            }
        }
        return UILabel()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 200
        }
        return 38
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
}









