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

    var webview: DetailWebView!
    var previousWeb: DetailWebView!
    var idArr = [Int]()
    var previousId = 0
    var nextId = -1
    var statusBackView = UIView().then {
        $0.backgroundColor = UIColor.white
        $0.frame = CGRect.init(x: 0, y: 0, width: screenW, height: 20)
        $0.isHidden = true
    }
    
    let provider = RxMoyaProvider<ApiManager>()
    let dispose = DisposeBag()
    var id = Int() {
        didSet {
            loadData()
            for (index, element) in idArr.enumerated() {
                if id == element {
                    if index == 0 {
                        //最新一条
                        previousId = 0
                        nextId = idArr[index + 1]
                    }
                    else if (index == idArr.count - 1) {
                        //最后一条
                        nextId = -1
                        previousId = idArr[index - 1]
                    }
                    else {
                        previousId = idArr[index - 1]
                        nextId = idArr[index + 1]
                    }
                    break;
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: UILabel())
        webview = DetailWebView.init(frame: view.bounds)
        webview.delegate = self
        webview.scrollView.delegate = self
        view.addSubview(webview)
        previousWeb = DetailWebView.init(frame: CGRect.init(x: 0, y: -screenH, width: screenW, height: screenH))
        view.addSubview(previousWeb)
        view.addSubview(statusBackView)
        setUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scrollViewDidScroll(webview.scrollView)
    }
}

extension DetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        webview.img.frame.origin.y = CGFloat.init(scrollView.contentOffset.y)
        webview.img.frame.size.height = 200 - CGFloat.init(scrollView.contentOffset.y)
        webview.maskImg.frame = CGRect.init(x: 0, y: webview.img.frame.size.height - 100, width: screenW, height: 100)
        if scrollView.contentOffset.y > 180 {
            view.bringSubview(toFront: statusBackView)
            statusBackView.isHidden = false
            UIApplication.shared.statusBarStyle = .default
        } else {
            statusBackView.isHidden = true
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= -60 {
            if previousId > 0 {
                previousWeb.frame = CGRect.init(x: 0, y: -screenH, width: screenW, height: screenH)
                UIView.animate(withDuration: 0.3, animations: {
                    self.webview.transform = CGAffineTransform.init(translationX: 0, y: screenH)
                    self.previousWeb.transform = CGAffineTransform.init(translationX: 0, y: screenH)
                }, completion: { (state) in
                    if state { self.changeWebview(self.previousId) }
                })
            }
        }
        if scrollView.contentOffset.y - 50 + screenH >= scrollView.contentSize.height {
            if nextId > 0 {
                previousWeb.frame = CGRect.init(x: 0, y: screenH, width: screenW, height: screenH)
                UIView.animate(withDuration: 0.3, animations: {
                    self.previousWeb.transform = CGAffineTransform.init(translationX: 0, y: -screenH)
                    self.webview.transform = CGAffineTransform.init(translationX: 0, y: -screenH)
                }, completion: { (state) in
                    if state { self.changeWebview(self.nextId) }
                })
            }
        }
    }
}

extension DetailViewController {
    
    func changeWebview(_ showID: Int) {
        webview.removeFromSuperview()
        previousWeb.scrollView.delegate = self
        previousWeb.delegate = self
        webview = previousWeb
        id = showID
        setUI()
        previousWeb = DetailWebView.init(frame: CGRect.init(x: 0, y: -screenH, width: screenW, height: screenH))
        view.addSubview(previousWeb)
        scrollViewDidScroll(webview.scrollView)
    }
    
    func loadData() {
        provider
            .request(.getNewsDesc(id))
            .mapModel(NewsDetailModel.self)
            .subscribe(onNext: { (model) in
                if let image = model.image {
                    self.webview.img.kf.setImage(with: URL.init(string: image))
                    self.webview.titleLab.text = model.title
                } else {
                    self.webview.img.isHidden = true
                    self.webview.previousLab.textColor = UIColor.colorFromHex(0x777777)
                }
                if let image_source = model.image_source {
                    self.webview.imgLab.text = "图片: " + image_source
                }
                if (model.title?.characters.count)! > 16 {
                   self.webview.titleLab.frame = CGRect.init(x: 15, y: 120, width: screenW - 30, height: 55)
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
    
    func setUI() {
        if previousId == 0 {
            webview.previousLab.text = "已经是第一篇了"
        } else {
            webview.previousLab.text = "载入上一篇"
        }
        if nextId == -1 {
            webview.nextLab.text = "已经是最后一篇了"
        } else {
            webview.nextLab.text = "载入下一篇"
        }
    }
    
}

extension DetailViewController: UIWebViewDelegate {
    func webViewDidStartLoad(_ webView: UIWebView) {
//        waitView.isHidden = false
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webview.waitView.removeFromSuperview()
        webview.nextLab.frame = CGRect.init(x: 15, y: self.webview.scrollView.contentSize.height + 10, width: screenW - 30, height: 20)
    }
}

