//
//  LaunchModel.swift
//  ZhiHu+RxSwift
//
//  Created by  paralworld－02 on 2017/2/17.
//  Copyright © 2017年 like. All rights reserved.
//

import Foundation

struct LaunchModel: Codable {
    var creatives: [LaunchModelImg]?
}

struct LaunchModelImg: Codable {
    var url: String?
    var text: String?
    var start_time : Int?
    var impression_tracks: [String]?
}
