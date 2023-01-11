//
//  API.swift
//
//  Created by AppleBetas on 2017-01-15.
//  Copyright © 2017 AppleBetas. All rights reserved.
//

import Foundation

class HttpClient {
    static let shared = HttpClient(baseURL: URL(string: "URL")!)
    var baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    enum HTTPBody {
        case text(String), data(Data), codableObject(CodableProtocol, ParameterEncoding), parameters([String: Any], ParameterEncoding)
        
        var data: Data? {
            switch self {
            case .text(let body):
                return body.data(using: .utf8)
            case .data(let body):
                return body
            case .parameters(let dict, let encoding):
                return encoding.encode(body: dict)
            case .codableObject(let object, let encoding):
                return encoding.encode(body: object)
            }
        }
        
        var contentType: String? {
            switch self {
            case .parameters(_, let encoding):
                return encoding.contentType
            case .text(_):
                return "text/plain; charset=utf-8"
            default:
                return nil
            }
        }
    }
    
    enum HTTPMethod {
        case GET, DELETE, OPTIONS
        case POST(HTTPBody), PUT(HTTPBody), PATCH(HTTPBody)
        
        var description: String {
            switch self {
            case .GET:
                return "GET"
            case .POST(_):
                return "POST"
            case .PUT(_):
                return "PUT"
            case .PATCH(_):
                return "PATCH"
            case .DELETE:
                return "DELETE"
            case .OPTIONS:
                return "OPTIONS"
            }
        }

        var body: Data? {
            switch self {
            case .POST(let body), .PUT(let body), .PATCH(let body):
                return body.data
            default:
                return nil
            }
        }
        
        var contentType: String? {
            switch self {
            case .POST(let body), .PUT(let body), .PATCH(let body):
                return body.contentType
            default:
                return nil
            }
        }
    }
    
    enum ParameterEncoding {
        case json
        
        func encode(body: CodableProtocol) -> Data? {
            return body.encode()
        }
        
        func encode(body: [String: Any]) -> Data? {
            switch self {
            case .json:
                return try? JSONSerialization.data(withJSONObject: body)
            }
        }

        var contentType: String? {
            switch self {
            case .json:
                return "application/json; charset=utf-8"
            }
        }
    }
    
    static func makeRawRequest(to url: URL, method: HTTPMethod = .GET, headers: [String: String] = [:], completionHandler: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
        request.httpMethod = method.description
        request.httpBody = method.body
        for (name, value) in headers {
            request.addValue(value, forHTTPHeaderField: name)
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            completionHandler(data, error)
        })
        task.resume()
        return task
    }
    
}

