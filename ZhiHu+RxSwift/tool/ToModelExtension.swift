//
//  ToModelExtension.swift
//  ZhiHu+RxSwift
//
//  Created by like on 2017/1/28.
//  Copyright © 2017年 like. All rights reserved.
//

import Foundation
import RxSwift
import Moya

extension Response {
    func mapModel<T: Codable>(_ type: T.Type) throws -> T {
        print(String.init(data: data, encoding: .utf8) ?? "")
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw MoyaError.jsonMapping(self)
        }
    }
}

extension PrimitiveSequence where TraitType == SingleTrait, ElementType == Response {
    func mapModel<T: Codable>(_ type: T.Type) -> Single<T> {
        return flatMap { response -> Single<T> in
            return Single.just(try response.mapModel(T.self))
        }
    }
}
