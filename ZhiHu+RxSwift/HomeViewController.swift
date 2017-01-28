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

class HomeViewController: UIViewController {

    private let provider = RxMoyaProvider<ApiManager>()
    let dispose = DisposeBag()
    let dataArr = Variable([storyModel]())
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadData()
        
        dataArr
            .asObservable()
            .bindTo(tableView.rx
                .items(cellIdentifier: "ListTableViewCell", cellType: ListTableViewCell.self)) {
                    row, model, cell in
                    cell.title.text = model.title
                    cell.img.kf.setImage(with: URL.init(string: (model.images?.first)!))
            }
            .addDisposableTo(dispose)
        
        tableView.rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
                print(model)
                self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
            })
            .addDisposableTo(dispose)
        
    }
    
    func loadData() {
        provider
            .request(.getNewList)
            .mapModel(listModel.self)
            .subscribe(onNext: { (model) in
                self.dataArr.value = model.stories!
            })
            .addDisposableTo(dispose)
    }
    
}
