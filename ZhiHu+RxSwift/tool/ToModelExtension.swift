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
import HandyJSON

//extension ObservableType where E == Response {
//    public func mapModel<T: HandyJSON>(_ type: T.Type) -> Observable<T> {
//        return flatMap { response -> Observable<T> in
//            return Observable.just(response.mapModel(T.self))
//        }
//    }
//}

extension Response {
    func mapModel<T: HandyJSON>(_ type: T.Type) throws -> T {
        let jsonString = String.init(data: data, encoding: .utf8)
        guard let object = JSONDeserializer<T>.deserializeFrom(json: jsonString) else {
            throw MoyaError.jsonMapping(self)
        }
        return object
    }
}

extension PrimitiveSequence where TraitType == SingleTrait, ElementType == Response {
    func mapModel<T: HandyJSON>(_ type: T.Type) -> Single<T> {
        return flatMap { response -> Single<T> in
            return Single.just(try response.mapModel(T.self))
        }
    }
}
