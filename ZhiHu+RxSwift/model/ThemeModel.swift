//
//  ThemeModel.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/9.
//  Copyright © 2017年 like. All rights reserved.
//

import Foundation
import HandyJSON

struct ThemeResponseModel: HandyJSON {
    var others: [ThemeModel]?
}

struct ThemeModel: HandyJSON {
    var color: String?
    var thumbnail: String?
    var id: Int?
    var description: String?
    var name: String?
}
