//
//  DetailViewController.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/13.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit
import Moya
import RxSwift
import Kingfisher
import RxCocoa
import RxDataSources

class DetailViewController: UIViewController {

    @IBOutlet weak var webview: UIWebView!
    var img = UIImageView()
    let provider = RxMoyaProvider<ApiManager>()
    let dispose = DisposeBag()
    var id = Int() {
        didSet {
            loadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: UILabel())
        img.frame = CGRect.init(x: 0, y: 0, width: screenW, height: 200)
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        webview.scrollView.addSubview(img)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }

}

extension DetailViewController {
    
    func loadData() {
        provider
            .request(.getNewsDesc(id))
            .mapModel(NewsDetailModel.self)
            .subscribe(onNext: { (model) in
                self.img.kf.setImage(with: URL.init(string: model.image ?? ""))
                OperationQueue.main.addOperation {
                    self.webview.loadHTMLString(self.concatHTML(css: model.css!, body: model.body!), baseURL: nil)
                }
            })
            .addDisposableTo(dispose)
    }
    
    private func concatHTML(css: [String], body: String) -> String {
        var html = "<html>"
        html += "<head>"
        css.forEach { html += "<link rel=\"stylesheet\" href=\($0)>" }
        html += "<style>img{max-width:320px !important;}</style>"
        html += "</head>"
        html += "<body>"
        html += body
        html += "</body>"
        html += "</html>"
        return html
    }
    
}
