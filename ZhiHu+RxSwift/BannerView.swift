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
    
    override func awakeFromNib() {
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
        
        contentOffset.x = screenW
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
    }
}
