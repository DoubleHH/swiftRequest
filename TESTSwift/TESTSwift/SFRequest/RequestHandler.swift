//
//  RequestHandler.swift
//  TESTSwift
//
//  Created by DoubleHH on 2018/2/2.
//  Copyright © 2018年 com.baidu.iwaimai. All rights reserved.
//

import Foundation

protocol Dictionaryable {
    func toDictionary() -> Dictionary<String, CustomStringConvertible>?
}

protocol Requestable: Codable {
    var url: String { get }
}

extension Requestable where Self: Dictionaryable {
    func toDictionary() -> Dictionary<String, CustomStringConvertible>? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        return data.toDictionary()
    }
}

extension Data {
    func toDictionary() -> Dictionary<String, CustomStringConvertible>? {
        guard let json = try? JSONSerialization.jsonObject(with: self, options: .mutableContainers) else { return nil }
        return json as? Dictionary<String, CustomStringConvertible>
    }
}

struct ResponseCode: RawRepresentable {
    typealias RawValue = Int
    var rawValue: Int
    init?(rawValue: Int) {
        self.rawValue = rawValue
    }
    static let netError: ResponseCode = ResponseCode(rawValue: -9993999)!
    static let success: ResponseCode = ResponseCode(rawValue: 0)!
}

class Response {
    var code: ResponseCode!
    var message: String?
    var result: Decodable?
    var params: Requestable!
}

class RequestHandler {
    class func sendRequest<T, R>(params: T, responseType: R.Type?, completion:@escaping (Response) -> Void) where T: Requestable & Dictionaryable, R: Decodable {
        DispatchQueue.global().async {
            var request = Request(url: params.url)
            if let dict = params.toDictionary() {
                request.postParameters = dict
            }
            request.sendSync { (data, response, error) in
                let response = Response()
                let json = data == nil ? nil : data?.toDictionary()
                if error != nil || json == nil {
                    response.code = ResponseCode.netError
                } else {
                    if let errno = json!["errno"] as? Int {
                        response.code = ResponseCode(rawValue: errno)
                    } else {
                        response.code = ResponseCode.netError
                    }
                    response.message = json!["errmsg"] as? String
                    
                    if responseType != nil && response.code == ResponseCode.success && json!["data"] != nil {
                        let responseJson = json!["data"]
                        if let responseData = try? JSONSerialization.data(withJSONObject: responseJson!, options: .prettyPrinted) {
                            let decoder = JSONDecoder()
                            response.result = try? decoder.decode(responseType!, from: responseData)
                        }
                    }
                }
                completion(response)
            }
        }
    }
}
