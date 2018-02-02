//
//  SFURLRequest.swift
//  TESTSwift
//
//  Created by DoubleHH on 2018/1/14.
//  Copyright © 2018年 com.baidu.iwaimai. All rights reserved.
//

import Foundation

struct URLUtils {
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

protocol RequestSendable {
    func sendSync(completionHandler:(Data?, URLResponse?, Error?) -> Swift.Void)
}

struct RequestMutiPart {
    var data: Data
    var name: String
    var fileName: String
    var contentType: String
}

struct Request {
    var url: String
    var getParameters: Dictionary<String, CustomStringConvertible>?
    var postParameters: Dictionary<String, CustomStringConvertible>?
    var headers: Dictionary<String, CustomStringConvertible>?
    var httpBody: String?
    var contentType: String?
    var httpMethod: String?
    var mutiParts: Array<RequestMutiPart>?
    
    init(url: String) {
        self.url = url
    }
    
    private func wholeURL() -> URL? {
        return URL(string: URLUtils.urlString(url: url, params: getParameters))
    }
}

extension Request: RequestProtocol {
    func urlRequest() -> URLRequest? {
        guard let url = wholeURL() else {
            return nil
        }
        var request = URLRequest(url: url)
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 18
        request.allHTTPHeaderFields = self.headers?.mapValues({ $0.description })
        var method = "post"
        if Checker.hasValues(collection: postParameters) ||
            Checker.hasValues(collection: httpBody) {
            method = "post"
        } else {
            method = httpMethod ?? "get"
        }
        request.httpMethod = method
        if Checker.hasValues(collection: postParameters) { // form
            request.httpBody = URLUtils.stringWithParameters(params: postParameters).data(using: String.Encoding.utf8)
        } else if Checker.hasValues(collection: httpBody) { // custom http body
            request.httpBody = httpBody?.data(using: String.Encoding.utf8)
            if Checker.hasValues(collection: contentType) {
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        } else if (Checker.hasValues(collection: mutiParts)) { // mutipart
            let boundary = "D3JKIOU8743NMNFQWERTYUIO12345678BNM"
            let beginBoundary = "--" + boundary
            // set Content-Type: mutipart
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var bodyData: Data = Data()
            
            // content
            if let postParams = postParameters {
                var postString = String()
                for key in postParams.keys {
                    var onePost = "\(beginBoundary)\r\n"
                    onePost += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
                    onePost += "\(postParams[key]?.description ?? "")\r\n"
                    postString += onePost
                }
                if let postData = postString.data(using: String.Encoding.utf8) {
                    bodyData += postData
                }
            }
            
            // file
            if let mutiFiles = mutiParts {
                var count: Int = 0
                for form in mutiFiles {
                    var fileDataString = String()
                    if count > 0 {
                        fileDataString += "\r\n"
                    }
                    fileDataString += beginBoundary + "\r\n"
                    fileDataString += "Content-Disposition: form-data; name=\"\(form.name)\"; filename=\"\(form.fileName)\"\r\n"
                    fileDataString += "Content-Type: \(form.contentType)\r\n\r\n"
                    if let fileData = fileDataString.data(using: String.Encoding.utf8) {
                        bodyData += fileData
                    }
                    bodyData += form.data
                    count += 1
                }
            }
            
            // end
            if let endBoundary = ("\r\n--\(boundary)--").data(using: String.Encoding.utf8) {
                bodyData += endBoundary
            }
            
            // set content length
            request.setValue(String(bodyData.count), forHTTPHeaderField: "Content-Length")
            // set http body
            request.httpBody = bodyData
        }
        return request
    }
}

extension Request: RequestSendable {
    func sendSync(completionHandler:(Data?, URLResponse?, Error?) -> Swift.Void) {
        guard let urlRequest: URLRequest = self.urlRequest() else {
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
