//
//  ThemeTableViewCell.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/9.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit

class ThemeTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var homeIcon: UIImageView!
    @IBOutlet weak var nameLeft: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            name.font = UIFont.boldSystemFont(ofSize: 15)
            name.textColor = UIColor.white
            contentView.backgroundColor = UIColor.colorFromHex(0x1D2328)
            homeIcon.image = UIImage.init(named: "Menu_Icon_Home_Highlight")
        } else {
            name.font = UIFont.systemFont(ofSize: 15)
            name.textColor = UIColor.colorFromHex(0x95999D)
            contentView.backgroundColor = UIColor.clear
            homeIcon.image = UIImage.init(named: "Menu_Icon_Home")
        }
    }

}
