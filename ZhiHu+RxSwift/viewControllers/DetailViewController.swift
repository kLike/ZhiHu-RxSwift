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
    var img = UIImageView().then {
        $0.frame = CGRect.init(x: 0, y: 0, width: screenW, height: 200)
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        let maskImg = UIImageView.init(frame: CGRect.init(x: 0, y: 100, width: screenW, height: 100))
        maskImg.image = UIImage.init(named: "Home_Image_Mask")
        $0.addSubview(maskImg)
    }
    var titleLab = UILabel().then {
        $0.frame = CGRect.init(x: 15, y: 150, width: screenW - 30, height: 26)
        $0.font = UIFont.boldSystemFont(ofSize: 21)
        $0.numberOfLines = 2
        $0.textColor = UIColor.white
    }
    var imgLab = UILabel().then {
        $0.frame = CGRect.init(x: 15, y: 180, width: screenW - 30, height: 16)
        $0.font = UIFont.systemFont(ofSize: 10)
        $0.textAlignment = .right
        $0.textColor = UIColor.white
    }
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
        webview.scrollView.addSubview(img)
        img.addSubview(titleLab)
        img.addSubview(imgLab)
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
                if let image = model.image {
                    self.img.kf.setImage(with: URL.init(string: image))
                    self.titleLab.text = model.title
                } else {
                    self.img.isHidden = true
                }
                if let image_source = model.image_source {
                    self.imgLab.text = "图片: " + image_source
                }
                if (model.title?.characters.count)! > 16 {
                   self.titleLab.frame = CGRect.init(x: 15, y: 120, width: screenW - 30, height: 55)
                }
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
