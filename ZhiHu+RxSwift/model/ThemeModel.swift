//
//  ThemeModel.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/9.
//  Copyright © 2017年 like. All rights reserved.
//

import Foundation

struct ThemeResponseModel: Codable {
    var others: [ThemeModel]?
}

struct ThemeModel: Codable {
//    var color: String?
    var thumbnail: String?
    var id: Int?
    var description: String?
    var name: String?
}
