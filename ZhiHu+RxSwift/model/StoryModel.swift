//
//  StoryModel.swift
//  ZhiHu+RxSwift
//
//  Created by like on 2017/1/28.
//  Copyright © 2017年 like. All rights reserved.
//

import Foundation
import HandyJSON

struct listModel: HandyJSON {
    var date: String?
    var stories: [storyModel]?
    var top_stories: [storyModel]?
}

struct storyModel: HandyJSON {
    var ga_prefix: String?
    var id: Int?
    var images: [String]? //list_stories
    var title: String?
    var type: Int?
    var image: String? //top_stories
    var multipic = false
}
