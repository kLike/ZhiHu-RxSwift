//
//  ToolExtension.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/6.
//  Copyright © 2017年 like. All rights reserved.
//

import UIKit

let screenW: CGFloat = UIScreen.main.bounds.width
let screenH: CGFloat = UIScreen.main.bounds.height

extension UIColor {
    
    class func rgb(_ r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        return UIColor.init(red: r / 255,
                            green: g / 255,
                            blue: b / 255,
                            alpha: 1.0)
    }
    
    class func colorFromHex(_ Hex: UInt32) -> UIColor {
        return UIColor.init(red: CGFloat((Hex & 0xFF0000) >> 16) / 255.0,
                            green: CGFloat((Hex & 0xFF00) >> 8) / 255.0,
                            blue: CGFloat((Hex & 0xFF)) / 255.0,
                            alpha: 1.0)
    }
    
}
