//
//  BannerCell.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/7.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit

class BannerCell: UICollectionViewCell {
    
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var imgTitle: UILabel!
    
    override func awakeFromNib() {
//        titlebackView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.05)
        imgTitle.font = UIFont.boldSystemFont(ofSize: 21)
    }
    
}
