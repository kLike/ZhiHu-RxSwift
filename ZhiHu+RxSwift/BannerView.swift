//
//  BannerView.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/7.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import Kingfisher

class BannerView: UICollectionView {
    
    let imgUrlArr = Variable([storyModel]())
    let dispose = DisposeBag()
    var offY = Variable(0.0)
    var bannerDelegate: BannerDelegate?
    
    override func awakeFromNib() {
        
        contentOffset.x = screenW

        imgUrlArr
            .asObservable()
            .bindTo(rx.items(cellIdentifier: "BannerCell", cellType: BannerCell.self)) {
                row, model, cell in
                cell.img.kf.setImage(with: URL.init(string: model.image!))
                cell.imgTitle.text = model.title!
            }
            .addDisposableTo(dispose)
        
        rx.setDelegate(self).addDisposableTo(dispose)
        
        offY
            .asObservable()
            .subscribe(onNext: { (offy) in
                self.visibleCells.forEach { (cell) in
                    let cell = cell as! BannerCell
                    cell.img.frame.origin.y = CGFloat.init(offy)
                    cell.img.frame.size.height = 200 - CGFloat.init(offy)
                }
            })
            .addDisposableTo(dispose)
        
        rx
            .modelSelected(storyModel.self)
            .subscribe(onNext: { (model) in
                self.bannerDelegate?.selectedItem(model: model)
            })
            .addDisposableTo(dispose)
        
    }

}

extension BannerView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x == CGFloat.init(imgUrlArr.value.count - 1) * screenW {
            scrollView.contentOffset.x = screenW
        }
        else if scrollView.contentOffset.x == 0 {
            scrollView.contentOffset.x = CGFloat.init(imgUrlArr.value.count - 2) * screenW
        }
        bannerDelegate?.scrollTo(index: Int(scrollView.contentOffset.x / screenW) - 1)
    }
}

protocol BannerDelegate {
    func selectedItem(model: storyModel)
    func scrollTo(index: Int)
}


