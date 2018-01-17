//
//  SFURLRequest.swift
//  TESTSwift
//
//  Created by DoubleHH on 2018/1/14.
//  Copyright © 2018年 com.baidu.iwaimai. All rights reserved.
//

import Foundation

struct RequestUtils {
    static func addingPercentEscapes(string: String) -> String {
        let dealedString = string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        return (dealedString ?? "")
    }
    
    static func stringWithParameters(params: Dictionary<String, CustomStringConvertible>?) -> String {
        guard let params = params else { return "" }
        var paramsArray = Array<String>()
        params.forEach { (key, value) in
            let kv = addingPercentEscapes(string: key) + "=" + addingPercentEscapes(string: value.description)
            paramsArray.append(kv)
        }
        return paramsArray.joined(separator: "&")
    }
    
    static func urlString(url: String, params: Dictionary<String, CustomStringConvertible>?) -> String {
        if (params?.isEmpty ?? true) {
            return url
        }
        let joinFlag = url.contains("?") ? "&" : "?"
        return (url + joinFlag + stringWithParameters(params: params))
    }
}

struct Checker {
    static func isNilOrEmpty<T>(collection: T?) -> Bool where T: Collection {
        guard let collection = collection else { return true }
        return collection.isEmpty
    }
    
    static func hasValues<T>(collection: T?) -> Bool where T: Collection {
        return !isNilOrEmpty(collection: collection)
    }
}

protocol RequestProtocol {
    func urlRequest() -> URLRequest?;
}

struct Request: RequestProtocol {
    var url: String
    var getParameters: Dictionary<String, CustomStringConvertible>?
    var postParameters: Dictionary<String, CustomStringConvertible>?
    var headers: Dictionary<String, CustomStringConvertible>?
    var httpBody: String?
    var contentType: String?
    var httpMethod: String?
    
    func urlRequest() -> URLRequest? {
        guard let url = wholeURL() else {
            return nil
        }
        var request = URLRequest(url: url)
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 18
        var method = "post"
        if Checker.hasValues(collection: postParameters) ||
           Checker.hasValues(collection: httpBody) {
            method = "post"
        } else {
            method = httpMethod ?? "get"
        }
        request.httpMethod = method
        if Checker.hasValues(collection: postParameters) {
            request.httpBody = RequestUtils.stringWithParameters(params: postParameters).data(using: String.Encoding.utf8)
        } else if Checker.hasValues(collection: httpBody) {
            request.httpBody = httpBody?.data(using: String.Encoding.utf8)
            if Checker.hasValues(collection: contentType) {
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        }
        return request
    }
    
    init(url: String) {
        self.url = url
    }
    
    private func wholeURL() -> URL? {
        return URL(string: RequestUtils.urlString(url: url, params: getParameters))
    }
}

protocol SFRequestSendable {
    func sendRequest(request: RequestProtocol, completionHandler:(Data?, URLResponse?, Error?) -> Swift.Void);
}

struct SFRequest: SFRequestSendable {
    func sendRequest(request: RequestProtocol, completionHandler:(Data?, URLResponse?, Error?) -> Swift.Void) {
        guard let urlRequest: URLRequest = request.urlRequest() else {
            completionHandler(nil, nil, nil)
            return
        }
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        var data: Data? = nil
        var response: URLResponse? = nil
        var error: Error? = nil
        let task: URLSessionTask = URLSession.shared.dataTask(with: urlRequest) { (aData, aResponse, aError) in
            data = aData
            response = aResponse
            error = aError
            semaphore.signal()
        }
        task.resume()
        semaphore.wait(timeout: DispatchTime.distantFuture)
        completionHandler(data, response, error)
    }
}
